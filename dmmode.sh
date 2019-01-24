#Environment Variables of dmmode
DM_CC='gcc'
DM_CXX='g++'
#Override env var here if you want
#DISTCC_HOSTS="localhost/2 --localslots_cpp=$(echo "$(nproc) * 4" | bc)"

# Blue "\[\033[44m\]"
# High Itensity Blue "\[\033[0;104m\]"
DM_BASH_COLOR='\[\033[0;104m\]'
DM_BASH_NC='\[\033[0m\]'
#Color for zsh. Note: Not all background colors are supported by some teerminals.
#Here are possible names of colors
#   black blink blue conceal cyan green magenta red white yellow
DM_ZSH_COLOR='%K{blue}%F{white}'
DM_ZSH_NC='%{$reset_color%}'
#Set to y if you want to make the state show before your PS1 setting
DM_PUT_BEFORE_PS1="n"
#Set to y if you want to use the version detection function
#If distcc servers have all versions of gcc, set this to y could improve compatibility
DM_AUTO_VERSION_DETECTION="y"

# DO NOT EDIT THE VARIABLES AFTER THIS LINE UNLESS YOU KNOW THE RISK!!
# DO NOT EDIT THE VARIABLES AFTER THIS LINE UNLESS YOU KNOW THE RISK!!
# DO NOT EDIT THE VARIABLES AFTER THIS LINE UNLESS YOU KNOW THE RISK!!
function _dmmode_bash() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--help distcc ccache both reset"

    if [[ ${cur} == * ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
}

function _dmmode_zsh() {
    local -a options
    options=('--help:Display help message and information of usage!!!' \
             'reset:Reset shell to original mode' \
             'distcc:Set shell to distcc state. alias CC,CXX,CPP in "make" with the optimal number of -j' \
             'ccache:Set shell to ccache state. alias CC,CXX,CPP in "make" with the optimal number of -j' \
             'both:Set shell to ccache + distcc state. alias CC,CXX,CPP in "make" with the optimal number of -j' \
            )
    _describe 'values' options
}

if [[ -n "$ZSH_VERSION" ]]; then
    # assume Zsh
    compdef _dmmode_zsh dmmode
    autoload colors && colors
    DM_COLOR="$DM_ZSH_COLOR"
    DM_NC="$DM_ZSH_NC"
elif [[ -n "$BASH_VERSION" ]]; then
    # assume Bash
    complete -F _dmmode_bash dmmode
    DM_COLOR="$DM_BASH_COLOR"
    DM_NC="$DM_BASH_NC"
else
    # asume something else
    echo "No completion support in this shell";
    DM_COLOR="$DM_BASH_COLOR"
    DM_NC="$DM_BASH_NC"
fi

function _dmmode_ask_confirm()
{
    local user_decision=""

    while [[ "yes" != "${user_decision}" && "no" != "${user_decision}" ]]
    do
        if [[ -n "$ZSH_VERSION" ]]; then
            read user_decision\?"contiune[yes/no]?"
        else
            read -p "contiune[yes/no]? " user_decision
        fi
    done

    [[ "yes" == "${user_decision}" ]] && echo "yes"
}

function prompt_dmmode() {
    local dmmode_sym="%F{red}M%F{black} "
    local distcc_bg=195
    local ccache_bg=226

    if [[ "$BULLETTRAIN_PROMPT_ORDER" != "" ]]; then
        # Use bullet train prompt
        [[ "$DM_DISTCC_ENABLEED" == 'y' ]] && prompt_segment $distcc_bg black "${dmmode_sym}distcc"
        [[ "$DM_CCACHE_ENABLEED" == 'y' ]] && prompt_segment $ccache_bg black "${dmmode_sym}ccache"
        return 0;
    fi
}

function _dmmode_set_prompt() {
    if [[ "$BULLETTRAIN_PROMPT_ORDER" != "" ]]; then
        BULLETTRAIN_PROMPT_ORDER[$BULLETTRAIN_PROMPT_ORDER[(i)dmmode]]=()
        if [[ "$DM_PUT_BEFORE_PS1" == 'y' ]]; then
            BULLETTRAIN_PROMPT_ORDER=(dmmode $BULLETTRAIN_PROMPT_ORDER)
        else
            BULLETTRAIN_PROMPT_ORDER+=dmmode
        fi
        return 0;
    fi
}

function _dmmode_set_ps1() {
    local mode_str
    mode_str="${DM_COLOR}${1}${DM_NC} "
    [[ -n "$2" ]] && mode_str=${mode_str}"${DM_COLOR}${2}${DM_NC} "

    # Try set prompt for zsh. Exit when succeed
    _dmmode_set_prompt && return 0
    if [[ "$DM_PUT_BEFORE_PS1" == 'y' ]]; then
        export PS1=${mode_str}$ORIG_PS1
    else
        export PS1=${ORIG_PS1}${mode_str}
    fi
}

function _dmmode_set_gcc_version() {
    local gcc_ver

    #Initialize to the default value
    DM_CC_V="$DM_CC"
    DM_CXX_V="$DM_CXX"

    gcc_ver=$(${DM_CC} --version | head -n1 | cut -d' ' -f3 | cut -d'.' -f1,2)
    if [[ -n "$gcc_ver" ]] && [[ "$DM_AUTO_VERSION_DETECTION" == "y" ]]; then
        if [[ ! -f "/usr/bin/gcc-${gcc_ver}" ]]; then
            echo "Creating symbolic link for gcc-${gcc_ver}?"
            echo '    Set DM_AUTO_VERSION_DETECTION="n" to disable this function'
            if [[ "$(_dmmode_ask_confirm)" == "yes" ]]; then
                echo "Creating symbolic link for gcc..."
                sudo ln -s "/usr/bin/$DM_CC" "/usr/bin/gcc-${gcc_ver}"
                sudo ln -s "/usr/bin/$DM_CXX" "/usr/bin/g++-${gcc_ver}"
            fi
        fi
        DM_CC_V="gcc-${gcc_ver}"
        DM_CXX_V="g++-${gcc_ver}"
    fi
}

function _dmmode_print_help(){
    echo "dmmode"
    echo "Version: 1.0"
    echo ""
    echo "Usage:"
    echo "  --help         Display This help message"
    echo "  reset          Reset shell to original mode"
    echo "  distcc         Set shell to distcc state. alias CC,CXX,CPP in 'make' with the optimal number of -j"
    echo "  ccache         Set shell to ccache state. alias CC,CXX,CPP in 'make' with the optimal number of -j"
    echo "  both           Set shell to ccache + distcc state. alias CC,CXX,CPP in 'make' with the optimal number of -j"
    echo ""
    echo "Helpful Notes/Features:"
    echo "    If you have the same gcc toolchain version on the distcc servers, "
    echo "    you don't need to change any setting in the script."
    echo ""
    echo "  RUN ANY VERSION OF GCC ON YOUR COMPUTER:"
    echo "    If you have a distcc servers which have all versions of gcc (the future features of this tool),"
    echo "    you can set DM_AUTO_VERSION_DETECTION=\"y\" to enable the compatibility function."
    echo "    Once you have set this flag to \"y\", the gcc version on your computer won't matter at all."
    echo "    This tool will automatically help you to set correct settings to make your distcc works (on the client side)."
    echo "    You can still use any gcc version you have on your computer by setting \"DM_CC\" and \"DM_CXX\" variables in the script."
    echo ""
    echo "  HOW TO SPECIFY -j FOR YOUR MAKE:"
    echo "    You can easily add \"-jX\" to your make command. The argument will override the original one in the alias."
    echo "    No matter what number of \"-j\" is in the alias, you always can force the number to be any number you want."
    echo "    For example: "
    echo "        make -j4"
    echo ""
    echo "  HOW TO SPECIFY COMPILER VERSION:"
    echo "    Modify the variables, \"DM_CC\" and \"DM_CXX\" in this script."
    echo ""
}

function dmmode() {
    echo "dmmode $0 $1"

    local num_cores num_j make_alias

    case "$1" in
    "-h") _dmmode_print_help;;
    "--help") _dmmode_print_help;;
    "reset")
        [[ -n "$(alias | grep 'colormake')" ]] && unalias colormake
        [[ -n "$(alias | grep 'make')" ]] && unalias make
        [ "$ORIG_PS1" != '' ] && export PS1=$ORIG_PS1

        #Reset memory
        ORIG_PS1=''
        DM_DISTCC_ENABLEED=''
        DM_CCACHE_ENABLEED=''
        unset CCACHE_PREFIX
        return 0
        ;;
    "distcc") DM_DISTCC_ENABLEED='y' ;;
    "ccache") DM_CCACHE_ENABLEED='y' ;;
    "both")
        DM_DISTCC_ENABLEED='y'
        DM_CCACHE_ENABLEED='y'
        ;;
    esac

    #Backup original env vars when it's first time
    [[ "$ORIG_PS1" == '' ]] && ORIG_PS1=$PS1

    _dmmode_set_gcc_version

    #Set up env vars
    if [[ "$DM_DISTCC_ENABLEED" == 'y' ]] && \
       [[ "$DM_CCACHE_ENABLEED" == 'y' ]]; then
        _dmmode_set_ps1 "ccache" "distcc"
        num_cores=$(distcc -j)
        num_j=$(echo "${num_cores} * 7 / 5" | bc)
        make_alias=$(printf \
            'CC="ccache %s" CXX="ccache %s" -j%d' \
            $DM_CC_V $DM_CXX_V $num_j)
        export DISTCC_PAUSE_TIME_MSEC=300
        #Only set this when use both
        export CCACHE_PREFIX="distcc "
    elif [[ "$DM_DISTCC_ENABLEED" == 'y' ]]; then
        _dmmode_set_ps1 "distcc"
        num_cores=$(distcc -j)
        num_j=$(echo "${num_cores} * 7 / 5" | bc)
        make_alias=$(printf \
            'CC="distcc %s" CXX="distcc %s" -j%d' \
            $DM_CC_V $DM_CXX_V $num_j)
        export DISTCC_PAUSE_TIME_MSEC=300
    elif [[ "$DM_CCACHE_ENABLEED" == 'y' ]]; then
        _dmmode_set_ps1 "ccache"
        make_alias=$(printf \
            'CC="ccache %s" CXX="ccache %s" -j%d' \
            $DM_CC_V $DM_CXX_V $(nproc))
    else
        #Exit when there is no mode set. The following lines are common actions
        return 0;
    fi

    if [[ "$(echo ${DISTCC_HOSTS} | grep "localslots_cpp")" == "" ]] ; then
        DISTCC_HOSTS="${DISTCC_HOSTS} --localslots_cpp=$(echo "$(nproc) * 4" | bc)"
    fi

    alias make='make '$make_alias
    alias colormake='colormake '$make_alias
    #Show current settings of env vars
    echo "Current settings:"
    echo "  CCACHE_PREFIX=$CCACHE_PREFIX"
    echo "  DISTCC_HOSTS=$DISTCC_HOSTS"
    echo "  alias make='make $make_alias'"
    echo "  alias colormake='colormake $make_alias'"
}
#This is for updating shell state in case user source their shell config
dmmode

#
# This is the end of dmmode code
#

