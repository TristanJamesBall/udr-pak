Short, repo-specific guidance for AI agents working on udr-pak

Purpose
- Provide minimal, actionable knowledge to be productive immediately: build/install, key files, conventions, examples, and concrete gotchas.

Top actions (first 3)
1. Read these files (priority):
   - Makefile
   - sql/udr-pak_REG.sql and sql/udr-pak_UNREG.sql
   - tracing/tracing.h / tracing/tracing.c
   - runtime/runtime.h / runtime/runtime.c
   - Examples: util/util.c, prng/prng.c, uuid/uuid.c
2. Build locally: make -> artifact build/lib/udr-pak.so
   - If the link step fails: make LD=gcc
   - To use custom Informix SDK: make SDKDIR=/path/to/sdk
3. Install (requires Informix env & permissions): make install (runs dbaccess on SQL registration). Verify with ./extra/show_install.sh

Big picture
- Single Informix extension .so: built from SRCDIRS in Makefile: tracing runtime seq prng uuid realtime.
- SQL ↔ C boundary: sql/udr-pak_REG.sql maps SQL names to exported C symbols inside the .so.
- Runtime helpers are in runtime/; tracing is in tracing/.

Critical repo conventions & gotchas
- Trace class names MUST NOT contain '.' (see tracing/tracing.h); use e.g. "udrpak" or "udrpak_mem".
- Memory lifetimes: use udr_alloc (PER_COMMAND) vs udr_alloc_ret (PER_ROUTINE). For iterator state call get_func_state_ptr(sz,fParam) (see util/util.c).
- Exporting a new SQL function: add C to SRCDIR, add registration in sql/udr-pak_REG.sql using .so(symbol), make && make install, then verify with ./extra/show_install.sh.
- Makefile quirk: LD used at link time is not defined — use make LD=gcc or apply the Makefile change.

Build & debug quick tips
- Build: make (include final 20 lines of output when reporting failures).
- Install: make install (needs INFORMIXDIR and appropriate permissions).
- Verify installed objects: ./extra/show_install.sh
- Smoke test SQL: dbaccess tjb sql/demo_small.sql
- Bench: bench/udr_bench.sh

PR checklist for AI agents
- Reference exact file paths and minimal diffs.
- Run make locally and paste build output in PR.
- If adding exports, update sql/udr-pak_REG.sql (and UNREG) lines in the same PR.
- Avoid '.' in trace class names and don't change systraceclasses structure without DB verification.

