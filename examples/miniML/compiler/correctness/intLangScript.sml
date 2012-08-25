open HolKernel bossLib boolLib boolSimps listTheory pred_setTheory finite_mapTheory SatisfySimps lcsymtacs
open MiniMLTheory compileTerminationTheory
val _ = new_theory "intLang"

(* TODO: move? *)
val lookup_ALOOKUP = store_thm(
"lookup_ALOOKUP",
``lookup = combin$C ALOOKUP``,
fs[FUN_EQ_THM] >> gen_tac >> Induct >- rw[] >> Cases >> rw[])
val _ = export_rewrites["lookup_ALOOKUP"];

val FINITE_free_vars = store_thm(
"FINITE_free_vars",
``(∀c t. FINITE (free_vars c t)) ∧ (∀c b. FINITE (cbod_fvs c b))``,
ho_match_mp_tac free_vars_ind >>
rw[free_vars_def] >>
TRY (Cases_on `FLOOKUP c l` >> rw[] >> NO_TAC) >>
qmatch_rename_tac `FINITE (FOLDL XXX YYY ls)` ["XXX","YYY"] >>
qmatch_abbrev_tac `FINITE (FOLDL ff s0 ls)` >>
qsuff_tac `∀s0. FINITE s0 ⇒ FINITE (FOLDL ff s0 ls)` >- rw[Abbr`s0`] >>
Induct_on `ls` >> rw[Abbr`s0`] >>
first_assum (ho_match_mp_tac o MP_CANON) >>
rw[Abbr`ff`] >>
TRY (Cases_on `h` >> rw[]) >>
metis_tac[])
val _ = export_rewrites["FINITE_free_vars"]

(* nicer induction theorem for evaluate *)
(* TODO: move? *)

val (evaluate_list_with_rules,evaluate_list_with_ind,evaluate_list_with_cases) = Hol_reln [ANTIQUOTE(
evaluate_rules |> SIMP_RULE (srw_ss()) [] |> concl |>
strip_conj |>
Lib.filter (fn tm => tm |> strip_forall |> snd |> strip_imp |> snd |> strip_comb |> fst |> same_const ``evaluate_list``) |>
let val t1 = ``evaluate cenv env``
    val t2 = ``evaluate_list cenv env``
    val tP = type_of t1
    val P = mk_var ("P",tP)
    val ew = mk_comb(mk_var("evaluate_list_with",tP --> type_of t2),P)
in List.map (fn tm => tm |> strip_forall |> snd |>
                   subst [t1|->P, t2|->ew])
end |> list_mk_conj)]

val evaluate_list_with_evaluate = store_thm(
"evaluate_list_with_evaluate",
``∀cenv env. evaluate_list cenv env = evaluate_list_with (evaluate cenv env)``,
ntac 2 gen_tac >>
simp_tac std_ss [Once FUN_EQ_THM] >>
Induct >>
rw[FUN_EQ_THM] >-
  rw[Once evaluate_cases,Once evaluate_list_with_cases] >>
rw[Once evaluate_cases] >>
rw[Once evaluate_list_with_cases,SimpRHS] >>
PROVE_TAC[])

val (evaluate_match_with_rules,evaluate_match_with_ind,evaluate_match_with_cases) = Hol_reln
  (* evaluate_rules |> SIMP_RULE (srw_ss()) [] |> concl |> strip_conj |>
     Lib.filter (fn tm => tm |> strip_forall |> snd |> strip_imp |> snd |>
     strip_comb |> fst |> same_const ``evaluate_match``) *)
   `(evaluate_match_with P cenv env v [] (Rerr (Rraise Bind_error))) ∧
    (ALL_DISTINCT (pat_bindings p []) ∧
     (pmatch cenv p v env = Match env') ∧ P cenv env' e bv ⇒
     evaluate_match_with P cenv env v ((p,e)::pes) bv) ∧
    (ALL_DISTINCT (pat_bindings p []) ∧
     (pmatch cenv p v env = No_match) ∧
     evaluate_match_with P cenv env v pes bv ⇒
     evaluate_match_with P cenv env v ((p,e)::pes) bv) ∧
    ((pmatch cenv p v env = Match_type_error) ⇒
     evaluate_match_with P cenv env v ((p,e)::pes) (Rerr Rtype_error)) ∧
    (¬ALL_DISTINCT (pat_bindings p []) ⇒
     evaluate_match_with P cenv env v ((p,e)::pes) (Rerr Rtype_error))`

val evaluate_match_with_evaluate = store_thm(
"evaluate_match_with_evaluate",
``evaluate_match = evaluate_match_with evaluate``,
simp_tac std_ss [FUN_EQ_THM] >>
ntac 3 gen_tac >>
Induct >-
  rw[Once evaluate_cases,Once evaluate_match_with_cases] >>
rw[Once evaluate_cases] >>
rw[Once evaluate_match_with_cases,SimpRHS] >>
PROVE_TAC[])

val evaluate_nice_ind = save_thm(
"evaluate_nice_ind",
evaluate_ind
|> Q.SPECL [`P`,`λcenv env. evaluate_list_with (P cenv env)`,`evaluate_match_with P`] |> SIMP_RULE (srw_ss()) []
|> UNDISCH_ALL
|> CONJUNCTS
|> List.hd
|> DISCH_ALL
|> Q.GEN `P`
|> SIMP_RULE (srw_ss()) [])

val evaluate_nice_strongind = save_thm(
"evaluate_nice_strongind",
evaluate_strongind
|> Q.SPECL [`P`,`λcenv env. evaluate_list_with (P cenv env)`,`evaluate_match_with P`] |> SIMP_RULE (srw_ss()) []
|> UNDISCH_ALL
|> CONJUNCTS
|> List.hd
|> DISCH_ALL
|> Q.GEN `P`
|> SIMP_RULE (srw_ss()) [evaluate_list_with_evaluate])

val (Cevaluate_list_with_rules,Cevaluate_list_with_ind,Cevaluate_list_with_cases) = Hol_reln [ANTIQUOTE(
Cevaluate_rules |> SIMP_RULE (srw_ss()) [] |> concl |>
strip_conj |>
Lib.filter (fn tm => tm |> strip_forall |> snd |> strip_imp |> snd |> strip_comb |> fst |> same_const ``Cevaluate_list``) |>
let val t1 = ``Cevaluate c env``
    val t2 = ``Cevaluate_list c env``
    val tP = type_of t1
    val P = mk_var ("P",tP)
    val ew = mk_comb(mk_var("Cevaluate_list_with",tP --> type_of t2),P)
in List.map (fn tm => tm |> strip_forall |> snd |>
                   subst [t1|->P, t2|->ew])
end |> list_mk_conj)]

val Cevaluate_list_with_Cevaluate = store_thm(
"Cevaluate_list_with_Cevaluate",
``∀c env. Cevaluate_list c env = Cevaluate_list_with (Cevaluate c env)``,
rpt gen_tac >>
simp_tac std_ss [Once FUN_EQ_THM] >>
Induct >>
rw[FUN_EQ_THM] >-
  rw[Once Cevaluate_cases,Once Cevaluate_list_with_cases] >>
rw[Once Cevaluate_cases] >>
rw[Once Cevaluate_list_with_cases,SimpRHS] >>
PROVE_TAC[])

val Cevaluate_nice_ind = save_thm(
"Cevaluate_nice_ind",
Cevaluate_ind
|> Q.SPECL [`P`,`λc env. Cevaluate_list_with (P c env)`] |> SIMP_RULE (srw_ss()) []
|> UNDISCH_ALL
|> CONJUNCTS
|> List.hd
|> DISCH_ALL
|> Q.GEN `P`
|> SIMP_RULE (srw_ss()) [])

val Cevaluate_nice_strongind = save_thm(
"Cevaluate_nice_strongind",
Cevaluate_strongind
|> Q.SPECL [`P`,`λc env. Cevaluate_list_with (P c env)`] |> SIMP_RULE (srw_ss()) []
|> UNDISCH_ALL
|> CONJUNCTS
|> List.hd
|> DISCH_ALL
|> Q.GEN `P`
|> SIMP_RULE (srw_ss()) [Cevaluate_list_with_Cevaluate])

(* TODO: move? *)

val pat_vars_def = tDefine "pat_vars"`
(pat_vars (Pvar v) = {v}) ∧
(pat_vars (Plit l) = {}) ∧
(pat_vars (Pcon c ps) = BIGUNION (IMAGE pat_vars (set ps)))`(
WF_REL_TAC `measure pat_size` >>
srw_tac[ARITH_ss][MiniMLTerminationTheory.pat1_size_thm] >>
Q.ISPEC_THEN `pat_size` imp_res_tac SUM_MAP_MEM_bound >>
srw_tac[ARITH_ss][])
val _ = export_rewrites["pat_vars_def"]

val FV_def = tDefine "FV"`
(FV (Raise _) = {}) ∧
(FV (Lit _) = {}) ∧
(FV (Con _ ls) = BIGUNION (IMAGE FV (set ls))) ∧
(FV (Var x) = {x}) ∧
(FV (Fun x e) = FV e DIFF {x}) ∧
(FV (App _ e1 e2) = FV e1 ∪ FV e2) ∧
(FV (Log _ e1 e2) = FV e1 ∪ FV e2) ∧
(FV (If e1 e2 e3) = FV e1 ∪ FV e2 ∪ FV e3) ∧
(FV (Mat e pes) = FV e ∪ BIGUNION (IMAGE (λ(p,e). FV e DIFF pat_vars p) (set pes))) ∧
(FV (Let x e b) = FV e ∪ (FV b DIFF {x})) ∧
(FV (Letrec defs b) = BIGUNION (IMAGE (λ(y,x,e). FV e DIFF ({x} ∪ (IMAGE FST (set defs)))) (set defs)) ∪ (FV b DIFF (IMAGE FST (set defs))))`
let open MiniMLTerminationTheory MiniMLTheory in
WF_REL_TAC `measure exp_size` >>
srw_tac[ARITH_ss][exp1_size_thm,exp6_size_thm,exp4_size_thm] >>
map_every (fn q => Q.ISPEC_THEN q imp_res_tac SUM_MAP_MEM_bound)
  [`exp2_size`,`exp5_size`,`exp_size`] >>
fsrw_tac[ARITH_ss][exp_size_def]
end
val _ = export_rewrites["FV_def"]

val FINITE_FV = store_thm(
"FINITE_FV",
``∀exp. FINITE (FV exp)``,
ho_match_mp_tac (theorem"FV_ind") >>
rw[pairTheory.EXISTS_PROD] >>
fsrw_tac[SATISFY_ss][])
val _ = export_rewrites["FINITE_FV"]

(* Cevaluate functional equations *)

val Cevaluate_raise = store_thm(
"Cevaluate_raise",
``∀c env err res. Cevaluate c env (CRaise err) res = (res = Rerr (Rraise err))``,
rw[Once Cevaluate_cases])

val Cevaluate_lit = store_thm(
"Cevaluate_lit",
``∀c env l res. Cevaluate c env (CLit l) res = (res = Rval (CLitv l))``,
rw[Once Cevaluate_cases])

val Cevaluate_var = store_thm(
"Cevaluate_var",
``∀c env vn res. Cevaluate c env (CVar vn) res = (vn ∈ FDOM env ∧ (res = Rval (env ' vn)))``,
rw[Once Cevaluate_cases] >> PROVE_TAC[])

val Cevaluate_let_nil = store_thm(
"Cevaluate_let_nil",
``∀c env exp res. Cevaluate c env (CLet [] [] exp) res = (Cevaluate c env exp res)``,
rw[Once Cevaluate_cases])

val Cevaluate_fun = store_thm(
"Cevaluate_fun",
``∀c env ns b res. Cevaluate c env (CFun ns b) res =
  (∀l. (b = INR l) ⇒ l ∈ FDOM c) ∧
  (res = Rval (CRecClos env [fresh_var (cbod_fvs c b)] [(ns,b)] (fresh_var (cbod_fvs c b))))``,
rw[Once Cevaluate_cases] >> PROVE_TAC[])

val _ = export_rewrites["Cevaluate_raise","Cevaluate_lit","Cevaluate_var","Cevaluate_let_nil","Cevaluate_fun"]

val Cevaluate_con = store_thm(
"Cevaluate_con",
``∀c env cn es res. Cevaluate c env (CCon cn es) res =
(∃vs. Cevaluate_list c env es (Rval vs) ∧ (res = Rval (CConv cn vs))) ∨
(∃err. Cevaluate_list c env es (Rerr err) ∧ (res = Rerr err))``,
rw[Once Cevaluate_cases] >> PROVE_TAC[])

val Cevaluate_tageq = store_thm(
"Cevaluate_tageq",
``∀c env exp n res. Cevaluate c env (CTagEq exp n) res =
  (∃m vs. Cevaluate c env exp (Rval (CConv m vs)) ∧ (res = (Rval (CLitv (Bool (n = m)))))) ∨
  (∃err. Cevaluate c env exp (Rerr err) ∧ (res = Rerr err))``,
rw[Once Cevaluate_cases] >> PROVE_TAC[])

val Cevaluate_let_cons = store_thm(
"Cevaluate_let_cons",
``∀c env n e ns es b res. Cevaluate c env (CLet (n::ns) (e::es) b) res =
(∃v. Cevaluate c env e (Rval v) ∧
     Cevaluate c (env |+ (n,v)) (CLet ns es b) res) ∨
(∃err. Cevaluate c env e (Rerr err) ∧ (res = Rerr err))``,
rw[Once Cevaluate_cases] >> PROVE_TAC[])

val Cevaluate_proj = store_thm(
"Cevaluate_proj",
``∀c env exp n res. Cevaluate c env (CProj exp n) res =
  (∃m vs. Cevaluate c env exp (Rval (CConv m vs)) ∧ (n < LENGTH vs) ∧ (res = (Rval (EL n vs)))) ∨
  (∃err. Cevaluate c env exp (Rerr err) ∧ (res = Rerr err))``,
rw[Once Cevaluate_cases] >> PROVE_TAC[])

val evaluate_list_with_nil = store_thm(
"evaluate_list_with_nil",
``∀f res. evaluate_list_with f [] res = (res = Rval [])``,
rw[Once evaluate_list_with_cases])
val _ = export_rewrites["evaluate_list_with_nil"];

val evaluate_list_with_cons = store_thm(
"evaluate_list_with_cons",
``∀f e es res. evaluate_list_with f (e::es) res =
  (∃v vs. f e (Rval v) ∧ evaluate_list_with f es (Rval vs) ∧ (res = Rval (v::vs))) ∨
  (∃v err. f e (Rval v) ∧ evaluate_list_with f es (Rerr err) ∧ (res = Rerr err)) ∨
  (∃err. f e (Rerr err) ∧ (res = Rerr err))``,
rw[Once evaluate_list_with_cases] >> PROVE_TAC[])

val Cevaluate_list_with_nil = store_thm(
"Cevaluate_list_with_nil",
``∀f res. Cevaluate_list_with f [] res = (res = Rval [])``,
rw[Once Cevaluate_list_with_cases])
val _ = export_rewrites["Cevaluate_list_with_nil"];

val Cevaluate_list_with_cons = store_thm(
"Cevaluate_list_with_cons",
``∀f e es res. Cevaluate_list_with f (e::es) res =
  (∃v vs. f e (Rval v) ∧ Cevaluate_list_with f es (Rval vs) ∧ (res = Rval (v::vs))) ∨
  (∃v err. f e (Rval v) ∧ Cevaluate_list_with f es (Rerr err) ∧ (res = Rerr err)) ∨
  (∃err. f e (Rerr err) ∧ (res = Rerr err))``,
rw[Once Cevaluate_list_with_cases] >> PROVE_TAC[])

val evaluate_list_with_error = store_thm(
"evaluate_list_with_error",
``!P ls err. evaluate_list_with P ls (Rerr err) =
             (∃n. n < LENGTH ls ∧ P (EL n ls) (Rerr err) ∧
               !m. m < n ⇒ ∃v. P (EL m ls) (Rval v))``,
gen_tac >> Induct >- rw[evaluate_list_with_nil] >>
rw[EQ_IMP_THM,evaluate_list_with_cons] >- (
  qexists_tac `SUC n` >>
  rw[] >>
  Cases_on `m` >> rw[] >- (
    qexists_tac `v` >> rw[] ) >>
  fs[] )
>- (
  qexists_tac `0` >>
  rw[] ) >>
Cases_on `n` >> fs[] >>
disj1_tac >>
first_assum (qspec_then `0` mp_tac) >>
simp_tac(srw_ss())[] >>
rw[] >> qexists_tac `v` >> rw[] >>
qmatch_assum_rename_tac `n < LENGTH ls` [] >>
qexists_tac `n` >> rw[] >>
first_x_assum (qspec_then `SUC m` mp_tac) >>
rw[])

val evaluate_list_with_value = store_thm(
"evaluate_list_with_value",
``!P ls vs. evaluate_list_with P ls (Rval vs) = (LENGTH ls = LENGTH vs) ∧ ∀n. n < LENGTH ls ⇒ P (EL n ls) (Rval (EL n vs))``,
gen_tac >> Induct >- rw[evaluate_list_with_nil,LENGTH_NIL_SYM] >>
gen_tac >> Cases >> rw[evaluate_list_with_cons,EQ_IMP_THM] >- (
  Cases_on `n` >> fs[] )
>- (
  first_x_assum (qspec_then `0` mp_tac) >>
  rw[] ) >>
first_x_assum (qspec_then `SUC n` mp_tac) >>
rw[])

val evaluate_list_with_EVERY = store_thm(
"evaluate_list_with_EVERY",
``∀P es vs. evaluate_list_with P es (Rval vs) = (LENGTH es = LENGTH vs) ∧ EVERY (UNCURRY P) (ZIP (es,MAP Rval vs))``,
gen_tac >> Induct >- (
  rw[evaluate_list_with_nil,LENGTH_NIL_SYM,EQ_IMP_THM] ) >>
rw[evaluate_list_with_cons,EQ_IMP_THM] >> rw[] >>
Cases_on `vs` >> fs[])

val Cevaluate_list_with_error = store_thm(
"Cevaluate_list_with_error",
``!P ls err. Cevaluate_list_with P ls (Rerr err) =
             (∃n. n < LENGTH ls ∧ P (EL n ls) (Rerr err) ∧
               !m. m < n ⇒ ∃v. P (EL m ls) (Rval v))``,
gen_tac >> Induct >- rw[Cevaluate_list_with_nil] >>
rw[EQ_IMP_THM,Cevaluate_list_with_cons] >- (
  qexists_tac `SUC n` >>
  rw[] >>
  Cases_on `m` >> rw[] >- (
    qexists_tac `v` >> rw[] ) >>
  fs[] )
>- (
  qexists_tac `0` >>
  rw[] ) >>
Cases_on `n` >> fs[] >>
disj1_tac >>
first_assum (qspec_then `0` mp_tac) >>
simp_tac(srw_ss())[] >>
rw[] >> qexists_tac `v` >> rw[] >>
qmatch_assum_rename_tac `n < LENGTH ls` [] >>
qexists_tac `n` >> rw[] >>
first_x_assum (qspec_then `SUC m` mp_tac) >>
rw[])

val Cevaluate_list_with_value = store_thm(
"Cevaluate_list_with_value",
``!P ls vs. Cevaluate_list_with P ls (Rval vs) = (LENGTH ls = LENGTH vs) ∧ ∀n. n < LENGTH ls ⇒ P (EL n ls) (Rval (EL n vs))``,
gen_tac >> Induct >- rw[Cevaluate_list_with_nil,LENGTH_NIL_SYM] >>
gen_tac >> Cases >> rw[Cevaluate_list_with_cons,EQ_IMP_THM] >- (
  Cases_on `n` >> fs[] )
>- (
  first_x_assum (qspec_then `0` mp_tac) >>
  rw[] ) >>
first_x_assum (qspec_then `SUC n` mp_tac) >>
rw[])

val Cevaluate_list_with_mono = store_thm(
"Cevaluate_list_with_mono",
``∀P Q es res. Cevaluate_list_with P es res ⇒ (∀e r. MEM e es ∧ P e r ⇒ Q e r) ⇒ Cevaluate_list_with Q es res``,
ntac 2 strip_tac >>
ho_match_mp_tac Cevaluate_list_with_ind >>
rw[Cevaluate_list_with_cons] >> PROVE_TAC[])

val Cevaluate_list_with_EVERY = store_thm(
"Cevaluate_list_with_EVERY",
``∀P es vs. Cevaluate_list_with P es (Rval vs) = (LENGTH es = LENGTH vs) ∧ EVERY (UNCURRY P) (ZIP (es,MAP Rval vs))``,
gen_tac >> Induct >- (
  rw[Cevaluate_list_with_nil,LENGTH_NIL_SYM,EQ_IMP_THM] ) >>
rw[Cevaluate_list_with_cons,EQ_IMP_THM] >> rw[] >>
Cases_on `vs` >> fs[])

(* Lemmas *)

val FOLDL2_FUPDATE_LIST = store_thm(
"FOLDL2_FUPDATE_LIST",
``!f1 f2 bs cs a. (LENGTH bs = LENGTH cs) ⇒
  (FOLDL2 (λfm b c. fm |+ (f1 b c, f2 b c)) a bs cs =
   a |++ ZIP (MAP2 f1 bs cs, MAP2 f2 bs cs))``,
SRW_TAC[][FUPDATE_LIST,FOLDL2_FOLDL,MAP2_MAP,ZIP_MAP,MAP_ZIP,
          rich_listTheory.FOLDL_MAP,rich_listTheory.LENGTH_MAP2,
          LENGTH_ZIP,pairTheory.LAMBDA_PROD])

val FOLDL2_FUPDATE_LIST_paired = store_thm(
"FOLDL2_FUPDATE_LIST_paired",
``!f1 f2 bs cs a. (LENGTH bs = LENGTH cs) ⇒
  (FOLDL2 (λfm b (c,d). fm |+ (f1 b c d, f2 b c d)) a bs cs =
   a |++ ZIP (MAP2 (λb. UNCURRY (f1 b)) bs cs, MAP2 (λb. UNCURRY (f2 b)) bs cs))``,
rw[FOLDL2_FOLDL,MAP2_MAP,ZIP_MAP,MAP_ZIP,LENGTH_ZIP,
   pairTheory.UNCURRY,pairTheory.LAMBDA_PROD,FUPDATE_LIST,
   rich_listTheory.FOLDL_MAP])

val FOLDL_FUPDATE_LIST = store_thm(
"FOLDL_FUPDATE_LIST",
``!f1 f2 ls a. FOLDL (\fm k. fm |+ (f1 k, f2 k)) a ls =
  a |++ MAP (\k. (f1 k, f2 k)) ls``,
SRW_TAC[][FUPDATE_LIST,rich_listTheory.FOLDL_MAP])

val SND_FOLDL2_FUPDATE_LIST = store_thm(
"SND_FOLDL2_FUPDATE_LIST",
``!f1 f2 bs cs a n. (LENGTH bs = LENGTH cs) ⇒
  (SND (FOLDL2 (λ(n,fm) b c. (n + 1, fm |+ (f1 n b c, f2 n b c))) (n,a) bs cs) =
   let ns = GENLIST ($+ n) (LENGTH cs) in
   a |++ ZIP (MAP2 (UNCURRY f1) (ZIP (ns,bs)) cs, MAP2 (UNCURRY f2) (ZIP (ns,bs)) cs))``,
ntac 2 gen_tac >>
Induct >- rw[LENGTH_NIL,LENGTH_NIL_SYM,LET_THM,FUPDATE_LIST_THM] >>
gen_tac >> Cases >> rw[LET_THM] >>
fs[FUPDATE_LIST_THM,LET_THM,GENLIST_CONS] >>
`$+ n o SUC = $+ (n + 1)` by (
  srw_tac[ARITH_ss][FUN_EQ_THM] ) >>
rw[])

val UNCURRY_K_I_o_FST = store_thm(
"UNCURRY_K_I_o_FST",
``UNCURRY K = I o FST``,
SRW_TAC[][FUN_EQ_THM,pairTheory.LAMBDA_PROD,pairTheory.FORALL_PROD])

val FUN_FMAP_FAPPLY_FEMPTY_FAPPLY = store_thm(
"FUN_FMAP_FAPPLY_FEMPTY_FAPPLY",
``FINITE s ==> (FUN_FMAP ($FAPPLY FEMPTY) s ' x = FEMPTY ' x)``,
Cases_on `x IN s` >>
rw[FUN_FMAP_DEF,NOT_FDOM_FAPPLY_FEMPTY])
val _ = export_rewrites["FUN_FMAP_FAPPLY_FEMPTY_FAPPLY"]

val FINITE_rw0 = prove(
``FINITE (free_vars c e DIFF x UNION BIGUNION (IMAGE (free_vars c) (set ls)))``,
rw[] >> rw[])
val FINITE_rw1 = prove(
``FINITE (free_vars c e DIFF x UNION (free_vars c e2 UNION BIGUNION (IMAGE (free_vars c) (set ls))))``,
rw[] >> rw[])
val FINITE_rw2 = prove(
``FINITE (free_vars c exp DIFF setns UNION (BIGUNION (IMAGE (λ(vs,e'). free_vars c e' DIFF (sset vs)) (set ls))))``,
rw[] >> rw[pairTheory.UNCURRY])
val FINITE_rw3 = prove(
``FINITE (free_vars c e UNION BIGUNION (IMAGE (free_vars c) (set ls)))``,
rw[] >> rw[])
val _ = augment_srw_ss[rewrites[FINITE_rw0,FINITE_rw1,FINITE_rw2,FINITE_rw3]]

val FUPDATE_LIST_APPLY_NOT_MEM_matchable = store_thm(
"FUPDATE_LIST_APPLY_NOT_MEM_matchable",
``!kvl f k v. ~MEM k (MAP FST kvl) /\ (v = f ' k) ==> ((f |++ kvl) ' k = v)``,
PROVE_TAC[FUPDATE_LIST_APPLY_NOT_MEM])

val MAP_ZIP_unfolded = let
fun f th = let
  val th = SPEC_ALL th
  val tm = rand(lhs(concl th))
  val th = PairRules.PABS tm th
  in CONV_RULE (LAND_CONV PairRules.PETA_CONV) th end
in
MAP_ZIP
|> SIMP_RULE (srw_ss()) [f pairTheory.FST,f pairTheory.SND]
end

val FST_triple = store_thm(
"FST_triple",
``(λ(n,ns,b). n) = FST``,
rw[FUN_EQ_THM,pairTheory.UNCURRY])

val SND_triple = store_thm(
"SND_triple",
``(λ(n,ns,b). f ns b) = UNCURRY f o SND``,
rw[FUN_EQ_THM,pairTheory.UNCURRY])

val FST_pair = store_thm(
"FST_pair",
``(λ(n,v). n) = FST``,
rw[FUN_EQ_THM,pairTheory.UNCURRY])

val SND_pair = store_thm(
"SND_pair",
``(λ(n,v). v) = SND``,
rw[FUN_EQ_THM,pairTheory.UNCURRY])

val SND_FST_pair = store_thm(
"SND_FST_pair",
``(λ((n,m),c).m) = SND o FST``,
rw[FUN_EQ_THM,pairTheory.UNCURRY])

val find_index_ALL_DISTINCT_EL = store_thm(
"find_index_ALL_DISTINCT_EL",
``∀ls n m. ALL_DISTINCT ls ∧ n < LENGTH ls ⇒ (find_index (EL n ls) ls m = SOME (m + n))``,
Induct >- rw[] >>
gen_tac >> Cases >>
srw_tac[ARITH_ss][find_index_def] >>
metis_tac[MEM_EL])
val _ = export_rewrites["find_index_ALL_DISTINCT_EL"]

val find_index_LESS_LENGTH = store_thm(
"find_index_LESS_LENGTH",
``∀ls n m i. (find_index n ls m = SOME i) ⇒ (i < m + LENGTH ls)``,
Induct >> rw[find_index_def] >>
res_tac >>
srw_tac[ARITH_ss][arithmeticTheory.ADD1])

(* TODO: move? *)

(*
val set_MAP_FST_fmap_to_alist = store_thm(
"set_MAP_FST_fmap_to_alist",
``set (MAP FST (fmap_to_alist fm)) = FDOM fm``,
METIS_TAC[fmap_to_alist_to_fmap,FDOM_alist_to_fmap])
val _ = export_rewrites["set_MAP_FST_fmap_to_alist"]
*)

val DIFF_UNION = store_thm(
"DIFF_UNION",
``!x y z. x DIFF (y UNION z) = x DIFF y DIFF z``,
SRW_TAC[][EXTENSION] THEN METIS_TAC[])

val DIFF_COMM = store_thm(
"DIFF_COMM",
``!x y z. x DIFF y DIFF z = x DIFF z DIFF y``,
SRW_TAC[][EXTENSION] THEN METIS_TAC[])

(* TODO: move? *)
val INJ_I = store_thm(
"INJ_I",
``∀s t. INJ I s t = s ⊆ t``,
SRW_TAC[][INJ_DEF,SUBSET_DEF])

val MAP_KEYS_I = store_thm(
"MAP_KEYS_I",
``∀fm. MAP_KEYS I fm = fm``,
rw[GSYM fmap_EQ_THM,MAP_KEYS_def,EXTENSION] >>
metis_tac[MAP_KEYS_def,INJ_I,SUBSET_UNIV,combinTheory.I_THM])
val _ = export_rewrites["MAP_KEYS_I"]

val MAP_EQ_ID = store_thm(
"MAP_EQ_ID",
``!f ls. (MAP f ls = ls) = (!x. MEM x ls ==> (f x = x))``,
PROVE_TAC[MAP_EQ_f,MAP_ID,combinTheory.I_THM])

(* TODO: move *)

val result_rel_def = Define`
(result_rel R (Rval v1) (Rval v2) = R v1 v2) ∧
(result_rel R (Rerr e1) (Rerr e2) = (e1 = e2)) ∧
(result_rel R _ _ = F)`
val _ = export_rewrites["result_rel_def"]

val syneq_refl = store_thm(
"syneq_refl",
``∀c x. syneq c x x``,
gen_tac >> (
(TypeBase.induction_of``:Cv``)
|> Q.SPECL [`W (syneq c)`,`FEVERY ((W (syneq c)) o SND)`,`EVERY (W (syneq c))`]
|> SIMP_RULE(srw_ss())[]
|> UNDISCH_ALL
|> CONJUNCT1
|> DISCH_ALL
|> match_mp_tac) >>
rw[] >> rw[syneq_cases] >>
fsrw_tac[DNF_ss]
[EVERY2_EVERY,MEM_ZIP,MEM_EL,EVERY_MEM,
 pairTheory.FORALL_PROD,pairTheory.UNCURRY] >>
rw[] >>
Cases_on `FLOOKUP env v` >> fs[optionTheory.OPTREL_def] >>
fsrw_tac[DNF_ss][FLOOKUP_DEF,FRANGE_DEF] >>
PROVE_TAC[])
val _ = export_rewrites["syneq_refl"]

val syneq_sym = store_thm(
"syneq_sym",
``∀c x y. syneq c x y ⇒ syneq c y x``,
ho_match_mp_tac syneq_ind >> rw[] >>
rw[syneq_cases] >- (
  fs[EVERY2_EVERY,EVERY_MEM,MEM_ZIP,
     pairTheory.FORALL_PROD] >>
  pop_assum mp_tac >>
  fs[MEM_ZIP] >>
  PROVE_TAC[] )
>- (
  fs[EVERY_MEM,pairTheory.FORALL_PROD,optionTheory.OPTREL_def] >>
  PROVE_TAC[] ))

val syneq_trans = store_thm(
"syneq_trans",
``∀c x y. syneq c x y ⇒ ∀z. syneq c y z ⇒ syneq c x z``,
ho_match_mp_tac syneq_ind >> rw[] >>
pop_assum mp_tac >>
rw[syneq_cases] >- (
  fs[EVERY2_EVERY,EVERY_MEM,MEM_ZIP] >>
  rpt (qpat_assum` LENGTH X = LENGTH Y` mp_tac) >>
  ntac 2 strip_tac >>
  fs[MEM_ZIP,pairTheory.FORALL_PROD] >>
  PROVE_TAC[] )
>- (
  fs[optionTheory.OPTREL_def,EVERY_MEM,
     pairTheory.FORALL_PROD] >>
  metis_tac[optionTheory.option_CASES,
            optionTheory.NOT_SOME_NONE,
            optionTheory.SOME_11] ))

val result_rel_refl = store_thm(
"result_rel_refl",
``(∀x. R x x) ⇒ ∀x. result_rel R x x``,
strip_tac >> Cases >> rw[])
val _ = export_rewrites["result_rel_refl"]

val result_rel_Rval = store_thm(
"result_rel_Rval",
``result_rel R (Rval v) r = ∃v'. (r = Rval v') ∧ R v v'``,
Cases_on `r` >> rw[])
val result_rel_Rerr = store_thm(
"result_rel_Rerr",
``result_rel R (Rerr e) r = (r = Rerr e)``,
Cases_on `r` >> rw[EQ_IMP_THM])
val _ = export_rewrites["result_rel_Rval","result_rel_Rerr"]

(* TODO: move *)
val fmap_rel_def = Define`
  fmap_rel R f1 f2 = (FDOM f2 = FDOM f1) ∧ (∀x. x ∈ FDOM f1 ⇒ R (f1 ' x) (f2 ' x))`

val fmap_rel_FUPDATE_same = store_thm(
"fmap_rel_FUPDATE_same",
``fmap_rel R f1 f2 ∧ R v1 v2 ⇒ fmap_rel R (f1 |+ (k,v1)) (f2 |+ (k,v2))``,
rw[fmap_rel_def,FAPPLY_FUPDATE_THM] >> rw[])

val fmap_rel_FUPDATE_LIST_same = store_thm(
"fmap_rel_FUPDATE_LIST_same",
``∀R ls1 ls2 f1 f2.
  fmap_rel R f1 f2 ∧ (MAP FST ls1 = MAP FST ls2) ∧ (LIST_REL R (MAP SND ls1) (MAP SND ls2))
  ⇒ fmap_rel R (f1 |++ ls1) (f2 |++ ls2)``,
gen_tac >>
Induct >> Cases >> rw[FUPDATE_LIST_THM,LIST_REL_CONS1] >>
Cases_on `ls2` >> fs[FUPDATE_LIST_THM] >>
first_x_assum match_mp_tac >> fs[] >> rw[] >>
qmatch_assum_rename_tac `R a (SND b)`[] >>
Cases_on `b` >> fs[] >>
rw[fmap_rel_FUPDATE_same])

val fmap_rel_FEMPTY = store_thm(
"fmap_rel_FEMPTY",
``fmap_rel R FEMPTY FEMPTY``,
rw[fmap_rel_def])
val _ = export_rewrites["fmap_rel_FEMPTY"]

val fmap_rel_refl = store_thm(
"fmap_rel_refl",
``(∀x. R x x) ⇒ fmap_rel R x x``,
rw[fmap_rel_def])
val _ = export_rewrites["fmap_rel_refl"]

val fmap_rel_extend_rec_env_same = store_thm(
"fmap_rel_extend_rec_env_same",
``fmap_rel R env1 env2 ∧ LIST_REL R vs1 vs2 ∧ (LENGTH ns = LENGTH vs1) ∧
  (∀b. MEM b rs ⇒ R (CRecClos cenv1 rs defs b) (CRecClos cenv2 rs defs b))
  ⇒ fmap_rel R
      (extend_rec_env cenv1 env1 rs defs ns vs1)
      (extend_rec_env cenv2 env2 rs defs ns vs2)``,
rw[extend_rec_env_def,FOLDL_FUPDATE_LIST,FOLDL2_FUPDATE_LIST,LIST_REL_EL_EQN] >>
rw[MAP2_MAP,FST_pair,SND_pair,MAP_ZIP] >>
match_mp_tac fmap_rel_FUPDATE_LIST_same >>
rw[MAP_ZIP,LENGTH_ZIP,LIST_REL_EL_EQN] >>
match_mp_tac fmap_rel_FUPDATE_LIST_same >>
rw[MAP_ZIP,LENGTH_ZIP,LIST_REL_EL_EQN,EL_MAP,MAP_MAP_o,combinTheory.o_DEF] >>
fsrw_tac[DNF_ss][MEM_EL])

val FDOM_extend_rec_env = store_thm(
"FDOM_extend_rec_env",
``(LENGTH ns = LENGTH vs) ⇒ (FDOM (extend_rec_env cenv' env' ns' defs ns vs) = FDOM env' ∪ (set ns') ∪ (set ns))``,
rw[extend_rec_env_def,FOLDL_FUPDATE_LIST,FOLDL2_FUPDATE_LIST,FDOM_FUPDATE_LIST] >>
rw[MAP2_MAP,FST_pair,SND_pair,MAP_ZIP,MAP_MAP_o,combinTheory.o_DEF])
val _ = export_rewrites["FDOM_extend_rec_env"]

(* TODO: move *)
val LIST_REL_EVERY_ZIP = store_thm(
"LIST_REL_EVERY_ZIP",
``!R l1 l2. LIST_REL R l1 l2 = ((LENGTH l1 = LENGTH l2) /\ EVERY (UNCURRY R) (ZIP (l1,l2)))``,
GEN_TAC THEN Induct THEN SRW_TAC[][LENGTH_NIL_SYM] THEN
SRW_TAC[][EQ_IMP_THM,LIST_REL_CONS1] THEN SRW_TAC[][] THEN
Cases_on `l2` THEN FULL_SIMP_TAC(srw_ss())[])

val fmap_rel_FUNION_rels = store_thm(
"fmap_rel_FUNION_rels",
``fmap_rel R f1 f2 ∧ fmap_rel R f3 f4 ⇒ fmap_rel R (f1 ⊌ f3) (f2 ⊌ f4)``,
rw[fmap_rel_def,FUNION_DEF] >> rw[])

val MAP_ZIP_SND_triple = store_thm(
"MAP_ZIP_SND_triple",
``(LENGTH l1 = LENGTH l2) ⇒ (MAP (λ(x,y,z). f y z) (ZIP(l1,l2)) = MAP (UNCURRY f) l2)``,
strip_tac >> (
MAP_ZIP
|> Q.GEN`g`
|> Q.ISPEC `UNCURRY (f:'b->'c->'d)`
|> SIMP_RULE(srw_ss())[combinTheory.o_DEF,pairTheory.LAMBDA_PROD]
|> UNDISCH_ALL
|> CONJUNCTS
|> Lib.el 4
|> MATCH_ACCEPT_TAC))

val (closed_rules,closed_ind,closed_cases) = Hol_reln`
(closed (Litv l)) ∧
(EVERY closed vs ⇒ closed (Conv n vs)) ∧
(EVERY closed (MAP SND env) ∧
 FV b ⊆ set (MAP FST env) ∪ {x}
⇒ closed (Closure env x b)) ∧
(EVERY closed (MAP SND env) ∧
 ALL_DISTINCT (MAP FST defs) ∧
 MEM d (MAP FST defs) ∧
 (∀i d x b. i < LENGTH defs ∧ (EL i defs = (d,x,b)) ⇒
            FV b ⊆ set (MAP FST env) ∪ set (MAP FST defs) ∪ {x})
⇒ closed (Recclosure env defs d))`

val (Cclosed_rules,Cclosed_ind,Cclosed_cases) = Hol_reln`
(Cclosed c (CLitv l)) ∧
(EVERY (Cclosed c) vs ⇒ Cclosed c (CConv cn vs)) ∧
((∀v. v ∈ FRANGE env ⇒ Cclosed c v) ∧
 (LENGTH ns = LENGTH defs) ∧
 ALL_DISTINCT ns ∧
 MEM n ns ∧
 (∀i xs cb. i < LENGTH ns ∧ (EL i defs = (xs,cb)) ⇒
    cbod_fvs c cb ⊆ FDOM env ∪ set ns ∪ set xs ∧
    (∀l. (cb = INR l) ⇒ l ∈ FDOM c))
  ⇒ Cclosed c (CRecClos env ns defs n))`

(* TODO: move *)
val every_result_def = Define`
  (every_result P (Rerr _) = T) ∧
  (every_result P (Rval v) = P v)`
val _ = export_rewrites["every_result_def"]

val FUPDATE_LIST_APPLY_HO_THM = store_thm(
"FUPDATE_LIST_APPLY_HO_THM",
``∀P f kvl k.
(∃n. n < LENGTH kvl ∧ (k = EL n (MAP FST kvl)) ∧ P (EL n (MAP SND kvl)) ∧
     (∀m. n < m ∧ m < LENGTH kvl ⇒ EL m (MAP FST kvl) ≠ k)) ∨
(¬MEM k (MAP FST kvl) ∧ P (f ' k))
⇒ (P ((f |++ kvl) ' k))``,
metis_tac[FUPDATE_LIST_APPLY_MEM,FUPDATE_LIST_APPLY_NOT_MEM])

val doPrim2_closed = store_thm(
"doPrim2_closed",
``∀c b ty op v1 v2. every_result (Cclosed c) (doPrim2 b ty op v1 v2)``,
ntac 4 gen_tac >>
Cases >> TRY (Cases_on `l`) >>
Cases >> TRY (Cases_on `l`) >>
rw[Cclosed_rules])
val _ = export_rewrites["doPrim2_closed"];

val CevalPrim2_closed = store_thm(
"CevalPrim2_closed",
``∀c p2 v1 v2. every_result (Cclosed c) (CevalPrim2 p2 v1 v2)``,
gen_tac >> Cases >> rw[Cclosed_rules])
val _ = export_rewrites["CevalPrim2_closed"];

val LESS_1 = store_thm(
"LESS_1",
``x < 1 = (x = 0:num)``,
DECIDE_TAC)
val _ = export_rewrites["LESS_1"]

val FRANGE_FUPDATE_LIST_SUBSET = store_thm(
"FRANGE_FUPDATE_LIST_SUBSET",
``∀ls fm. FRANGE (fm |++ ls) ⊆ FRANGE fm ∪ (set (MAP SND ls))``,
Induct >- rw[FUPDATE_LIST_THM] >>
qx_gen_tac `p` >> qx_gen_tac `fm` >>
pop_assum (qspec_then `fm |+ p` mp_tac) >>
srw_tac[DNF_ss][SUBSET_DEF] >>
first_x_assum (qspec_then `x` mp_tac) >> fs[FUPDATE_LIST_THM] >>
rw[] >> fs[] >>
PairCases_on `p` >>
fsrw_tac[DNF_ss][FRANGE_FLOOKUP,FLOOKUP_UPDATE] >>
pop_assum mp_tac >> rw[] >>
PROVE_TAC[])

val IN_FRANGE_FUPDATE_LIST_suff = store_thm(
"IN_FRANGE_FUPDATE_LIST_suff",
``(∀v. v ∈ FRANGE fm ⇒ P v) ∧ (∀v. MEM v (MAP SND ls) ⇒ P v) ⇒
    ∀v. v ∈ FRANGE (fm |++ ls) ⇒ P v``,
rw[] >>
imp_res_tac(SIMP_RULE(srw_ss())[SUBSET_DEF]FRANGE_FUPDATE_LIST_SUBSET) >>
PROVE_TAC[])

val free_vars_DOMSUB_SUBSET = store_thm("free_vars_DOMSUB_SUBSET",
  ``(∀c e l. free_vars (c \\ l) e ⊆ free_vars c e) ∧
    (∀c b l. cbod_fvs (c \\ l) b ⊆ cbod_fvs c b)``,
  ho_match_mp_tac free_vars_ind >>
  rw[FOLDL_UNION_BIGUNION,FOLDL_UNION_BIGUNION_paired] >>
  fsrw_tac[DNF_ss][SUBSET_DEF] >>
  fsrw_tac[DNF_ss][pairTheory.FORALL_PROD,pairTheory.EXISTS_PROD] >>
  TRY (PROVE_TAC[]) >>
  fsrw_tac[DNF_ss][FLOOKUP_DEF] >> rw[] >>
  fsrw_tac[][DOMSUB_FAPPLY_THM] >>
  PROVE_TAC[DOMSUB_COMMUTES])

val free_vars_DOMSUB = store_thm("free_vars_DOMSUB",
  ``(∀c e l. (l ∈ FDOM c) ⇒ (free_vars c e ⊆ free_vars (c \\ l) e ∪ free_vars (c \\ l) (c ' l))) ∧
    (∀c b l. (l ∈ FDOM c) ⇒ (cbod_fvs c b ⊆ cbod_fvs (c \\ l) b ∪ cbod_fvs (c \\ l) (INL (c ' l))))``,
  ho_match_mp_tac free_vars_ind >>
  rw[FOLDL_UNION_BIGUNION,FOLDL_UNION_BIGUNION_paired] >>
  fsrw_tac[DNF_ss][SUBSET_DEF] >>
  fsrw_tac[DNF_ss][pairTheory.FORALL_PROD,pairTheory.EXISTS_PROD] >>
  TRY (PROVE_TAC[]) >>
  BasicProvers.EVERY_CASE_TAC >>
  fsrw_tac[DNF_ss][FLOOKUP_DEF] >> rw[] >>
  fsrw_tac[][DOMSUB_FAPPLY_THM] >>
  PROVE_TAC[DOMSUB_COMMUTES,free_vars_DOMSUB_SUBSET,SUBSET_DEF])

val Cevaluate_closed = store_thm("Cevaluate_closed",
  ``∀c env exp res. Cevaluate c env exp res
    ⇒ free_vars c exp ⊆ FDOM env
    ∧ (∀v. v ∈ FRANGE env ⇒ Cclosed c v)
    ⇒ every_result (Cclosed c) res``,
  ho_match_mp_tac Cevaluate_nice_ind >>
  strip_tac >- rw[] >>
  strip_tac >- (
    rw[] >> fsrw_tac[DNF_ss][FRANGE_DEF] ) >>
  strip_tac >- ( rw[] >> rw[Once Cclosed_cases]) >>
  strip_tac >- (
    rw[Cevaluate_list_with_value,FOLDL_UNION_BIGUNION] >>
    rw[Once Cclosed_cases] >>
    fsrw_tac[DNF_ss][EVERY_MEM,MEM_EL] >> rw[] >>
    fsrw_tac[DNF_ss][SUBSET_DEF,MEM_EL] >>
    PROVE_TAC[] ) >>
  strip_tac >- rw[] >>
  strip_tac >- ( rw[] >> rw[Once Cclosed_cases]) >>
  strip_tac >- rw[] >>
  strip_tac >- (
    rw[] >> fs[] >>
    fsrw_tac[DNF_ss][Q.SPECL[`c`,`CConv m vs`] Cclosed_cases,EVERY_MEM,MEM_EL] ) >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- (
    rw[FOLDL_UNION_BIGUNION] >>
    first_x_assum match_mp_tac >>
    fsrw_tac[DNF_ss][SUBSET_DEF,FRANGE_DEF,DOMSUB_FAPPLY_THM] >>
    PROVE_TAC[] ) >>
  strip_tac >- rw[] >>
  strip_tac >- (
    rw[FOLDL_UNION_BIGUNION_paired] >>
    qpat_assum `LENGTH ns = X` assume_tac >>
    fs[FOLDL2_FUPDATE_LIST_paired,FDOM_FUPDATE_LIST,MAP2_MAP,FST_triple,MAP_ZIP] >>
    first_x_assum match_mp_tac >>
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    conj_tac >- PROVE_TAC[] >>
    match_mp_tac IN_FRANGE_FUPDATE_LIST_suff >>
    fs[MAP_ZIP] >>
    fs[MEM_MAP,pairTheory.EXISTS_PROD] >>
    fsrw_tac[DNF_ss][MEM_ZIP,MEM_EL] >>
    rw[Once Cclosed_cases] >>
    TRY (first_x_assum match_mp_tac >> PROVE_TAC[]) >>
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    qx_gen_tac `x` >>
    srw_tac[DNF_ss][] >>
    first_x_assum (qspecl_then [`x`,`n`] mp_tac) >>
    rw[] >> PROVE_TAC[] ) >>
  strip_tac >- (
    rw[FOLDL_FUPDATE_LIST,FOLDL_UNION_BIGUNION_paired] >>
    first_x_assum match_mp_tac >>
    fs[FDOM_FUPDATE_LIST,MAP_MAP_o,combinTheory.o_DEF] >>
    fsrw_tac[DNF_ss][FRANGE_DEF,SUBSET_DEF,FDOM_FUPDATE_LIST,MAP_MAP_o,combinTheory.o_DEF] >>
    conj_tac >- PROVE_TAC[] >>
    qho_match_abbrev_tac `(∀x. P x ⇒ R x) ∧ (∀x. Q x ⇒ R x)` >>
    qsuff_tac `∀x. Q x ∨ (¬Q x ∧ P x) ⇒ R x` >- PROVE_TAC[] >>
    gen_tac >>
    unabbrev_all_tac >> rw[] >>
    ho_match_mp_tac FUPDATE_LIST_APPLY_HO_THM >|[
      disj1_tac >>
      fsrw_tac[DNF_ss][EL_MAP,MAP_ZIP,LENGTH_ZIP,MEM_EL,EL_ZIP] >>
      qpat_assum `LENGTH ns = LENGTH defs` assume_tac >>
      qexists_tac `n` >> fs[LENGTH_ZIP,EL_MAP,EL_ZIP] >>
      fs[EL_ALL_DISTINCT_EL_EQ] >>
      rw[Once Cclosed_cases,MEM_EL] >>
      fsrw_tac[DNF_ss][SUBSET_DEF,FRANGE_DEF,EL_ALL_DISTINCT_EL_EQ]
      >- PROVE_TAC[] >- PROVE_TAC[] >>
      TRY (first_x_assum match_mp_tac >> PROVE_TAC[]) >>
      qmatch_assum_rename_tac `EL i defs = (xs,b)`[] >>
      qx_gen_tac `x` >>
      first_x_assum (qspecl_then [`x`,`i`] mp_tac) >>
      fs[] >> PROVE_TAC[],
     disj2_tac >>
     fs[MAP_ZIP,MEM_MAP,MEM_ZIP,LENGTH_ZIP,pairTheory.EXISTS_PROD,MEM_EL] >>
     PROVE_TAC[]
    ]) >>
  strip_tac >- (
    rw[] >>
    rw[Once Cclosed_cases] >>
    fs[SUBSET_DEF] >> rw[] >> fs[] >>
    PROVE_TAC[] ) >>
  strip_tac >- (
    rw[FOLDL_UNION_BIGUNION] >>
    first_x_assum match_mp_tac >>
    rw[] >- (
      fs[Q.SPECL[`c`,`CRecClos env' ns' defs n`]Cclosed_cases] >>
      first_x_assum (qspec_then `i` mp_tac) >> rw[] >>
      Cases_on `cb` >> fs[] >>
      imp_res_tac find_index_LESS_LENGTH >> pop_assum mp_tac >>
      fs[] >> rw[] >> fs[] >>
      fs[FLOOKUP_DEF] >>
      imp_res_tac free_vars_DOMSUB >>
      fsrw_tac[DNF_ss][SUBSET_DEF] >>
      PROVE_TAC[]) >>
    pop_assum mp_tac >>
    fs[extend_rec_env_def,FOLDL2_FUPDATE_LIST,FOLDL_FUPDATE_LIST] >>
    match_mp_tac IN_FRANGE_FUPDATE_LIST_suff >>
    fs[MAP2_MAP,FST_pair,SND_pair,MAP_ZIP] >>
    conj_tac >- (
      match_mp_tac IN_FRANGE_FUPDATE_LIST_suff >>
      fs[MAP_MAP_o,combinTheory.o_DEF] >>
      conj_tac >- (
        fs[Q.SPECL[`c`,`CRecClos env' ns' defs n`]Cclosed_cases] ) >>
      fsrw_tac[DNF_ss][MEM_MAP] >>
      fs[Q.SPECL[`c`,`CRecClos env' ns' defs n`]Cclosed_cases] >>
      rw[MEM_EL] >> PROVE_TAC[] ) >>
    fs[Cevaluate_list_with_EVERY] >>
    qpat_assum `LENGTH es = X` assume_tac >>
    fs[EVERY_MEM,pairTheory.FORALL_PROD,MEM_ZIP] >>
    fsrw_tac[DNF_ss][EL_MAP] >>
    rw[MEM_EL] >>
    fsrw_tac[DNF_ss][SUBSET_DEF,MEM_EL] >>
    PROVE_TAC[]) >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- (
    rw[Cevaluate_list_with_value] >> fs[] >>
    Cases_on `n` >> fs[] ) >>
  strip_tac >- (
    rw[Cevaluate_list_with_error] >>
    qexists_tac `0` >> rw[] ) >>
  rw[Cevaluate_list_with_error] >>
  qexists_tac `0` >> rw[])

(* TODO: move *)
val IN_FRANGE = store_thm(
"IN_FRANGE",
``!f v. v IN FRANGE f = ?k. k IN FDOM f /\ (f ' k = v)``,
SRW_TAC[][FRANGE_DEF])

val FRANGE_FUNION_SUBSET = store_thm(
"FRANGE_FUNION_SUBSET",
``FRANGE (f1 ⊌ f2) ⊆ FRANGE f1 ∪ FRANGE f2``,
srw_tac[DNF_ss][FRANGE_DEF,SUBSET_DEF,FUNION_DEF] >>
PROVE_TAC[])

val FRANGE_DOMSUB_SUBSET = store_thm(
"FRANGE_DOMSUB_SUBSET",
``FRANGE (fm \\ k) ⊆ FRANGE fm``,
srw_tac[DNF_ss][FRANGE_DEF,SUBSET_DEF,DOMSUB_FAPPLY_THM] >>
PROVE_TAC[])

val FRANGE_DRESTRICT_SUBSET = store_thm(
"FRANGE_DRESTRICT_SUBSET",
``FRANGE (DRESTRICT fm s) ⊆ FRANGE fm``,
srw_tac[DNF_ss][FRANGE_DEF,SUBSET_DEF,DRESTRICT_DEF] >>
PROVE_TAC[])

val IN_FRANGE_FUNION_suff = store_thm(
"IN_FRANGE_FUNION_suff",
``(∀v. v ∈ FRANGE f1 ⇒ P v) ∧ (∀v. v ∈ FRANGE f2 ⇒ P v) ⇒
  (∀v. v ∈ FRANGE (f1 ⊌ f2) ⇒ P v)``,
rw[] >>
imp_res_tac(SIMP_RULE(srw_ss())[SUBSET_DEF]FRANGE_FUNION_SUBSET) >>
PROVE_TAC[])

val IN_FRANGE_DOMSUB_suff = store_thm(
"IN_FRANGE_DOMSUB_suff",
``(∀v. v ∈ FRANGE fm ⇒ P v) ⇒ (∀v. v ∈ FRANGE (fm \\ k) ⇒ P v)``,
rw[] >>
imp_res_tac(SIMP_RULE(srw_ss())[SUBSET_DEF]FRANGE_DOMSUB_SUBSET) >>
PROVE_TAC[])

val IN_FRANGE_DRESTRICT_suff = store_thm(
"IN_FRANGE_DRESTRICT_suff",
``(∀v. v ∈ FRANGE fm ⇒ P v) ⇒ (∀v. v ∈ FRANGE (DRESTRICT fm s) ⇒ P v)``,
rw[] >>
imp_res_tac(SIMP_RULE(srw_ss())[SUBSET_DEF]FRANGE_DRESTRICT_SUBSET) >>
PROVE_TAC[])

val exists_list_GENLIST = store_thm(
"exists_list_GENLIST",
``(∃ls. P ls) = (∃n f. P (GENLIST f n))``,
rw[EQ_IMP_THM] >- (
  map_every qexists_tac [`LENGTH ls`,`combin$C EL ls`] >>
  qmatch_abbrev_tac `P ls2` >>
  qsuff_tac `ls2 = ls` >- rw[] >>
  rw[LIST_EQ_REWRITE,Abbr`ls2`] ) >>
PROVE_TAC[])

val DRESTRICT_SUBMAP_gen = store_thm(
"DRESTRICT_SUBMAP_gen",
``f SUBMAP g ==> DRESTRICT f P SUBMAP g``,
SRW_TAC[][SUBMAP_DEF,DRESTRICT_DEF])

val DRESTRICT_SUBSET_SUBMAP = store_thm(
"DRESTRICT_SUBSET_SUBMAP",
``s1 SUBSET s2 ==> DRESTRICT f s1 SUBMAP DRESTRICT f s2``,
SRW_TAC[][SUBMAP_DEF,SUBSET_DEF,DRESTRICT_DEF])

val FUPDATE_SAME_APPLY = store_thm(
"FUPDATE_SAME_APPLY",
``(x = FST kv) \/ (fm1 ' x = fm2 ' x) ==> ((fm1 |+ kv) ' x = (fm2 |+ kv) ' x)``,
Cases_on `kv` >> rw[FAPPLY_FUPDATE_THM])

val FUPDATE_SAME_LIST_APPLY = store_thm(
"FUPDATE_SAME_LIST_APPLY",
``!kvl fm1 fm2 x. MEM x (MAP FST kvl) ==> ((fm1 |++ kvl) ' x = (fm2 |++ kvl) ' x)``,
ho_match_mp_tac SNOC_INDUCT >>
conj_tac >- rw[] >>
rw[FUPDATE_LIST,FOLDL_SNOC] >>
match_mp_tac FUPDATE_SAME_APPLY >>
qmatch_rename_tac `(y = FST p) \/ Z` ["Z"] >>
Cases_on `y = FST p` >> rw[] >>
first_x_assum match_mp_tac >>
fs[MEM_MAP] >>
PROVE_TAC[])

val extend_rec_env_FUNION = store_thm(
"extend_rec_env_FUNION",
``(LENGTH n = LENGTH v) ⇒
  (extend_rec_env env f ns defs n v = extend_rec_env env FEMPTY ns defs n v ⊌ f)``,
rw[extend_rec_env_def,FOLDL2_FUPDATE_LIST,FOLDL_FUPDATE_LIST] >>
rw[MAP2_MAP,MAP_ZIP,FST_pair,SND_pair] >>
fs[GSYM fmap_EQ_THM] >>
conj_tac >- (
  rw[FDOM_FUPDATE_LIST,MAP_ZIP,MAP2_MAP,FST_pair,SND_pair] >>
  PROVE_TAC[UNION_COMM,UNION_ASSOC] ) >>
qx_gen_tac `x` >>
strip_tac >>
Cases_on `MEM x n` >- (
  Q.PAT_ABBREV_TAC `(f1 : string |-> Cv) = FEMPTY |++ MAP zz ns` >>
  `x ∈ FDOM (f1 |++ ZIP (n,v))` by (
    rw[FDOM_FUPDATE_LIST,MAP_ZIP] ) >>
  rw[Once FUNION_DEF,SimpRHS] >>
  match_mp_tac FUPDATE_SAME_LIST_APPLY >>
  rw[MAP_ZIP] ) >>
ho_match_mp_tac FUPDATE_LIST_APPLY_NOT_MEM_matchable >>
fs[MAP_ZIP] >>
Cases_on `MEM x ns` >- (
  Q.PAT_ABBREV_TAC `(f1 : string |-> Cv) = FEMPTY |++ MAP zz ns` >>
  `x ∈ FDOM (f1 |++ ZIP (n,v))` by (
    rw[FDOM_FUPDATE_LIST,MAP_ZIP,Abbr`f1`,MAP_MAP_o,MEM_MAP] ) >>
  rw[Once FUNION_DEF] >>
  match_mp_tac FUPDATE_LIST_APPLY_NOT_MEM_matchable >>
  rw[MAP_ZIP,Abbr`f1`] >>
  match_mp_tac FUPDATE_SAME_LIST_APPLY >>
  srw_tac[DNF_ss][MEM_MAP,MAP_MAP_o] ) >>
rw[FUNION_DEF,FDOM_FUPDATE_LIST,MAP_ZIP,MAP_MAP_o,MEM_MAP] >>
match_mp_tac EQ_SYM >>
match_mp_tac FUPDATE_LIST_APPLY_NOT_MEM_matchable >>
srw_tac[DNF_ss][MAP_MAP_o,MEM_MAP])

val DRESTRICTED_FUNION = store_thm(
"DRESTRICTED_FUNION",
``∀f1 f2 s. DRESTRICT (f1 ⊌ f2) s = DRESTRICT f1 s ⊌ DRESTRICT f2 (s DIFF FDOM f1)``,
rw[GSYM fmap_EQ_THM,DRESTRICT_DEF,FUNION_DEF] >> rw[] >>
rw[EXTENSION] >> PROVE_TAC[])

val syneq_no_closures = store_thm(
"syneq_no_closures",
``∀c v1 v2. syneq c v1 v2 ⇒ (no_closures v2 = no_closures v1)``,
ho_match_mp_tac syneq_ind >>
rw[EVERY2_EVERY] >>
pop_assum mp_tac >>
srw_tac[DNF_ss][EVERY_MEM,pairTheory.FORALL_PROD,MEM_ZIP] >>
srw_tac[DNF_ss][MEM_EL])

val no_closures_syneq_equal = store_thm(
"no_closures_syneq_equal",
``∀c v1 v2. syneq c v1 v2 ⇒ no_closures v1 ⇒ (v1 = v2)``,
ho_match_mp_tac syneq_ind >>
srw_tac[ETA_ss][EVERY2_EVERY] >>
qpat_assum `LENGTH X = Y` assume_tac >>
fs[EVERY_MEM,pairTheory.FORALL_PROD] >>
rw[LIST_EQ_REWRITE] >>
first_x_assum (match_mp_tac o MP_CANON) >>
fsrw_tac[DNF_ss][MEM_ZIP] >>
fsrw_tac[DNF_ss][MEM_EL] >>
PROVE_TAC[])

val CevalPrim2_syneq = store_thm(
"CevalPrim2_syneq",
``∀c v1 v2. syneq c v1 v2 ⇒
    ∀p v. (CevalPrim2 p v v1 = CevalPrim2 p v v2) ∧
          (CevalPrim2 p v1 v = CevalPrim2 p v2 v)``,
ho_match_mp_tac (CompileTheory.syneq_strongind) >>
strip_tac >- (
  gen_tac >> Cases >> Cases >> rw[] ) >>
strip_tac >- (
  rpt gen_tac >> strip_tac >>
  `EVERY2 (syneq c) vs1 vs2` by (
    fs[EVERY2_EVERY] >>
    pop_assum mp_tac >>
    match_mp_tac EVERY_MONOTONIC >>
    fs[pairTheory.FORALL_PROD] ) >>
  `no_closures (CConv cn vs1) = no_closures (CConv cn vs2)` by (
    match_mp_tac syneq_no_closures >>
    qexists_tac `c` >>
    match_mp_tac syneq_sym >>
    rw[Once syneq_cases] ) >>
  `no_closures (CConv cn vs2) ⇒ (vs1 = vs2)` by (
    strip_tac >>
    qsuff_tac `CConv cn vs1 = CConv cn vs2` >- rw[] >>
    match_mp_tac (MP_CANON no_closures_syneq_equal) >>
    rw[Once syneq_cases] >> PROVE_TAC[] ) >>
  Cases >> Cases >> TRY (Cases_on `l`) >> rw[] ) >>
strip_tac >- (
  rpt gen_tac >> strip_tac >>
  Cases >> Cases >> TRY (Cases_on `l`) >> rw[] ) >>
rpt gen_tac >> strip_tac >>
Cases >> Cases >> TRY (Cases_on `l`) >> rw[] )

val doPrim2_syneq = store_thm(
"doPrim2_syneq",
``∀c v1 v2. syneq c v1 v2 ⇒
    ∀b ty op v. (doPrim2 b ty op v v1 = doPrim2 b ty op v v2) ∧
                (doPrim2 b ty op v1 v = doPrim2 b ty op v2 v)``,
ho_match_mp_tac (CompileTheory.syneq_strongind) >> rw[] >>
Cases_on `v` >> rw[] >>
Cases_on `l` >> rw[])

val final0 =
  qsuff_tac `env0 ⊌ env1 = env1` >- PROVE_TAC[] >>
  rw[GSYM SUBMAP_FUNION_ABSORPTION] >>
  rw[Abbr`env0`,Abbr`env1`,SUBMAP_DEF,DRESTRICT_DEF,FUNION_DEF,FUN_FMAP_DEF,pairTheory.UNCURRY,FAPPLY_FUPDATE_THM] >>
  fsrw_tac[boolSimps.DNF_ss,SATISFY_ss][FUN_FMAP_DEF,pairTheory.UNCURRY,MEM_EL,fmap_rel_def] >>
  metis_tac[]

val final =
  qmatch_assum_abbrev_tac `∀env'. Cevaluate (env0 ⊌ env') ee rr` >>
  qmatch_abbrev_tac `Cevaluate env1 ee rr` >>
  final0

val Cevaluate_any_env = store_thm(
"Cevaluate_any_env",
``∀c env exp res. Cevaluate c env exp res ⇒
  free_vars c exp ⊆ FDOM env ∧ (∀v. v ∈ FRANGE env ⇒ Cclosed c v) ⇒
    ∀env'. fmap_rel (syneq c) env env' ∧ (∀v. v ∈ FRANGE env' ⇒ Cclosed c v) ⇒
      ∀env''. (∀v. v ∈ FRANGE env'' ⇒ Cclosed c v) ⇒
        ∃res'. Cevaluate c ((DRESTRICT env' (free_vars c exp)) ⊌ env'') exp res' ∧
               (result_rel (syneq c)) res res'``,
ho_match_mp_tac Cevaluate_nice_strongind >>
strip_tac >- rw[] >>
strip_tac >- rw[DRESTRICT_DEF,FUNION_DEF,fmap_rel_def] >>
strip_tac >- rw[] >>
strip_tac >- (
  rw[Cevaluate_con,Cevaluate_list_with_Cevaluate,
     Cevaluate_list_with_value,FOLDL_UNION_BIGUNION] >>
  fsrw_tac[DNF_ss,SATISFY_ss][SUBSET_DEF,MEM_EL,result_rel_def] >>
  rw[exists_list_GENLIST] >>
  rw[syneq_cases,EVERY2_EVERY,EVERY_MEM] >>
  rw[pairTheory.FORALL_PROD] >>
  srw_tac[DNF_ss][MEM_ZIP] >>
  rw[GSYM FORALL_AND_THM] >>
  rw[GSYM SKOLEM_THM] >>
  Q.PAT_ABBREV_TAC `env1 = X ⊌ env''` >>
  first_x_assum (qspecl_then [`n`,`env'`,`env1`] mp_tac) >>
  `∀v. v ∈ FRANGE env1 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    fsrw_tac[DNF_ss][FRANGE_DEF,DRESTRICT_DEF,FUNION_DEF] >>
    METIS_TAC[] ) >>
  fs[] >>
  Cases_on `n < LENGTH vs` >> fs[] >>
  disch_then (Q.X_CHOOSE_THEN `v` strip_assume_tac) >>
  qexists_tac `v` >>
  qmatch_assum_abbrev_tac `Cevaluate c (env0 ⊌ env1) ee rr` >>
  final0) >>
strip_tac >- (
  map_every qx_gen_tac [`c`,`env`,`m`] >>
  rw[Cevaluate_con,Cevaluate_list_with_Cevaluate,
     Cevaluate_list_with_error,FOLDL_UNION_BIGUNION] >>
  qmatch_assum_rename_tac `Cevaluate c env (EL z es) (Rerr err)`[] >>
  qpat_assum `z < LENGTH es` mp_tac >>
  qmatch_assum_rename_tac `n < LENGTH es`[] >>
  strip_tac >>
  qpat_assum `n < LENGTH es` assume_tac >>
  fsrw_tac[DNF_ss,SATISFY_ss][SUBSET_DEF,MEM_EL,result_rel_def] >>
  qexists_tac `n` >> fs[] >>
  first_x_assum (qspec_then `env'` mp_tac) >> fs[] >>
  strip_tac >> conj_tac  >- (
    qmatch_abbrev_tac `Cevaluate c env1 ee rr` >>
    `∀v. v ∈ FRANGE env1 ⇒ Cclosed c v` by (
      unabbrev_all_tac >>
      fsrw_tac[DNF_ss][FRANGE_DEF,DRESTRICT_DEF,FUNION_DEF] >>
      metis_tac[] ) >>
    first_x_assum (qspec_then `env1` mp_tac) >> fs[] >>
    qmatch_abbrev_tac `Cevaluate c (env0 ⊌ env1) ee rr ⇒ Cevaluate c env1 ee rr` >>
    strip_tac >>
    final0 ) >>
  qx_gen_tac `m` >> strip_tac >>
  first_x_assum (qspec_then `m` mp_tac) >>
  `m < LENGTH es` by srw_tac[ARITH_ss][] >>
  fsrw_tac[DNF_ss,SATISFY_ss][SUBSET_DEF,MEM_EL] >>
  rw[] >>
  Q.PAT_ABBREV_TAC `env1 = X ⊌ env''` >>
  first_x_assum (qspecl_then [`env'`,`env1`] mp_tac) >>
  rw[] >>
  `∀v. v ∈ FRANGE env1 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    fsrw_tac[DNF_ss][FRANGE_DEF,DRESTRICT_DEF,FUNION_DEF] >>
    metis_tac[] ) >>
  fs[] >>
  qmatch_assum_abbrev_tac `Cevaluate c (env0 ⊌ env1) ee rr` >>
  qmatch_assum_rename_tac `syneq c v v2`[] >>
  qexists_tac `v2` >> final0) >>
strip_tac >- (
  rw[Cevaluate_tageq] >>
  fsrw_tac[DNF_ss][result_rel_def] >>
  qexists_tac `m` >> fs[] >>
  fsrw_tac[DNF_ss][syneq_cases] >>
  PROVE_TAC[]) >>
strip_tac >- rw[Cevaluate_tageq,result_rel_def] >>
strip_tac >- (
  rw[Cevaluate_proj] >>
  fsrw_tac[DNF_ss][result_rel_def] >>
  qmatch_abbrev_tac `X` >>
  qpat_assum `∀env' env''. Y` mp_tac >>
  rw[syneq_cases] >> unabbrev_all_tac >>
  qexists_tac `m` >>
  pop_assum (qspec_then `env'` mp_tac) >> rw[] >>
  fsrw_tac[DNF_ss][EVERY2_EVERY,EVERY_MEM,MEM_EL,SKOLEM_THM] >>
  pop_assum (qspec_then `env''` mp_tac) >> rw[] >>
  pop_assum mp_tac >> fs[LENGTH_ZIP,EL_ZIP] >>
  PROVE_TAC[]) >>
strip_tac >- rw[Cevaluate_proj,result_rel_def] >>
strip_tac >- rw[] >>
strip_tac >- (
  fs[Cevaluate_let_cons,FOLDL_UNION_BIGUNION,
     DRESTRICT_DEF,FUNION_DEF] >>
  rpt gen_tac >>
  strip_tac >> strip_tac >>
  fsrw_tac[DNF_ss,SATISFY_ss][SUBSET_DEF] >>
  qx_gen_tac `env'` >>
  qx_gen_tac `env''` >>
  strip_tac >>
  strip_tac >>
  disj1_tac >>
  Q.PAT_ABBREV_TAC `env1 = X ⊌ env''` >>
  qpat_assum `∀env' env''. P ⇒ Q ⇒ ∃v'. X ∧ syneq c v v'`
    (qspecl_then [`env'`,`env1`] mp_tac) >>
  `∀v. v ∈ FRANGE env1 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    fsrw_tac[DNF_ss][FRANGE_DEF,FUNION_DEF,DRESTRICT_DEF] >>
    metis_tac[]) >>
  rw[] >>
  rw[Once SWAP_EXISTS_THM] >>
  qmatch_assum_abbrev_tac `Cevaluate c (env0 ⊌ env1) ee rr` >>
  qmatch_assum_rename_tac `syneq c v v2`[] >>
  qexists_tac `v2` >>
  simp_tac(srw_ss())[RIGHT_EXISTS_AND_THM,GSYM CONJ_ASSOC] >>
  conj_tac >- final0 >>
  `∀x. x ∈ free_vars c b ∧ ¬MEM x ns ⇒ (x = n) ∨ x ∈ FDOM env` by (
    PROVE_TAC[] ) >> fs[] >>
  `∀x x'. x ∈ free_vars c x' ∧ MEM x' es ⇒ (x = n) ∨ x ∈ FDOM env` by (
    PROVE_TAC[] ) >> fsrw_tac[SATISFY_ss][] >>
  first_x_assum (qspecl_then [`env' |+ (n,v2)`, `env1 |+ (n,v2)`] mp_tac) >>
  asm_simp_tac bool_ss [fmap_rel_FUPDATE_same,syneq_refl] >>
  `every_result (Cclosed c) rr` by (
    match_mp_tac (MP_CANON Cevaluate_closed) >>
    qexists_tac `env0 ⊌ env1` >>
    qexists_tac `ee` >> fs[] >>
    unabbrev_all_tac >>
    fs[DRESTRICT_DEF] >>
    conj_tac >- (
      fsrw_tac[][SUBSET_DEF,fmap_rel_def] ) >>
    fsrw_tac[DNF_ss][FRANGE_DEF,DRESTRICT_DEF,FUNION_DEF] >>
    metis_tac[] ) >>
  `∀v. v ∈ FRANGE (env' |+ (n,v2)) ⇒ Cclosed c v` by (
    fsrw_tac[DNF_ss][FRANGE_DEF,DOMSUB_FAPPLY_THM] >>
    fs[Abbr`rr`] ) >>
  `∀v. v ∈ FRANGE (env1 |+ (n,v2)) ⇒ Cclosed c v` by (
    fsrw_tac[DNF_ss][FRANGE_DEF,DOMSUB_FAPPLY_THM] >>
    fs[Abbr`rr`] ) >>
  `∀v. v ∈ FRANGE (env \\ n) ⇒ Cclosed c v` by (
    match_mp_tac IN_FRANGE_DOMSUB_suff >> fs[] ) >>
  `every_result (Cclosed c) (Rval v)` by (
    match_mp_tac (MP_CANON Cevaluate_closed) >>
    PROVE_TAC[SUBSET_DEF] ) >>
  `Cclosed c v` by fs[] >>
  asm_simp_tac bool_ss [] >>
  strip_tac >>
  qmatch_assum_rename_tac `result_rel (syneq c) res r`[] >>
  qexists_tac `r` >> asm_simp_tac(srw_ss())[] >>
  qunabbrev_tac `env1` >>
  Q.PAT_ABBREV_TAC `env1 = X |+ (n,v2)` >>
  qunabbrev_tac `env0` >>
  qmatch_assum_abbrev_tac `Cevaluate c (env0 ⊌ env1) (CLet ns es b) r` >>
  final0 ) >>
strip_tac >- (
  rw[Cevaluate_let_cons,FOLDL_UNION_BIGUNION] >>
  disj2_tac >> fs[] >>
  first_x_assum (qspec_then `env'` mp_tac) >> rw[] >>
  qmatch_abbrev_tac `Cevaluate c env1 ee rr` >>
  `∀v. v ∈ FRANGE env1 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    fsrw_tac[DNF_ss][FRANGE_DEF,DRESTRICT_DEF,FUNION_DEF] >>
    metis_tac[] ) >>
  first_x_assum (qspec_then `env1` mp_tac) >> rw[] >>
  qmatch_assum_abbrev_tac `Cevaluate c (env0 ⊌ env1) ee rr` >>
  final0) >>
strip_tac >- (
  rw[FOLDL_UNION_BIGUNION_paired] >>
  rw[Once Cevaluate_cases] >>
  qpat_assum `LENGTH ns = LENGTH defs` assume_tac >>
  fs[FOLDL_FUPDATE_LIST,FDOM_FUPDATE_LIST,FOLDL2_FUPDATE_LIST_paired] >>
  fsrw_tac[DNF_ss][MAP2_MAP,MAP_ZIP,FST_triple] >>
  `free_vars c exp ⊆ FDOM env ∪ set ns` by (
    fsrw_tac[DNF_ss][SUBSET_DEF,pairTheory.FORALL_PROD] >>
    PROVE_TAC[] ) >>
  fs[] >> fsrw_tac[SATISFY_ss][] >>
  qho_match_abbrev_tac `∃res'. Cevaluate c (env0 |++ (ls0 env0)) exp res' ∧ result_rel (syneq c) res res'` >>
  `fmap_rel (syneq c) (env |++ (ls0 env)) (env' |++ (ls0 env0))` by (
    unabbrev_all_tac >> fs[] >>
    match_mp_tac fmap_rel_FUPDATE_LIST_same >>
    fs[MAP_ZIP] >>
    fs[LIST_REL_EL_EQN,EL_MAP,EL_ZIP] >>
    qx_gen_tac `n` >> strip_tac >>
    rw[pairTheory.UNCURRY] >>
    rw[syneq_cases,EVERY_MEM,pairTheory.FORALL_PROD] >>
    fs[fmap_rel_def,optionTheory.OPTREL_def,FLOOKUP_DEF] >>
    `v ∈ FDOM env` by (
      fsrw_tac[DNF_ss][SUBSET_DEF,pairTheory.FORALL_PROD,MEM_EL] >>
      fsrw_tac[DNF_ss][pairTheory.UNCURRY,MEM_EL] >>
      metis_tac[pairTheory.FST,pairTheory.SND] ) >> fs[] >>
    qmatch_abbrev_tac `(v ∈ FDOM (DRESTRICT env0 ss) ∨ v ∈ FDOM env2) ∧ syneq c (env ' v) (env1 ' v)` >>
    `v ∈ ss` by (
      srw_tac[DNF_ss][Abbr`ss`,pairTheory.EXISTS_PROD] >>
      fsrw_tac[DNF_ss][SUBSET_DEF,pairTheory.UNCURRY,MEM_EL] >>
      metis_tac[pairTheory.FST,pairTheory.SND]) >>
    fs[DRESTRICT_DEF] >>
    rw[FUNION_DEF,DRESTRICT_DEF] ) >>
  first_x_assum (qspecl_then [`env' |++ (ls0 env0)`,`env0 |++ ls0 env0`] mp_tac) >>
  `∀v. v ∈ FRANGE env0 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    fsrw_tac[DNF_ss][FRANGE_DEF,DRESTRICT_DEF,FUNION_DEF] >>
    PROVE_TAC[] ) >>
  `∀v. MEM v (MAP SND (ls0 env0)) ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    fsrw_tac[DNF_ss][MEM_MAP,pairTheory.FORALL_PROD,MEM_ZIP,EL_MAP] >>
    qx_gen_tac `n` >> strip_tac >> rw[EL_ZIP] >> rw[pairTheory.UNCURRY] >>
    asm_simp_tac(srw_ss())[Once Cclosed_cases] >>
    qabbrev_tac `d = EL n defs` >> PairCases_on`d` >> rw[] >>
    rw[DRESTRICT_DEF] >>
    fsrw_tac[DNF_ss][SUBSET_DEF,MEM_EL,pairTheory.UNCURRY] >>
    metis_tac[pairTheory.FST,pairTheory.SND,fmap_rel_def] ) >>
  `∀v. v ∈ FRANGE (env' |++ ls0 env0) ⇒ Cclosed c v` by (
    match_mp_tac IN_FRANGE_FUPDATE_LIST_suff >> fs[] ) >>
  `∀v. v ∈ FRANGE (env0 |++ ls0 env0) ⇒ Cclosed c v` by (
    match_mp_tac IN_FRANGE_FUPDATE_LIST_suff >> fs[] ) >>
  fs[] >>
  Q.PAT_ABBREV_TAC `P = ∀v. v ∈ FRANGE xxx ⇒ Cclosed c v` >>
  `P` by (
    qunabbrev_tac`P` >>
    ho_match_mp_tac IN_FRANGE_FUPDATE_LIST_suff >>
    srw_tac[][MAP_ZIP,LENGTH_ZIP,MEM_MAP,MEM_ZIP] >>
    rw[EL_MAP,EL_ZIP] >> rw[pairTheory.UNCURRY] >>
    rw[Once Cclosed_cases,SUBSET_DEF] >>
    TRY (first_x_assum match_mp_tac >> fsrw_tac[DNF_ss][MEM_EL] >> PROVE_TAC[]) >>
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    qmatch_assum_rename_tac `EL n defs = (xs,b)`[] >>
    first_x_assum (qspecl_then [`x`,`EL n defs`] mp_tac) >>
    fs[] >> PROVE_TAC[MEM_EL] ) >>
  fs[Abbr`ls0`] >>
  ntac 7 (pop_assum kall_tac) >>
  disch_then (Q.X_CHOOSE_THEN `res'` strip_assume_tac) >>
  qexists_tac `res'` >> fs[] >>
  unabbrev_all_tac >>
  qmatch_abbrev_tac `Cevaluate c env1 ee rr` >>
  qmatch_assum_abbrev_tac `Cevaluate c (env0 ⊌ env1) ee rr` >>
  qsuff_tac `env0 ⊌ env1 = env1` >- PROVE_TAC[] >>
  rw[GSYM SUBMAP_FUNION_ABSORPTION] >>
  unabbrev_all_tac >>
  ntac 2 (pop_assum kall_tac) >>
  fs[SUBMAP_DEF] >>
  qx_gen_tac `x` >> strip_tac >>
  qpat_assum `LENGTH ns = LENGTH defs` assume_tac >>
  conj_tac >- (
    fsrw_tac[DNF_ss][DRESTRICT_DEF,FDOM_FUPDATE_LIST,pairTheory.EXISTS_PROD,MAP_MAP_o,MEM_MAP,MEM_ZIP,LENGTH_ZIP,MEM_EL,EL_ZIP] >>
    PROVE_TAC[EL_ZIP,pairTheory.PAIR_EQ,pairTheory.pair_CASES] ) >>
  Cases_on `MEM x ns` >- (
    fsrw_tac[DNF_ss][DRESTRICT_DEF] >>
    match_mp_tac FUPDATE_LIST_APPLY_MEM >>
    fs[LENGTH_ZIP,MAP_ZIP,MEM_EL,MAP_MAP_o,combinTheory.o_DEF] >>
    qexists_tac `n` >>
    qpat_assum `n < LENGTH ns` mp_tac >>
    fs[] >> strip_tac >>
    reverse conj_tac >- (
      fs[EL_ALL_DISTINCT_EL_EQ] ) >>
    fs[EL_MAP] >>
    match_mp_tac FUPDATE_LIST_APPLY_MEM >>
    fs[MAP_ZIP,LENGTH_ZIP,MAP_MAP_o,combinTheory.o_DEF] >>
    qexists_tac `n` >> fs[] >>
    reverse conj_tac >- (
      fs[EL_ALL_DISTINCT_EL_EQ] ) >>
    fs[EL_MAP] ) >>
  fs[DRESTRICT_DEF,FDOM_FUPDATE_LIST,MAP_ZIP,MAP_MAP_o,combinTheory.o_DEF] >>
  match_mp_tac FUPDATE_LIST_APPLY_NOT_MEM_matchable >>
  fs[MAP_ZIP,MAP_MAP_o,combinTheory.o_DEF] >>
  match_mp_tac FUPDATE_LIST_APPLY_NOT_MEM_matchable >>
  fs[MAP_ZIP,MAP_MAP_o,combinTheory.o_DEF] >>
  fs[DRESTRICT_DEF,FUNION_DEF] ) >>
strip_tac >- (
  rw[FOLDL_UNION_BIGUNION_paired] >>
  rw[Once Cevaluate_cases] >>
  qpat_assum `LENGTH ns = LENGTH defs` assume_tac >>
  fs[FOLDL_FUPDATE_LIST,FDOM_FUPDATE_LIST,FOLDL2_FUPDATE_LIST_paired] >>
  fsrw_tac[DNF_ss][MAP2_MAP,MAP_ZIP,FST_triple,MAP_MAP_o,combinTheory.o_DEF] >>
  `free_vars c exp ⊆ FDOM env ∪ set ns` by (
    fsrw_tac[DNF_ss][SUBSET_DEF,pairTheory.FORALL_PROD] >>
    PROVE_TAC[] ) >>
  fs[] >> fsrw_tac[SATISFY_ss][] >>
  qho_match_abbrev_tac `∃res'. Cevaluate c (env0 |++ (ls0 env0)) exp res' ∧ result_rel (syneq c) res res'` >>
  `fmap_rel (syneq c) (env |++ (ls0 env)) (env' |++ (ls0 env0))` by (
    unabbrev_all_tac >> fs[] >>
    match_mp_tac fmap_rel_FUPDATE_LIST_same >>
    fs[MAP_ZIP,MAP_MAP_o,combinTheory.o_DEF] >>
    fs[LIST_REL_EL_EQN,EL_MAP,EL_ZIP] >>
    qx_gen_tac `n` >> strip_tac >>
    rw[pairTheory.UNCURRY] >>
    rw[syneq_cases,EVERY_MEM,pairTheory.FORALL_PROD] >>
    fs[fmap_rel_def,optionTheory.OPTREL_def,FLOOKUP_DEF] >>
    `v ∈ FDOM env` by (
      fsrw_tac[DNF_ss][SUBSET_DEF,pairTheory.FORALL_PROD,MEM_EL] >>
      fsrw_tac[DNF_ss][pairTheory.UNCURRY,MEM_EL] >>
      metis_tac[pairTheory.FST,pairTheory.SND] ) >> fs[] >>
    qmatch_abbrev_tac `(v ∈ FDOM (DRESTRICT env0 ss) ∨ v ∈ FDOM env2) ∧ syneq c (env ' v) (env1 ' v)` >>
    `v ∈ ss` by (
      srw_tac[DNF_ss][Abbr`ss`,pairTheory.EXISTS_PROD] >>
      fsrw_tac[DNF_ss][SUBSET_DEF,pairTheory.UNCURRY,MEM_EL] >>
      metis_tac[pairTheory.FST,pairTheory.SND]) >>
    fs[DRESTRICT_DEF] >>
    rw[FUNION_DEF,DRESTRICT_DEF] ) >>
  first_x_assum (qspecl_then [`env' |++ (ls0 env0)`,`env0 |++ ls0 env0`] mp_tac) >>
  `∀v. v ∈ FRANGE env0 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    fsrw_tac[DNF_ss][FRANGE_DEF,DRESTRICT_DEF,FUNION_DEF] >>
    PROVE_TAC[] ) >>
  `∀v. MEM v (MAP SND (ls0 env0)) ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    fsrw_tac[DNF_ss][MEM_MAP,pairTheory.FORALL_PROD,MEM_ZIP,EL_MAP] >>
    qx_gen_tac `n` >> strip_tac >> rw[EL_ZIP] >> rw[pairTheory.UNCURRY] >>
    asm_simp_tac(srw_ss())[Once Cclosed_cases] >>
    rw[DRESTRICT_DEF] >>
    fsrw_tac[DNF_ss][SUBSET_DEF,MEM_EL,pairTheory.UNCURRY] >>
    metis_tac[pairTheory.FST,pairTheory.SND,fmap_rel_def] ) >>
  `∀v. v ∈ FRANGE (env' |++ ls0 env0) ⇒ Cclosed c v` by (
    match_mp_tac IN_FRANGE_FUPDATE_LIST_suff >> fs[] ) >>
  `∀v. v ∈ FRANGE (env0 |++ ls0 env0) ⇒ Cclosed c v` by (
    match_mp_tac IN_FRANGE_FUPDATE_LIST_suff >> fs[] ) >>
  fs[] >>
  Q.PAT_ABBREV_TAC `P = ∀v. v ∈ FRANGE xxx ⇒ Cclosed c v` >>
  `P` by (
    qunabbrev_tac`P` >>
    ho_match_mp_tac IN_FRANGE_FUPDATE_LIST_suff >>
    srw_tac[][MAP_ZIP,LENGTH_ZIP,MEM_MAP,MEM_ZIP] >>
    rw[EL_MAP,EL_ZIP] >> rw[pairTheory.UNCURRY] >>
    rw[Once Cclosed_cases,SUBSET_DEF] >>
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    TRY (first_x_assum match_mp_tac >> fsrw_tac[DNF_ss][MEM_EL] >> PROVE_TAC[]) >>
    qmatch_assum_rename_tac `EL i defs = (xs,b)`[] >>
    first_x_assum (qspecl_then [`x`,`EL i defs`] mp_tac) >>
    fs[] >> PROVE_TAC[MEM_EL] ) >>
  fs[Abbr`ls0`] >>
  ntac 7 (pop_assum kall_tac) >>
  disch_then (Q.X_CHOOSE_THEN `res'` strip_assume_tac) >>
  qexists_tac `res'` >> fs[] >>
  unabbrev_all_tac >>
  qmatch_abbrev_tac `Cevaluate c env1 ee rr` >>
  qmatch_assum_abbrev_tac `Cevaluate c (env0 ⊌ env1) ee rr` >>
  qsuff_tac `env0 ⊌ env1 = env1` >- PROVE_TAC[] >>
  rw[GSYM SUBMAP_FUNION_ABSORPTION] >>
  unabbrev_all_tac >>
  ntac 2 (pop_assum kall_tac) >>
  fs[SUBMAP_DEF] >>
  qx_gen_tac `x` >> strip_tac >>
  qpat_assum `LENGTH ns = LENGTH defs` assume_tac >>
  conj_tac >- (
    fsrw_tac[DNF_ss][DRESTRICT_DEF,FDOM_FUPDATE_LIST,pairTheory.EXISTS_PROD,MAP_MAP_o,MEM_MAP,MEM_ZIP,LENGTH_ZIP,MEM_EL,EL_ZIP] >>
    PROVE_TAC[EL_ZIP,pairTheory.PAIR_EQ,pairTheory.pair_CASES] ) >>
  Cases_on `MEM x ns` >- (
    fsrw_tac[DNF_ss][DRESTRICT_DEF] >>
    match_mp_tac FUPDATE_LIST_APPLY_MEM >>
    fs[LENGTH_ZIP,MAP_ZIP,MEM_EL,MAP_MAP_o,combinTheory.o_DEF] >>
    qexists_tac `n` >>
    qpat_assum `n < LENGTH ns` mp_tac >>
    fs[] >> strip_tac >>
    reverse conj_tac >- (
      fs[EL_ALL_DISTINCT_EL_EQ] ) >>
    fs[EL_MAP] >>
    match_mp_tac FUPDATE_LIST_APPLY_MEM >>
    fs[MAP_ZIP,LENGTH_ZIP,MAP_MAP_o,combinTheory.o_DEF] >>
    qexists_tac `n` >> fs[] >>
    reverse conj_tac >- (
      fs[EL_ALL_DISTINCT_EL_EQ] ) >>
    fs[EL_MAP] ) >>
  fs[DRESTRICT_DEF,FDOM_FUPDATE_LIST,MAP_ZIP,MAP_MAP_o,combinTheory.o_DEF] >>
  match_mp_tac FUPDATE_LIST_APPLY_NOT_MEM_matchable >>
  fs[MAP_ZIP,MAP_MAP_o,combinTheory.o_DEF] >>
  match_mp_tac FUPDATE_LIST_APPLY_NOT_MEM_matchable >>
  fs[MAP_ZIP,MAP_MAP_o,combinTheory.o_DEF] >>
  fs[DRESTRICT_DEF,FUNION_DEF] ) >>
strip_tac >- (
  srw_tac[DNF_ss][] >>
  rw[syneq_cases,FLOOKUP_DEF] >>
  rw[DRESTRICT_DEF,optionTheory.OPTREL_def] >>
  `v ∈ FDOM env` by fs[SUBSET_DEF] >> fs[] >>
  fs[fmap_rel_def] >>
  rw[DRESTRICT_DEF,FUNION_DEF] ) >>
strip_tac >- (
  rw[FOLDL_UNION_BIGUNION] >>
  fsrw_tac[DNF_ss][Cevaluate_list_with_value] >>
  qmatch_assum_rename_tac `fmap_rel (syneq c) env env2`[] >>
  rw[Once Cevaluate_cases] >>
  fsrw_tac[DNF_ss][] >>
  disj1_tac >>
  fsrw_tac[DNF_ss][Q.SPECL[`c`,`CRecClos env' ns' defs n`]syneq_cases] >>
  qpat_assum `∀env2 env0. fmap_rel (syneq c) env nv0 ∧ Z ⇒ P` (qspec_then `env2` mp_tac) >>
  fsrw_tac[DNF_ss][] >> rw[] >>
  Q.PAT_ABBREV_TAC `env0 = (X ⊌ Y : string |-> Cv) ` >>
  `∀v. v ∈ FRANGE env0 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    fsrw_tac[DNF_ss][FRANGE_DEF,DRESTRICT_DEF,FUNION_DEF] >>
    PROVE_TAC[] ) >>
  first_x_assum (qspec_then `env0` mp_tac) >> fs[] >>
  rw[] >>
  qmatch_assum_abbrev_tac `Cevaluate c env1 exp (Rval (CRecClos env3 ns' defs n))` >>
  CONV_TAC SWAP_EXISTS_CONV >> qexists_tac `env3` >>
  CONV_TAC SWAP_EXISTS_CONV >> qexists_tac `ns'` >>
  CONV_TAC SWAP_EXISTS_CONV >> qexists_tac `defs` >>
  CONV_TAC SWAP_EXISTS_CONV >> qexists_tac `n` >>
  `env1 = env0` by (
    unabbrev_all_tac >>
    rw[GSYM SUBMAP_FUNION_ABSORPTION] >>
    rw[SUBMAP_DEF,DRESTRICT_DEF,FUNION_DEF] ) >>
  unabbrev_all_tac >>
  fsrw_tac[DNF_ss][] >>
  pop_assum kall_tac >>
  rw[exists_list_GENLIST] >>
  qpat_assum `∀n env1 env2. P` (qspec_then `env2` mp_tac o CONV_RULE SWAP_FORALL_CONV) >>
  `∀n. n < LENGTH es ⇒ free_vars c (EL n es) ⊆ FDOM env` by (
    fsrw_tac[DNF_ss][SUBSET_DEF,MEM_EL] >>
    PROVE_TAC[] ) >>
  fs[] >>
  pop_assum kall_tac >>
  qmatch_assum_abbrev_tac `Cevaluate c env3 exp vv` >>
  disch_then (qspec_then `env3` (mp_tac o SIMP_RULE(srw_ss())[GSYM RIGHT_EXISTS_IMP_THM,SKOLEM_THM])
                  o CONV_RULE SWAP_FORALL_CONV) >>
  `∀v. v ∈ FRANGE env3 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    fsrw_tac[DNF_ss][FRANGE_DEF,DRESTRICT_DEF,FUNION_DEF] >>
    PROVE_TAC[] ) >> fs[] >>
  rw[] >>
  CONV_TAC SWAP_EXISTS_CONV >> qexists_tac `f` >>
  fs[] >>
  `∀n. n < LENGTH vs ⇒ (DRESTRICT env2 (free_vars c (EL n es)) ⊌ env3 = env3)` by (
    unabbrev_all_tac >>
    rw[GSYM SUBMAP_FUNION_ABSORPTION] >>
    srw_tac[DNF_ss][SUBMAP_DEF,DRESTRICT_DEF,FUNION_DEF,MEM_EL] >>
    PROVE_TAC[] ) >>
  fs[] >>
  fs[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_value] >>
  qpat_assum `LENGTH ns = LENGTH vs` assume_tac >>
  fs[FDOM_extend_rec_env] >>
  `∀n. n < LENGTH vs ⇒ every_result (Cclosed c) (Rval (f n))` by (
    qx_gen_tac `m` >> strip_tac >>
    match_mp_tac (MP_CANON Cevaluate_closed) >>
    map_every qexists_tac [`env3`,`EL m es`] >>
    fs[] >>
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    rw[Abbr`env3`] >>
    qmatch_abbrev_tac `a \/ b` >>
    Cases_on `b` >> fs[Abbr`a`] >>
    fsrw_tac[DNF_ss][DRESTRICT_DEF,MEM_EL] >>
    fs[fmap_rel_def] >>
    metis_tac[] ) >>
  `every_result (Cclosed c) vv` by (
    match_mp_tac (MP_CANON Cevaluate_closed) >>
    map_every qexists_tac [`env3`,`exp`] >> fs[] >>
    unabbrev_all_tac >>
    fsrw_tac[DNF_ss][DRESTRICT_DEF,SUBSET_DEF,FUNION_DEF] >>
    fs[fmap_rel_def] ) >>
  fs[Abbr`vv`] >>
  fs[Once(Q.SPECL[`c`,`CRecClos env2' ns' defs n`] Cclosed_cases)] >>
  imp_res_tac find_index_LESS_LENGTH >> fs[] >>
  fs[EVERY_MEM,pairTheory.FORALL_PROD] >>
  qmatch_assum_abbrev_tac `Cevaluate c X exp' res` >>
  qunabbrev_tac`X` >>
  `every_result (Cclosed c) (Rval (CRecClos env' ns' defs n))` by (
    match_mp_tac (MP_CANON Cevaluate_closed) >>
    PROVE_TAC[] ) >>
  `∀n. n < LENGTH vs ⇒ every_result (Cclosed c) (Rval (EL n vs))` by (
    gen_tac >> strip_tac >>
    match_mp_tac (MP_CANON Cevaluate_closed) >>
    fsrw_tac[DNF_ss][SUBSET_DEF,MEM_EL] >>
    METIS_TAC[] ) >>
  fs[Q.SPECL[`c`,`CRecClos env' ns' defs n`]Cclosed_cases] >>
  `free_vars c exp' ⊆ FDOM env' ∪ set ns' ∪ set ns` by (
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    first_x_assum (qspecl_then [`i`,`ns`,`cb`] mp_tac) >>
    rw[] >>
    `MEM (ns,cb) defs` by (rw[MEM_EL] >> qexists_tac `i` >> rw[] >> PROVE_TAC[] ) >>
    fsrw_tac[DNF_ss][optionTheory.OPTREL_def,FLOOKUP_DEF] >>
    first_x_assum (qspecl_then [`ns`,`cb`] mp_tac) >> rw[] >>
    pop_assum (qspec_then `x` mp_tac) >> rw[] >>
    qunabbrev_tac`exp'` >> Cases_on `cb` >> fs[] >>
    fs[FLOOKUP_DEF] >>
    pop_assum mp_tac >> rw[] >> fs[] >>
    fsrw_tac[DNF_ss][MEM_EL] >>
    metis_tac[free_vars_DOMSUB,SUBSET_DEF,IN_UNION]) >>
  fs[] >>
  `∀v. v ∈ FRANGE (extend_rec_env env' env' ns' defs ns vs) ⇒ Cclosed c v` by (
    fs[extend_rec_env_def,FOLDL2_FUPDATE_LIST,FOLDL_FUPDATE_LIST] >>
    match_mp_tac IN_FRANGE_FUPDATE_LIST_suff >>
    fsrw_tac[DNF_ss][MAP_ZIP,MAP2_MAP,SND_pair,FST_pair,MEM_EL,LENGTH_ZIP] >>
    match_mp_tac IN_FRANGE_FUPDATE_LIST_suff >>
    fsrw_tac[DNF_ss][MAP_ZIP,MAP2_MAP,SND_pair,FST_pair,MEM_EL,LENGTH_ZIP,MAP_MAP_o,EL_MAP] >>
    rw[Once Cclosed_cases,MEM_EL] >>
    PROVE_TAC[] ) >>
  fs[] >> rw[] >>
  qunabbrev_tac `env3` >>
  fs[DRESTRICT_FUNION,FUNION_ASSOC] >>
  fsrw_tac[ETA_ss][] >>
  qabbrev_tac `fvs = free_vars c exp ∪ BIGUNION (IMAGE (free_vars c) (set es))` >>
  `∀n. n < LENGTH vs ⇒ (free_vars c (EL n es) ∪ fvs = fvs)` by (
    rw[GSYM SUBSET_UNION_ABSORPTION] >>
    srw_tac[DNF_ss][Abbr`fvs`,SUBSET_DEF,MEM_EL] >>
    PROVE_TAC[] ) >>
  fs[] >>
  Q.PAT_ABBREV_TAC `vs' = GENLIST f X` >>
  Q.PAT_ABBREV_TAC `env3 = (Z:string|->Cv)` >>
  qabbrev_tac `env4 =
    extend_rec_env env2' (DRESTRICT env2' (free_vars c exp' DIFF set ns DIFF set ns') ⊌ env') ns' defs ns vs'` >>
  `∀v. v ∈ FRANGE env4 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    fs[extend_rec_env_def,FOLDL2_FUPDATE_LIST,FOLDL_FUPDATE_LIST] >>
    match_mp_tac IN_FRANGE_FUPDATE_LIST_suff >>
    fsrw_tac[DNF_ss][MAP_ZIP,MAP2_MAP,SND_pair,FST_pair,MEM_EL] >>
    match_mp_tac IN_FRANGE_FUPDATE_LIST_suff >>
    fsrw_tac[DNF_ss][MAP_ZIP,MAP2_MAP,SND_pair,FST_pair,MEM_EL,MAP_MAP_o,EL_MAP] >>
    conj_tac >- (
      match_mp_tac IN_FRANGE_FUNION_suff >> fs[] >>
      match_mp_tac IN_FRANGE_DRESTRICT_suff >> fs[] ) >>
    simp_tac(srw_ss())[Once Cclosed_cases,MEM_EL] >>
    fsrw_tac[DNF_ss][] >>
    conj_tac >- PROVE_TAC[] >>
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    PROVE_TAC[] ) >>
  `∀v. v ∈ FRANGE env3 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    fs[extend_rec_env_def,FOLDL2_FUPDATE_LIST,FOLDL_FUPDATE_LIST] >>
    match_mp_tac IN_FRANGE_FUPDATE_LIST_suff >>
    fsrw_tac[DNF_ss][MAP_ZIP,MAP2_MAP,SND_pair,FST_pair,MEM_EL] >>
    match_mp_tac IN_FRANGE_FUPDATE_LIST_suff >>
    fsrw_tac[DNF_ss][MAP_ZIP,MAP2_MAP,SND_pair,FST_pair,MEM_EL,LENGTH_ZIP,MAP_MAP_o,EL_MAP] >>
    rw[Once Cclosed_cases,MEM_EL] >>
    PROVE_TAC[] ) >>
  first_x_assum (qspecl_then [`env4`,`env3`] mp_tac) >> fs[] >>
  Q.PAT_ABBREV_TAC `P = fmap_rel (syneq c) X Y` >>
  `P` by (
    unabbrev_all_tac >>
    match_mp_tac fmap_rel_extend_rec_env_same >>
    fs[LIST_REL_EL_EQN] >>
    fs[fmap_rel_def,DRESTRICT_DEF,FUNION_DEF,GSYM SUBSET_UNION_ABSORPTION] >>
    conj_tac >- (
      conj_tac >- (fsrw_tac[DNF_ss][SUBSET_DEF] >> PROVE_TAC[]) >>
      rw[] >>
      fs[FLOOKUP_DEF,optionTheory.OPTREL_def] >>
      `MEM (ns,cb) defs` by (rw[MEM_EL] >> qexists_tac `i` >> rw[] >> PROVE_TAC[] ) >>
      first_x_assum (qspecl_then [`ns`,`cb`] mp_tac) >> fs[] >>
      first_x_assum (qspecl_then [`i`,`ns`,`cb`] mp_tac) >> fs[] >>
      Cases_on `cb` >> fs[] >- PROVE_TAC[] >>
      rw[FLOOKUP_DEF] >> fs[] >>
      fsrw_tac[DNF_ss][SUBSET_DEF] >>
      first_x_assum (qspecl_then [`i`,`ns`,`y`] mp_tac) >> fs[] >>
      metis_tac[free_vars_DOMSUB,IN_UNION,SUBSET_DEF]) >>
    simp_tac(srw_ss())[Once syneq_cases] >>
    fs[EVERY_MEM,pairTheory.FORALL_PROD] >>
    rw[] >>
    fs[FLOOKUP_DEF,optionTheory.OPTREL_def] >>
    fs[FUNION_DEF,DRESTRICT_DEF] >>
    PROVE_TAC[syneq_refl,syneq_sym] ) >>
  fs[] >>
  disch_then (Q.X_CHOOSE_THEN `rr` strip_assume_tac) >>
  qmatch_assum_abbrev_tac `Cevaluate c (env0 ⊌ env1) ee rr` >>
  qsuff_tac `env0 ⊌ env1 = env1` >- PROVE_TAC[] >>
  rw[GSYM SUBMAP_FUNION_ABSORPTION] >>
  qunabbrev_tac `env0` >>
  qunabbrev_tac `env1` >>
  `LENGTH vs' = LENGTH ns` by rw[Abbr`vs'`] >>
  qunabbrev_tac `env4` >>
  rw[Once extend_rec_env_FUNION] >>
  qunabbrev_tac `env3` >>
  rw[DRESTRICTED_FUNION] >>
  rw[DIFF_UNION,DRESTRICT_DEF] >>
  Q.PAT_ABBREV_TAC `ss = free_vars c ee DIFF Y DIFF Z DIFF ZZ` >>
  `ss = {}` by (
    unabbrev_all_tac >>
    rw[EXTENSION] >>
    fs[SUBSET_DEF,fmap_rel_def] >>
    Cases_on `MEM x ns` >> fs[] >>
    Cases_on `MEM x ns'` >> fs[] >>
    Cases_on `x ∈ FDOM env2'` >> fs[] >>
    first_x_assum (qspecl_then [`i`,`ns`,`cb`] mp_tac) >>
    first_x_assum (qspecl_then [`i`,`ns`,`cb`] mp_tac) >>
    fs[] >>
    Cases_on `cb` >> fs[] >- METIS_TAC[] >>
    rw[FLOOKUP_DEF] >>
    rpt (pop_assum (qspec_then `x` mp_tac)) >> fs[] >>
    PROVE_TAC[free_vars_DOMSUB,IN_UNION,SUBSET_DEF]) >>
  rw[DRESTRICT_IS_FEMPTY,FUNION_FEMPTY_2] >>
  rw[DIFF_COMM] >>
  Q.ISPECL_THEN [`extend_rec_env env2' FEMPTY ns' defs ns vs'`,`env2'`,`free_vars c ee`] (mp_tac o GSYM) DRESTRICTED_FUNION >>
  rw[DIFF_UNION,DIFF_COMM] >>
  rw[GSYM extend_rec_env_FUNION]) >>
strip_tac >- (
  rw[FOLDL_UNION_BIGUNION] >>
  fsrw_tac[DNF_ss][Cevaluate_list_with_value] >>
  qmatch_assum_rename_tac `fmap_rel (syneq c) env env2`[] >>
  rw[Once Cevaluate_cases] >>
  fsrw_tac[DNF_ss][] >>
  disj2_tac >> disj1_tac >>
  fsrw_tac[DNF_ss][] >>
  qpat_assum `∀env2 env0. fmap_rel (syneq c) env nv0 ∧ Z ⇒ P` (qspec_then `env2` mp_tac) >>
  fsrw_tac[DNF_ss][] >> rw[] >>
  Q.PAT_ABBREV_TAC `env0 = (X ⊌ Y : string |-> Cv) ` >>
  `∀v. v ∈ FRANGE env0 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    fsrw_tac[DNF_ss][FRANGE_DEF,DRESTRICT_DEF,FUNION_DEF] >>
    PROVE_TAC[] ) >>
  first_x_assum (qspec_then `env0` mp_tac) >> fs[] >>
  rw[] >>
  qmatch_assum_rename_tac `syneq c v w`[] >>
  qmatch_assum_abbrev_tac `Cevaluate c env1 exp (Rval w)` >>
  qexists_tac `w` >>
  `env1 = env0` by (
    unabbrev_all_tac >>
    rw[GSYM SUBMAP_FUNION_ABSORPTION] >>
    rw[SUBMAP_DEF,DRESTRICT_DEF,FUNION_DEF] ) >>
  unabbrev_all_tac >>
  fsrw_tac[DNF_ss][] >>
  pop_assum kall_tac >>
  fs[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_error] >>
  qmatch_assum_rename_tac `Cevaluate c env (EL z es) (Rerr err)`[] >>
  qpat_assum `z < LENGTH es` mp_tac >>
  qmatch_assum_rename_tac `m < LENGTH es`[] >>
  strip_tac >>
  qpat_assum `m < LENGTH es` assume_tac >>
  fsrw_tac[DNF_ss,SATISFY_ss][SUBSET_DEF,MEM_EL,result_rel_def] >>
  qexists_tac `m` >> fs[] >>
  first_x_assum (qspec_then `env2` mp_tac) >> fs[] >>
  strip_tac >> conj_tac  >- (
    qmatch_abbrev_tac `Cevaluate c env1 ee rr` >>
    `∀v. v ∈ FRANGE env1 ⇒ Cclosed c v` by (
      unabbrev_all_tac >>
      fsrw_tac[DNF_ss][FRANGE_DEF,DRESTRICT_DEF,FUNION_DEF] >>
      metis_tac[] ) >>
    first_x_assum (qspec_then `env1` mp_tac) >> fs[] >>
    qmatch_abbrev_tac `Cevalutae c (env0 ⊌ env1) ee rr ⇒ Cevaluate c env1 ee rr` >>
    strip_tac >>
    final0 ) >>
  qx_gen_tac `k` >> strip_tac >>
  first_x_assum (qspec_then `k` mp_tac) >>
  `k < LENGTH es` by srw_tac[ARITH_ss][] >>
  fsrw_tac[DNF_ss,SATISFY_ss][SUBSET_DEF,MEM_EL] >>
  rw[] >>
  Q.PAT_ABBREV_TAC `env1 : (string |-> Cv) = X ⊌ Y` >>
  first_x_assum (qspecl_then [`env2`,`env1`] mp_tac) >>
  rw[] >>
  qmatch_assum_abbrev_tac `Cevaluate c (env0 ⊌ env1) ee rr` >>
  qpat_assum `syneq c v w` kall_tac >>
  qmatch_assum_rename_tac `syneq c vv v2`[] >>
  qexists_tac `v2` >> final0) >>
strip_tac >- (
  rw[FOLDL_UNION_BIGUNION] >>
  rw[Once Cevaluate_cases] >>
  fsrw_tac[DNF_ss][] >>
  disj2_tac >> disj2_tac >>
  Q.PAT_ABBREV_TAC`env1 = Z : string |-> Cv` >>
  first_x_assum (qspecl_then [`env'`,`env1`] mp_tac) >> rw[] >>
  `∀v. v ∈ FRANGE env1 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    ho_match_mp_tac IN_FRANGE_FUNION_suff >> fs[] >>
    ho_match_mp_tac IN_FRANGE_DRESTRICT_suff >> fs[] ) >> fs[] >>
  unabbrev_all_tac >>
  fs[DRESTRICT_FUNION,FUNION_ASSOC] >>
  fs[UNION_ASSOC] ) >>
strip_tac >- (
  rw[] >>
  rw[Once Cevaluate_cases] >>
  fsrw_tac[DNF_ss][] >>
  disj1_tac >>
  rw[Cevaluate_list_with_Cevaluate] >>
  fs[Cevaluate_list_with_EVERY] >>
  fsrw_tac[DNF_ss][] >>
  qmatch_assum_rename_tac `fmap_rel (syneq c) env env2`[] >>
  Q.PAT_ABBREV_TAC `env3 = (DRESTRICT env2 X) ⊌ Y` >>
  `∀v. v ∈ FRANGE env3 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    match_mp_tac IN_FRANGE_FUNION_suff >> fs[] >>
    match_mp_tac IN_FRANGE_DRESTRICT_suff >> fs[] ) >>
  first_x_assum (qspecl_then [`env2`,`env3`] mp_tac) >>
  first_x_assum (qspecl_then [`env2`,`env3`] mp_tac) >>
  fs[DRESTRICT_IS_FEMPTY,FUNION_FEMPTY_1] >> rw[] >>
  qmatch_assum_rename_tac `syneq c v1 w1`[] >>
  qmatch_assum_rename_tac `syneq c v2 w2`[] >>
  map_every qexists_tac [`w1`,`w2`] >>
  fs[] >>
  `DRESTRICT env2 (free_vars c e1) ⊌ env3 = env3` by (
    rw[GSYM SUBMAP_FUNION_ABSORPTION] >>
    unabbrev_all_tac >>
    match_mp_tac SUBMAP_FUNION >>
    disj1_tac >>
    rw[DRESTRICT_SUBSET_SUBMAP] ) >>
  `DRESTRICT env2 (free_vars c e2) ⊌ env3 = env3` by (
    rw[GSYM SUBMAP_FUNION_ABSORPTION] >>
    unabbrev_all_tac >>
    match_mp_tac SUBMAP_FUNION >>
    disj1_tac >>
    rw[DRESTRICT_SUBSET_SUBMAP] ) >>
  fs[] >>
  qsuff_tac `CevalPrim2 p2 v1 v2 = CevalPrim2 p2 w1 w2` >- rw[] >>
  PROVE_TAC[CevalPrim2_syneq,syneq_refl,syneq_trans]) >>
strip_tac >- (
  rw[] >>
  rw[Once Cevaluate_cases] >>
  fsrw_tac[DNF_ss][Cevaluate_list_with_Cevaluate,Cevaluate_list_with_error] >>
  disj2_tac >>
  qmatch_assum_rename_tac `Cevaluate c env (EL z [e1;e2]) (Rerr err)`[] >>
  qpat_assum `z < 2` mp_tac >>
  qmatch_assum_rename_tac `n < 2:num`[] >>
  strip_tac >>
  qexists_tac `n` >>
  qmatch_assum_rename_tac `fmap_rel (syneq c) env env2`[] >>
  `∀m. m < 2 ⇒ free_vars c (EL m [e1; e2]) ⊆ FDOM env` by (
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    Cases >> rw[] >>
    qmatch_assum_rename_tac `SUC m < 2`[] >>
    Cases_on `m` >> fsrw_tac[ARITH_ss][]) >>
  qpat_assum `n<2` assume_tac >>
  Q.PAT_ABBREV_TAC `env3 = (DRESTRICT env2 X) ⊌ Y` >>
  `∀v. v ∈ FRANGE env3 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    match_mp_tac IN_FRANGE_FUNION_suff >> fs[] >>
    match_mp_tac IN_FRANGE_DRESTRICT_suff >> fs[] ) >>
  first_x_assum (qspecl_then [`env2`,`env3`] mp_tac) >>
  fs[] >>
  `∀m. m < 2 ⇒ (DRESTRICT env2 (free_vars c (EL m [e1;e2])) ⊌ env3 = env3)` by (
    rw[GSYM SUBMAP_FUNION_ABSORPTION] >>
    unabbrev_all_tac >>
    match_mp_tac SUBMAP_FUNION >>
    disj1_tac >>
    `(m = 0) \/ (m = 1)` by DECIDE_TAC >>
    rw[DRESTRICT_SUBSET_SUBMAP] ) >>
  fs[] >> strip_tac >>
  qx_gen_tac `m` >> strip_tac >>
  qpat_assum `∀m. m < n ⇒ P` (qspec_then `m` mp_tac) >>
  `m < 2` by DECIDE_TAC >>
  fs[] >> rw[] >>
  first_x_assum (qspecl_then [`env2`,`env3`] mp_tac) >>
  rw[] >>
  PROVE_TAC[]) >>
strip_tac >- (
  rpt gen_tac >>
  rpt strip_tac >>
  fsrw_tac[DNF_ss][] >>
  qmatch_assum_rename_tac `fmap_rel (syneq c) env env2`[] >>
  Q.PAT_ABBREV_TAC `env3 = (DRESTRICT env2 X) ⊌ Y` >>
  `∀v. v ∈ FRANGE env3 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    match_mp_tac IN_FRANGE_FUNION_suff >> fs[] >>
    match_mp_tac IN_FRANGE_DRESTRICT_suff >> fs[] ) >>
  rw[Once Cevaluate_cases] >>
  fsrw_tac[DNF_ss][] >>
  disj1_tac >>
  fs[Q.SPECL[`c`,`CLitv(Bool b1)`]syneq_cases] >>
  CONV_TAC SWAP_EXISTS_CONV >> qexists_tac `b1` >>
  `free_vars c (if b1 then e2 else e3) ⊆ FDOM env` by rw[] >>
  first_x_assum (qspecl_then [`env2`,`env3`] mp_tac) >>
  fs[] >>
  `DRESTRICT env2 (free_vars c (if b1 then e2 else e3)) ⊌ env3 = env3` by (
    rw[GSYM SUBMAP_FUNION_ABSORPTION] >>
    unabbrev_all_tac >>
    match_mp_tac SUBMAP_FUNION >>
    disj1_tac >>
    match_mp_tac DRESTRICT_SUBSET_SUBMAP >>
    srw_tac[DNF_ss][SUBSET_DEF]) >> fs[] >>
  first_x_assum (qspecl_then [`env2`,`env3`] mp_tac) >>
  fs[] >>
  `DRESTRICT env2 (free_vars c exp) ⊌ env3 = env3` by (
    rw[GSYM SUBMAP_FUNION_ABSORPTION] >>
    unabbrev_all_tac >>
    match_mp_tac SUBMAP_FUNION >>
    disj1_tac >>
    match_mp_tac DRESTRICT_SUBSET_SUBMAP >>
    srw_tac[DNF_ss][SUBSET_DEF]) >> fs[]) >>
strip_tac >- (
  rw[] >>
  rw[Once Cevaluate_cases] >>
  fsrw_tac[DNF_ss][] >>
  disj2_tac >>
  qmatch_assum_rename_tac `fmap_rel (syneq c) env env2`[] >>
  Q.PAT_ABBREV_TAC `env3 = (DRESTRICT env2 X) ⊌ Y` >>
  `∀v. v ∈ FRANGE env3 ⇒ Cclosed c v` by (
    unabbrev_all_tac >>
    match_mp_tac IN_FRANGE_FUNION_suff >> fs[] >>
    match_mp_tac IN_FRANGE_DRESTRICT_suff >> fs[] ) >>
  first_x_assum (qspecl_then [`env2`,`env3`] mp_tac) >>
  fs[] >>
  `DRESTRICT env2 (free_vars c exp) ⊌ env3 = env3` by (
    rw[GSYM SUBMAP_FUNION_ABSORPTION] >>
    unabbrev_all_tac >>
    match_mp_tac SUBMAP_FUNION >>
    disj1_tac >>
    match_mp_tac DRESTRICT_SUBSET_SUBMAP >>
    srw_tac[DNF_ss][SUBSET_DEF]) >> fs[]) >>
strip_tac >- rw[] >>
strip_tac >- rw[Cevaluate_list_with_cons] >>
strip_tac >- rw[Cevaluate_list_with_cons] >>
rw[Cevaluate_list_with_cons] >>
fsrw_tac[DNF_ss][] >>
metis_tac[])

val Cevaluate_free_vars_env = save_thm(
"Cevaluate_free_vars_env",
Cevaluate_any_env
|> SPEC_ALL
|> SIMP_RULE (srw_ss()) [GSYM AND_IMP_INTRO]
|> UNDISCH_ALL
|> Q.SPEC `env`
|> SIMP_RULE (srw_ss()) [GSYM AND_IMP_INTRO]
|> UNDISCH_ALL
|> Q.SPEC `FEMPTY`
|> SIMP_RULE (srw_ss()) [FUNION_FEMPTY_2]
|> DISCH_ALL
|> Q.GEN `res` |> Q.GEN `exp` |> Q.GEN `env` |> Q.GEN `c`
|> SIMP_RULE (srw_ss()) [AND_IMP_INTRO,GSYM CONJ_ASSOC])

val Cevaluate_determ = store_thm("Cevaluate_determ",
  ``(∀c env exp res. Cevaluate c env exp res ⇒ ∀res'. Cevaluate c env exp res' ⇒ (res' = res)) ∧
    (∀c env exps ress. Cevaluate_list c env exps ress ⇒ ∀ress'. Cevaluate_list c env exps ress' ⇒ (ress' = ress))``,
  ho_match_mp_tac Cevaluate_ind >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- (
    rw[Cevaluate_con] >>
    res_tac >> fs[]) >>
  strip_tac >- (
    rw[Cevaluate_con] >>
    res_tac >> fs[]) >>
  strip_tac >- (
    rw[Cevaluate_tageq] >>
    res_tac >> fs[]) >>
  strip_tac >- (
    rw[Cevaluate_tageq] >>
    res_tac >> fs[]) >>
  strip_tac >- (
    rw[Cevaluate_proj] >>
    res_tac >> fs[]) >>
  strip_tac >- (
    rw[Cevaluate_proj] >>
    res_tac >> fs[]) >>
  strip_tac >- rw[] >>
  strip_tac >- (
    rw[Cevaluate_let_cons] >>
    res_tac >> fs[]) >>
  strip_tac >- (
    rw[Cevaluate_let_cons] >>
    res_tac >> fs[]) >>
  strip_tac >- (
    rw[] >>
    pop_assum mp_tac >>
    rw[Once Cevaluate_cases]) >>
  strip_tac >- (
    rw[] >>
    pop_assum mp_tac >>
    rw[Once Cevaluate_cases]) >>
  strip_tac >- rw[] >>
  strip_tac >- (
    rw[] >>
    pop_assum mp_tac >>
    rw[Once Cevaluate_cases] >>
    res_tac >> fs[] >>
    rw[] >>
    metis_tac[pairTheory.PAIR_EQ]) >>
  strip_tac >- (
    rw[] >>
    pop_assum mp_tac >>
    rw[Once Cevaluate_cases] >>
    res_tac >> fs[]) >>
  strip_tac >- (
    rw[] >>
    pop_assum mp_tac >>
    rw[Once Cevaluate_cases] >>
    res_tac >> fs[]) >>
  strip_tac >- (
    rw[] >>
    pop_assum mp_tac >>
    rw[Once Cevaluate_cases] >>
    res_tac >> fs[]) >>
  strip_tac >- (
    rw[] >>
    pop_assum mp_tac >>
    rw[Once Cevaluate_cases] >>
    res_tac >> fs[]) >>
  strip_tac >- (
    rw[] >>
    pop_assum mp_tac >>
    rw[Once Cevaluate_cases] >>
    res_tac >> fs[]) >>
  strip_tac >- (
    rw[] >>
    pop_assum mp_tac >>
    rw[Once Cevaluate_cases] >>
    res_tac >> fs[]) >>
  strip_tac >- rw[Cevaluate_list_with_Cevaluate] >>
  strip_tac >- (
    rw[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_cons] >>
    res_tac >> fs[] ) >>
  strip_tac >- (
    rw[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_cons] >>
    res_tac >> fs[] ) >>
  strip_tac >- (
    rw[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_cons] >>
    res_tac >> fs[] ))

val _ = export_theory()
