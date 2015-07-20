
This is a quick hack to experiment with combining the C preprocessor and BlitzMax.

Usage:
 - rename BlitzMax/bin/bmk to BlitzMax/bin/bmk_real
 - copy the script here called bmk to the old one's location
 - run short programs from the IDE normally

Recompiling BlitzMax's tools is not required.

What this does is rewrite BlitzMax comments using `'` to C-style comments using `//`,
recapitalizes #if and #endif and so on, then runs the preprocessor with removed
annotations in an attempt to preserve line numbering.

This is just an experiment. Limitations include conflicting with #Label, and this
doesn't work correctly with quick builds or for writing Importable modules (as it
generates a renamed temporary file), although these are probably fixable. It also
relies on C-style operators in any preprocessor expressions (e.g. `!=` and `==` instead
of `<>` and `=`).

Still, it's a start. Beats the native directives.
