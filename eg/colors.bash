# colors -- complete to the colors of the rainbow
#
# Source this file alongside the palette bash completion script.  The
# fn:colors completion spec in palette's opt_spec causes the generated
# completion function to call colors() with the current word as $1.

colors() {
    compgen -W "red orange yellow green blue indigo violet" -- "$1"
}
