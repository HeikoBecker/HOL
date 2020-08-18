signature psMinimize =
sig

  include Abbrev

  datatype Proof =
    Tactic of (string * goal)
  | Then   of (Proof * Proof)
  | Thenl  of (Proof * Proof list)

  val mini_tactic_time : real ref
  val mini_proof_time : real ref

  val minimize_stac : real -> string -> goal -> goal list -> string
  val requote_sproof : string -> string
  val minimize_proof : Proof -> Proof
  val reconstruct : goal -> Proof -> string

end
