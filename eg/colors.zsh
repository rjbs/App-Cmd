# colors -- complete to the colors of the rainbow
#
# Source this file alongside the palette zsh completion script.  The
# fn:colors completion spec in palette's opt_spec causes the generated
# _arguments action to call colors() directly.  compadd handles prefix
# matching automatically.

colors() {
    compadd red orange yellow green blue indigo violet
}
