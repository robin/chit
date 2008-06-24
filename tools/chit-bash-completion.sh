#
# completion rules for chit
#
# See http://github.com/robin/chit/ for more information about chit
# and http://github.com/melo/chit/ for the main development branch of this
# bash completion file
#
# Very basic stuff, fork and fix :)
#
# Written by Pedro Melo <melo@simplicidade.org>, June 23, 2008
#

function _chit_completion()
{
  local chits priv_chits partial

  chits=$( chit all 2>/dev/null )
  priv_chits=$( chit @all | sed -e 's/^/@/g' 2>/dev/null )
  partial=${COMP_WORDS[COMP_CWORD]}

  COMPREPLY=( $( compgen -W "$chits $priv_chits" -- $partial ) )

  return 0
}

complete -F _chit_completion -o default chit
