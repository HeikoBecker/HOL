(* ========================================================================= *)
(* FILE          : tttLearn.sml                                              *)
(* DESCRIPTION   : Re-addressing tactic ownership of goals during recording  *)
(* AUTHOR        : (c) Thibault Gauthier, University of Innsbruck            *)
(* DATE          : 2017                                                      *)
(* ========================================================================= *)

structure tttLearn :> tttLearn =
struct

open HolKernel Abbrev boolLib aiLib
  smlTimeout smlLexer smlParser smlExecute
  mlFeature mlThmData mlTacticData mlNearestNeighbor mlTreeNeuralNetwork
  psMinimize tttSetup tttToken

val ERR = mk_HOL_ERR "tttLearn"

(* -------------------------------------------------------------------------
   Combining multiple abstractions
   ------------------------------------------------------------------------- *)

fun abstract_stac stac =
  let val a1 = abstract_thml stac in
    if not (!learn_abstract_term) then Option.map fst a1 else
      let
        val a2 = abstract_term (if isSome a1 then fst (valOf a1) else stac)
      in
        if isSome a1 orelse isSome a2
        then Option.map fst a2
        else NONE
      end
  end
  handle Interrupt => raise Interrupt | _ =>
    (debug ("error: abstract_stac: " ^ stac); NONE)

fun concat_absstacl gfea stac stacl =
  let
    fun f x = [abstract_stac x, SOME x]
    val l = List.concat (map f stacl) @ [abstract_stac stac]
  in
    mk_sameorder_set String.compare (List.mapPartial I l)
  end

(* -------------------------------------------------------------------------
   Predictions + re-ordering according to coverage
   ------------------------------------------------------------------------- *)

fun pred_stac (tacsymweight,tacfea) ostac fea =
  let val stacl = tacknn (tacsymweight,tacfea) (!ttt_ortho_radius) fea in
    filter (fn x => not (x = ostac)) stacl
  end

fun pred_thmid thmdata fea =
  thmknn thmdata (!ttt_thmlarg_radius) fea

fun order_stac tacdata ostac stacl =
   let
     fun covscore x = dfind x (#taccov tacdata) handle NotFound => 0
     val oscore  = covscore ostac
     val stacl'  = filter (fn x => covscore x > oscore) stacl
     fun covcmp (x,y) = Int.compare (covscore y, covscore x)
   in
     dict_sort covcmp stacl'
   end

(* -------------------------------------------------------------------------
   Testing if a predicted tactic as a "better effect" than the original
   ------------------------------------------------------------------------- *)

fun op_subset eqf l1 l2 = null (op_set_diff eqf l1 l2)
fun test_stac g gl (stac, istac) =
  let
    val _ = debug "test_stac"
    val glo = app_stac (!learn_tactic_time) istac g
  in
    case glo of NONE => NONE | SOME newgl =>
      (if op_subset goal_eq newgl gl then SOME stac else NONE)
  end

(* -------------------------------------------------------------------------
   Updates the original label if a better tactic is found
   ------------------------------------------------------------------------- *)

val ortho_predstac_time = ref 0.0
val ortho_predthm_time = ref 0.0
val ortho_teststac_time = ref 0.0

fun orthogonalize (thmdata,tacdata,(tacsymweight,tacfea))
  (call as {stac,ortho,time,ig,ogl,loc,fea}) =
  let
    val _ = debug "predict tactics"
    val stacl1 = total_time ortho_predstac_time
      (pred_stac (tacsymweight,tacfea) stac) fea
    val _ = debug "order tactics"
    val stacl2 = order_stac tacdata stac stacl1
    val _ = debug "abstract tactics"
    val stacl3 = concat_absstacl fea stac stacl2
    val _ = debug "predict theorems"
    val thmidl = total_time ortho_predthm_time (pred_thmid thmdata) fea
    val _ = debug "instantiate arguments"
    val stacl4 = map_assoc (inst_thml thmidl) stacl3
    val _ = debug "test tactics"
    val (neworthoo,t) = add_time (findSome (test_stac ig ogl)) stacl4
    val _ = debug ("test time: " ^ rts t)
    val _ = ortho_teststac_time := !ortho_teststac_time + t
  in
    case neworthoo of NONE => call | SOME newortho =>
      {stac = stac, ortho = newortho, time = time,
       ig = ig, ogl = ogl, loc = loc, fea = fea}
  end
  handle Interrupt => raise Interrupt | _ =>
    (debug "error: orthogonalize"; call)

end (* struct *)
