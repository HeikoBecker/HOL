(*---------------------------------------------------------------------------
              HOL configuration script

   First, edit the following user-settable parameters. Then execute this
   file by going

      mosml < configure.sml

 ---------------------------------------------------------------------------*)


(*---------------------------------------------------------------------------
          BEGIN user-settable parameters

   If you are specifying directories under Windows, we recommend you
   use forward slashes (the "/" character) as a directory separator,
   rather than the 'traditional' backslash (the "\" character).  The
   problem with the latter is that you have to double them up (i.e.,
   write "\\") in order to 'escape' them and make the string valid for
   SML.  For example, write "c:/dir1/dir2/mosml", rather than
   "c:\\dir1\\dir2\\mosml", and certainly DON'T write "c:\dir1\dir2\mosml".
  ---------------------------------------------------------------------------*)


(* Uncomment these lines and fill in correct values if smart-configure doesn't
   get the correct values itself.  Then run

      mosml < configure.sml

val mosmldir:string =
val holdir :string  =

val OS :string      =
                           (* Operating system; choices are:
                                "linux", "solaris", "unix", "winNT"   *)
*)


val CC:string       = "gcc";      (* C compiler                       *)
val GNUMAKE:string  = "make";     (* for bdd library and SMV          *)
val DEPDIR:string   = ".HOLMK";   (* where Holmake dependencies kept  *)

(*---------------------------------------------------------------------------
          END user-settable parameters
 ---------------------------------------------------------------------------*)

val _ = Meta.quietdec := true;
app load ["FileSys", "Process", "Path",
          "Substring", "BinIO", "Lexing", "Nonstdio"];

fun check_is_dir role dir =
    (FileSys.isDir dir handle e => false) orelse
    (print "\n*** Bogus directory ("; print dir; print ") given for ";
     print role; print "! ***\n";
     Process.exit Process.failure)

val _ = check_is_dir "mosmldir" mosmldir
val _ = check_is_dir "holdir" holdir
val _ =
    if List.exists (fn s => s = OS) ["linux", "solaris", "unix", "winNT"] then
      ()
    else (print ("\n*** Bad OS specified: "^OS^" ***\n");
          Process.exit Process.failure)

fun normPath s = Path.toString(Path.fromString s)
fun itstrings f [] = raise Fail "itstrings: empty list"
  | itstrings f [x] = x
  | itstrings f (h::t) = f h (itstrings f t);

fun fullPath slist = normPath
   (itstrings (fn chunk => fn path => Path.concat (chunk,path)) slist);

fun quote s = String.concat ["\"",String.toString s,"\""]

val holmakedir = fullPath [holdir, "tools", "Holmake"];
val compiler = fullPath [mosmldir, "bin", "mosmlc"];

(*---------------------------------------------------------------------------
      File handling. The following implements a very simple line
      replacement function: it searchs the source file for a line that
      contains "redex" and then replaces the whole line by "residue". As it
      searches, it copies lines to the target. Each replacement happens
      once; the replacements occur in order. After the last replacement
      is done, the rest of the source is copied to the target.
 ---------------------------------------------------------------------------*)

fun processLinesUntil (istrm,ostrm) (redex,residue) =
 let open TextIO
     fun loop () =
       case inputLine istrm
        of ""   => ()
         | line =>
            let val ssline = Substring.all line
                val (pref, suff) = Substring.position redex ssline
            in
              if Substring.size suff > 0
              then output(ostrm, residue)
              else (output(ostrm, line); loop())
            end
 in
   loop()
 end;

fun fill_holes (src,target) repls =
 let open TextIO
     val istrm = openIn src
     val ostrm = openOut target
  in
     List.app (processLinesUntil (istrm, ostrm)) repls;
     output(ostrm, inputAll istrm);
     closeIn istrm; closeOut ostrm
  end;

infix -->
fun (x --> y) = (x,y);

fun text_copy src dest = fill_holes(src, dest) [];

fun bincopy src dest = let
  val instr = BinIO.openIn src
  val outstr = BinIO.openOut dest
  fun loop () = let
    val v = BinIO.inputN(instr, 1024)
  in
    if Word8Vector.length v = 0 then (BinIO.flushOut outstr;
                                      BinIO.closeOut outstr;
                                      BinIO.closeIn instr)
    else (BinIO.output(outstr, v); loop())
  end
in
  loop()
end;


(*---------------------------------------------------------------------------
     Generate "Systeml" file in tools/Holmake and then load in that file,
     thus defining the Systeml structure for the rest of the configuration
     (with OS-specific stuff available).
 ---------------------------------------------------------------------------*)

(* default values ensure that later things fail if Systeml doesn't compile *)
fun systeml x = (print "Systeml not correctly loaded.\n";
                 Process.exit Process.failure);
val mk_xable = systeml;
val xable_string = systeml;

val OSkind = if OS="linux" orelse OS="solaris" then "unix" else OS
val _ = let
  (* copy system-specific implementation of Systeml into place *)
  val srcfile = fullPath [holmakedir, OSkind ^"-systeml.sml"]
  val destfile = fullPath [holmakedir, "Systeml.sml"]
  val sigfile = fullPath [holmakedir, "Systeml.sig"]
in
  print "\nLoading system specific functions\n";
  use sigfile;
  fill_holes (srcfile, destfile)
  ["val HOLDIR ="   --> ("val HOLDIR = "^quote holdir^"\n"),
   "val MOSMLDIR =" --> ("val MOSMLDIR = "^quote mosmldir^"\n"),
   "val OS ="       --> ("val OS = "^quote OS^"\n"),
   "val DEPDIR ="   --> ("val DEPDIR = "^quote DEPDIR^"\n"),
   "val GNUMAKE ="  --> ("val GNUMAKE = "^quote GNUMAKE^"\n")];
  use destfile
end;

open Systeml;

(*---------------------------------------------------------------------------
     Now compile Systeml.sml in tools/Holmake/
 ---------------------------------------------------------------------------*)

let
  val _ = print "Compiling system specific functions ("
  val modTime = FileSys.modTime
  val dir_0 = FileSys.getDir()
  val sigfile = fullPath [holmakedir, "Systeml.sig"]
  val uifile = fullPath [holmakedir, "Systeml.ui"]
  val sigfile_newer = not (FileSys.access(uifile, [FileSys.A_READ])) orelse
                      Time.>(modTime sigfile, modTime uifile)
  fun die () = (print ")\nFailed to compile system-specific code\n";
                Process.exit Process.failure)
  val systeml = fn l => if systeml l <> Process.success then die() else ()
  fun to_sigobj s = bincopy s (fullPath [holdir, "sigobj", s])
in
  FileSys.chDir holmakedir;
  if sigfile_newer then (systeml [compiler, "-c", "Systeml.sig"];
                         app to_sigobj ["Systeml.sig", "Systeml.ui"];
                         print "sig ") else ();
  systeml [compiler, "-c", "Systeml.sml"];
  to_sigobj "Systeml.uo";
  print "sml)\n";
  FileSys.chDir dir_0
end;



(*---------------------------------------------------------------------------
          String and path operations.
 ---------------------------------------------------------------------------*)

fun echo s = (TextIO.output(TextIO.stdOut, s^"\n");
              TextIO.flushOut TextIO.stdOut);

val _ = echo "Beginning configuration.";

(*---------------------------------------------------------------------------
    Compile Holmake (bypassing the makefile in directory Holmake), then
    put the executable bin/Holmake.
 ---------------------------------------------------------------------------*)

val _ =
 let val _ = echo "Making bin/Holmake."
     val cdir      = FileSys.getDir()
     val hmakedir  = normPath(Path.concat(holdir, "tools/Holmake"))
     val _         = FileSys.chDir hmakedir
     val bin       = fullPath [holdir,   "bin/Holmake"]
     val lexer     = fullPath [mosmldir, "bin/mosmllex"]
     val yaccer    = fullPath [mosmldir, "bin/mosmlyac"]
     val systeml   = fn clist => if systeml clist <> Process.success then
                                   raise Fail ""
                                 else ()
  in
    systeml [yaccer, "Parser.grm"];
    systeml [lexer, "Lexer.lex"];
    systeml [compiler, "-c", "Parser.sig"];
    systeml [compiler, "-c", "Parser.sml"];
    systeml [compiler, "-c", "Lexer.sml" ];
    systeml [compiler, "-c", "Holdep.sml"];
    systeml [lexer, "Holmake_tokens.lex"];
    systeml [compiler, "-c", "internal_functions.sig"];
    systeml [compiler, "-c", "internal_functions.sml"];
    systeml [compiler, "-c", "Holmake_types.sig"];
    systeml [compiler, "-c", "Holmake_types.sml"];
    systeml [compiler, "-c", "Holmake_tokens.sml"];
    if OS <> "winNT" then
      systeml [compiler, "-standalone", "-o", bin, "Holmake.sml"]
    else
      systeml [compiler, "-o", bin, "Holmake.sml"];
    mk_xable bin;
    FileSys.chDir cdir
  end
handle _ => (print "*** Couldn't build Holmake\n";
             Process.exit Process.failure)

(*---------------------------------------------------------------------------
    Compile build.sml, and put it in bin/build.
 ---------------------------------------------------------------------------*)

val _ =
 let open TextIO
     val _ = echo "Making bin/build."
     val target = fullPath [holdir, "tools/build.sml"]
     val bin    = fullPath [holdir, "bin/build"]
     val full_paths =
      let fun ext s = fullPath [holdir,s]
          fun plist [] = raise Fail "plist: empty"
            | plist  [x] = [quote (ext x), "];\n"]
            | plist (h::t) = quote (ext h)::",\n     "::plist  t
      in String.concat o plist
      end
  in
   if systeml [fullPath [mosmldir, "bin/mosmlc"], "-o", bin,
               "-I", holmakedir, target] = Process.success then ()
   else (print "*** Failed to build build executable.\n";
         Process.exit Process.failure) ;
   FileSys.remove (fullPath [holdir,"tools/build.ui"]);
   FileSys.remove (fullPath [holdir,"tools/build.uo"]);
   mk_xable bin
  end;


(*---------------------------------------------------------------------------
    Instantiate tools/hol98-mode.src, and put it in tools/hol98-mode.el
 ---------------------------------------------------------------------------*)

val _ =
 let open TextIO
     val _ = echo "Making hol98-mode.el (for Emacs)"
     val src = fullPath [holdir, "tools/hol98-mode.src"]
    val target = fullPath [holdir, "tools/hol98-mode.el"]
 in
    fill_holes (src, target)
      ["(defvar hol98-executable HOL98-EXECUTABLE\n"
        -->
       ("(defvar hol98-executable \n  "^
        quote (fullPath [holdir, "bin/hol.unquote"])^"\n")]
 end;


(*---------------------------------------------------------------------------
      Generate shell scripts for running HOL.
 ---------------------------------------------------------------------------*)

val _ =
 let val _ = echo "Generating bin/hol."
     val target      = fullPath [holdir, "bin/hol.bare"]
     val qend        = fullPath [holdir, "tools/end-init.sml"]
     val target_boss = fullPath [holdir, "bin/hol"]
     val qend_boss   = fullPath [holdir, "tools/end-init-boss.sml"]
 in
   (* "unquote" scripts use the unquote executable to provide nice
      handling of double-backquote characters *)
   emit_hol_unquote_script target qend;
   emit_hol_unquote_script target_boss qend_boss
 end;

val _ =
 let val _ = echo "Generating bin/hol.noquote."
     val target      = fullPath [holdir,   "bin/hol.bare.noquote"]
     val target_boss = fullPath [holdir,   "bin/hol.noquote"]
     val qend        = fullPath [holdir,   "tools/end-init.sml"]
     val qend_boss   = fullPath [holdir,   "tools/end-init-boss.sml"]
 in
  emit_hol_script target qend;
  emit_hol_script target_boss qend_boss
 end;

(*---------------------------------------------------------------------------
    Compile the quotation preprocessor used by bin/hol.unquote and
    put it in bin/
 ---------------------------------------------------------------------------*)

val _ = let
  val _ = print "Attempting to compile quote filter ... "
  val tgt0 = fullPath [holdir, "tools/quote-filter/quote-filter"]
  val tgt = fullPath [holdir, "bin/unquote"]
  val cwd = FileSys.getDir()
  val _ = FileSys.chDir (fullPath [holdir, "tools/quote-filter"])
in
  if systeml [fullPath [holdir, "bin/Holmake"]] = Process.success
  then let val instrm = BinIO.openIn tgt0
           val ostrm = BinIO.openOut tgt
           val v = BinIO.inputAll instrm
       in
         BinIO.output(ostrm, v);
         BinIO.closeIn instrm;
         BinIO.closeOut ostrm;
         mk_xable tgt;
         print "Quote-filter built\n"
       end
       handle e => print "0.Quote-filter build failed (continuing anyway)\n"
  else             print "1.Quote-filter build failed (continuing anyway)\n"
  ;
  FileSys.chDir cwd
end

(*---------------------------------------------------------------------------
    Configure the muddy library.
 ---------------------------------------------------------------------------*)

local val CFLAGS =
        case OS
         of "linux"   => SOME " -Dunix -O3 -fPIC $(CINCLUDE)"
          | "solaris" => SOME " -Dunix -O3 $(CINCLUDE)"
          |     _     => NONE
      val DLLIBCOMP =
        case OS
         of "linux"   => SOME "ld -shared -o $@ $(COBJS) $(LIBS)"
          | "solaris" => SOME "ld -G -B dynamic -o $@ $(COBJS) $(LIBS)"
          |    _      => NONE
      val ALL =
        if OS="linux" orelse OS="solaris"
        then SOME " muddy.so"
        else NONE
in
val _ =
 let open TextIO
     val _ = echo "Setting up the muddy library Makefile."
     val src    = fullPath [holdir, "tools/makefile.muddy.src"]
     val target = fullPath [holdir, "src/muddy/muddyC/Makefile"]
 in
   case (CFLAGS, DLLIBCOMP, ALL) of
     (SOME s1, SOME s2, SOME s3) => let
       val (cflags, dllibcomp, all) = (s1, s2, s3)
     in
       fill_holes (src,target)
       ["MOSMLHOME=\n"  -->  String.concat["MOSMLHOME=", mosmldir,"\n"],
        "CC=\n"         -->  String.concat["CC=", CC, "\n"],
        "CFLAGS="       -->  String.concat["CFLAGS=",cflags,"\n"],
        "all:\n"        -->  String.concat["all: ",all,"\n"],
        "DLLIBCOMP"     -->  String.concat["\t", dllibcomp, "\n"]]
     end
   | _ =>  print (String.concat
                  ["   Warning! (non-fatal):\n    The muddy package is not ",
                   "expected to build in OS flavour ", quote OS, ".\n",
                   "   On winNT, muddy will be installed from binaries.\n",
                   "   End Warning.\n"])
 end
end; (* local *)

val _ = print "\nFinished configuration!\n";
