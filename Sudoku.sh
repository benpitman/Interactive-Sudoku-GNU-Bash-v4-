#!/bin/bash

# Creates a copy of the script to tmp for it to be executed in a new terminal
sed -n '8,$p' $0 >| /tmp/sudoku
gnome-terminal --title "Sudoku" --geometry 23x20+850+350 -e 'bash /tmp/sudoku' 2>/dev/null
exit

extrap() {
    tput setaf 9
}

check_answer() {
    # Default colour
    D=$(tput setaf 9)
    # Remove text formatting from grid and output to tmp
    sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2}(;[0-9]{1,2})?)?)?[mGK]//g" < <(show_grid) >| /tmp/sudoku_check
    # Compare files
    cmp -s /tmp/sudoku_check /tmp/sudoku_answer 2>/dev/null
    answer_bool=$?
    selected=1
    # If files match set colour to green, if not set to red
    (($answer_bool>0)) && C=$(tput setaf 1) || C=$(tput setaf 2)
    get_time
    while true; do
        tput reset
        echo -e "\e[0m$time_taken\n\e[36m+---------------------+"
        sed "s/^/$(echo -e '\e[36m|\e[0m') /;s/$/ $(echo -e '\e[36m|')/" < <(show_grid)
        if (($answer_bool>0)); then
            case $selected in
                1)  YES='\e[36;1mYES\e[0m'
                    NO='NO';;
                0)  YES='YES'
                    NO='\e[36;1mNO\e[0m';;
            esac
            echo -en "|\e[0m      \e[31mIncorrect\e[0m      \e[36m|
                    \r|\e[0m                     \e[36m|
                    \r|\e[0m    Keep  trying?    \e[36m|
                    \r|\e[0m      $YES    $NO      \e[36m|
                    \r+---------------------+"
            get_time
            read -sn1 -t1 key1
            (($?==142)) && continue
            read -sn1 -t 0.0001 key2
            read -sn1 -t 0.0001 key3
            [[ "$key3" == [CD] ]] && ((selected^=1))
            if [ -z "$key1" ]; then
                (($selected)) && break || exit
            fi
        else
            case $selected in
                1)  NEW='\e[36;1mNEW GAME\e[0m'
                    MENU='MAIN MENU';;
                0)  NEW='NEW GAME'
                    MENU='\e[36;1mMAIN MENU\e[0m';;
            esac
            echo -en "|\e[0m       \e[32mCorrect\e[0m       \e[36m|
                    \r|\e[0m                     \e[36m|
                    \r|\e[0m $NEW  $MENU \e[36m|
                    \r|\e[0m                     \e[36m|
                    \r+---------------------+"
            read -sn1 key1
            read -sn1 -t 0.0001 key2
            read -sn1 -t 0.0001 key3
            [[ "$key3" == [CD] ]] && ((selected^=1))
            if [ -z "$key1" ]; then
                # Bashing and exiting is quickest way to clear the variables
                if (($selected)); then
                    bash "$0" "${difficulty[@]}"
                else
                    bash "$0"
                fi
                exit
            fi
        fi
        unset key1 key2 key3
    done
    unset C D
}

quit_reset() {
    selected=0
    query=$(printf '%-6s' "$1?")
    while true; do
        tput reset
        case $selected in
            1)  YES='\e[36;1mYES\e[0m'
                NO='NO';;
            0)  YES='YES'
                NO='\e[36;1mNO\e[0m';;
        esac
        get_time
        echo -e "\e[0m$time_taken\n\e[36m+---------------------+"
        sed "s/^/$(echo -e '\e[36m|\e[0m') /;s/$/ $(echo -e '\e[36m|')/" < <(show_grid)
        echo -en "|\e[0m                     \e[36m|
                \r|\e[0m    Are you sure     \e[36m|
                \r|\e[0m  you want to $query \e[36m|
                \r|\e[0m      $YES    $NO      \e[36m|
                \r\e[36m+---------------------+"
        read -sn1 -t1 key1
        (($?==142)) && continue
        read -sn1 -t 0.0001 key2
        read -sn1 -t 0.0001 key3
        [[ "$key3" == [CD] ]] && ((selected^=1))
        if [ -z "$key1" ]; then
            if (($selected)); then
                [[ "$1" == "quit" ]] && exit
                if [[ "$1" == "reset" ]]; then
                    # Clears the puzzle of all guesses and resets the timer
                    declare -A grid
                    for index in "${!grid_reset[@]}"; do
                        grid[$index]="${grid_reset[$index]}"
                    done
                    navigate
                fi
            fi
            break
        fi
        unset key1 key2 key3
    done
}

pause() {
    # Pause and help menu screen
    selected=1
    while true; do
        tput reset
        case $selected in
            1)  RETURN='\e[36;1mRETURN\e[0m'
                MENU='MAIN MENU';;
            0)  RETURN='RETURN'
                MENU='\e[36;1mMAIN MENU\e[0m';;
        esac
        echo -en "\e[0m$time_taken\n\e[36m+---------------------+
                \r|\e[0m                     \e[36m|
                \r|\e[0m        \e[1mPAUSE\e[0m        \e[36m|
                \r|\e[0m                     \e[36m|
                \r|\e[0m                     \e[36m|
                \r$(show_help)
                \r|\e[0m                     \e[36m|
                \r|\e[0m                     \e[36m|
                \r|\e[0m  $RETURN  $MENU  \e[36m|
                \r|\e[0m                     \e[36m|
                \r\e[36m+---------------------+"
        read -sn1 key1
        read -sn1 -t 0.0001 key2
        read -sn1 -t 0.0001 key3
        [[ "$key3" == [CD] ]] && ((selected^=1))
        if [ -z "$key1" ]; then
            (($selected)) && break || { bash "$0"; exit; }
        fi
        unset key1 key2 key3
    done
}

show_grid() {
    # Loop though rows and columns printing appropriate grid referenes
    for row in {0..8}; do
        (($row%3)) || echo "${C}+-----+-----+-----+${D}"
        for col in {0..8}; do
            (($col%3)) && echo -n ' ' || echo -n "${C}|${D}"
            # Checks if grid ref is highlighted by cursor
            if (($ref_col==$col && $ref_row==$row)) 2>/dev/null; then
                echo -en "\e[$colour_num;1;4m${grid[$col,$row]}\e[0m"
            else
                echo -en "${grid[$col,$row]}"
            fi
        done
        echo "${C}|${D}"
    done
    echo "${C}+-----+-----+-----+${D}"
}

get_time() {
    # Calculate current time taken
    time_taken_s=$(($(date '+%s')-$start_time))
    time_taken=$(printf 'Time Taken: %02dh:%02dm:%02ds' \
            $(($time_taken_s/3600)) $(($time_taken_s%3600/60)) $(($time_taken_s%60)))
}

navigate() {
    # Run extrap on EXIT status
    trap extrap EXIT
    # Save epoch for timer
    [ -z "$start_time" ] && start_time=$(date '+%s')
    # Set start position
    ref_col=0
    ref_row=0
    # Set start colour
    colour_num=36
    while true; do
        # Clear screen and scroll history
        tput reset
        get_time
        echo -e "$time_taken\n\e[36m+---------------------+"
        # Print puzzle with boarder
        sed "s/^/$(echo -e '\e[36m|\e[0m') /;s/$/ $(echo -e '\e[36m|')/" < <(show_grid)
        echo -en '|\e[0m                     \e[36m|
                \r|\e[0m                     \e[36m|
                \r|\e[0m                     \e[36m|
                \r|\e[0m                     \e[36m|
                \r+---------------------+'
        # Arrow keys are three characters long
        read -sn1 -t1 key1
        # Refresh the screen every second to update timer
        (($?==142)) && continue
        read -sn1 -t 0.0001 key2
        read -sn1 -t 0.0001 key3
        case $key3 in
           A)   (($ref_row==0)) && ref_row=8 || ((ref_row--));; # Up
           B)   (($ref_row==8)) && ref_row=0 || ((ref_row++));; # Down
           C)   (($ref_col==8)) && ref_col=0 || ((ref_col++));; # Right
           D)   (($ref_col==0)) && ref_col=8 || ((ref_col--));; # Left
        esac
        case "$key1" in
            c)      check_answer;;
            h|p)    pause_time_start=$(date '+%s')
                    pause
                    pause_time_finish=$(date '+%s')
                    ((start_time+=$(($pause_time_finish-$pause_time_start))));;
            q)      quit_reset "quit";;
            r)      quit_reset "reset";;
            s)      colour_num=$(($colour_num==36?31:$colour_num+1));;
        esac
        # Checks if selected square is editable
        if ((${unprotected[$ref_col,$ref_row]}==1)) 2>/dev/null; then
            # If a number is input then it replaces the current grid reference
            [[ "$key1" == [1-9] ]] && grid[$ref_col,$ref_row]="\e[${colour_num}m$key1\e[0m"
            # If a hyphen is input then it removes the current grid reference
            [[ "$key1" == '-' ]] && grid[$ref_col,$ref_row]=' '
        fi
        unset key1 key2 key3
    done
}

scatter() {
    # Saves the filled puzzle before it gets scattered
    show_grid >| /tmp/sudoku_answer
    # Sets likelyhood of more or less squares to be cleared (difficulty)
    # High numbers increases likelyhood. Subsequent matching or lower numbers are ignored
    range3="0-$1"
    range4="$(($1==0?$1:$1+1))-$2"
    range5="$(($2==0?$2:$2+1))-$3"
    range6="$(($3==0?$3:$3+1))-$4"
    range7="$(($3==0?$4:$4+1))-$5"
    declare -A unprotected
    for block_row in 0 3 6; do
        for block_col in 0 3 6; do
            randomiser
            case $(($RANDOM%100+1)) in
                [$range3]*) match_rand=("${random_numbers[@]:0:3}");;
                [$range4]*) match_rand=("${random_numbers[@]:0:4}");;
                [$range5]*) match_rand=("${random_numbers[@]:0:5}");;
                [$range6]*) match_rand=("${random_numbers[@]:0:6}");;
                [$range7]*) match_rand=("${random_numbers[@]:0:7}");;
            esac
            for square_row in 0 1 2; do
                for square_col in 0 1 2; do
                    if grep -q $(($square_col*3+$square_row+1)) <<< "${match_rand[@]}"; then
                        del_col=$(($block_col+$square_col))
                        del_row=$(($block_row+$square_row))
                        grid[$del_col,$del_row]=' '
                        # Sets selected grid reference as editable
                        unprotected[$del_col,$del_row]=1
                    fi
                done
            done
        done
    done
    # Create copy of the scattered grid for a reset if needed
    declare -A grid_reset
    for index in "${!grid[@]}"; do
        grid_reset[$index]="${grid[$index]}"
    done
    navigate
}

check_position() {
    # Checks all numbers in row, column and neighbouring squares for matching number
    current_col=$1
    current_row=$2
    current_num=$3
    for check_col in {0..8}; do
        grid_num=${grid[$check_col,$current_row]}
        [ -z $grid_num ] && continue
        (($grid_num==$current_num)) && return 0
    done
    for check_row in {0..8}; do
        grid_num=${grid[$current_col,$check_row]}
        [ -z $grid_num ] && continue
        (($grid_num==$current_num)) && return 0
    done
    block_col=$(($current_col/3*3))
    block_row=$(($current_row/3*3))
    for square_row in 0 1 2; do
        for square_col in 0 1 2; do
            # Cycles through 1-9 from right to left, top to bottom in each block of 3x3
            grid_num=${grid[$((block_col+square_col)),$((block_row+square_row))]}
            [ -z $grid_num ] && continue
            (($grid_num==$current_num)) && return 0
        done
    done
    return 1
}

randomiser() {
    unset random_numbers
    # Create an array filled with random numbers between 1-9 with no duplicates
    while ((${#random_numbers[@]}<9)); do
        num=$(($RANDOM%9+1))
        ((${random_numbers[@]/[^$num]/})) || random_numbers+=($num)
    done
}

build() {
    col=$1
    row=$2
    (($row>8)) && scatter "${difficulty[@]}"
    randomiser
    # Recursive function call to allow stepping back through loops
    for number in ${random_numbers[@]}; do
        check_position $col $row $number
        if (($?==1)); then
            grid[$col,$row]=$number
            if (($col<8)); then
                ((col++))
            else
                col=0
                ((row++))
            fi
            build $col $row
        fi
    done
    if (($col>0)); then
        ((col--))
    else
        col=8
        ((row--))
    fi
    unset grid[$col,$row]
}

set_difficulty() {
    if [ -z "$*" ]; then
        selected=2
        while true; do
            tput reset
            case $selected in
                4)  VERY_EASY='\e[1;36mVERY  EASY\e[0m'
                    difficulty=(9 9 9 9 9)
                    unset EASY NORMAL HARD VERY_HARD;;
                3)  EASY='\e[1;36mEASY\e[0m'
                    difficulty=(4 9 9 9 9)
                    unset VERY_EASY NORMAL HARD VERY_HARD;;
                2)  NORMAL='\e[1;36mNORMAL\e[0m'
                    difficulty=(0 4 9 9 9)
                    unset VERY_EASY EASY HARD VERY_HARD;;
                1)  HARD='\e[1;36mHARD\e[0m'
                    difficulty=(0 0 4 9 9)
                    unset VERY_EASY EASY NORMAL VERY_HARD;;
                0)  VERY_HARD='\e[1;36mVERY  HARD\e[0m'
                    difficulty=(0 0 0 4 9)
                    unset VERY_EASY EASY NORMAL HARD;;
            esac
            VERY_EASY=${VERY_EASY:-'VERY  EASY'}
            EASY=${EASY:-'EASY'}
            NORMAL=${NORMAL:-'NORMAL'}
            HARD=${HARD:-'HARD'}
            VERY_HARD=${VERY_HARD:-'VERY  HARD'}
            echo -en "\e[36m+---------------------+
                    \r|\e[0m                     \e[36m|
                    \r|\e[0m                     \e[36m|
                    \r|\e[0m  \e[1mChoose Difficulty\e[0m  \e[36m|
                    \r|\e[0m                     \e[36m|
                    \r|\e[0m                     \e[36m|
                    \r|\e[0m                     \e[36m|
                    \r|\e[0m     $VERY_EASY      \e[36m|
                    \r|\e[0m                     \e[36m|
                    \r|\e[0m        $EASY         \e[36m|
                    \r|\e[0m                     \e[36m|
                    \r|\e[0m       $NORMAL        \e[36m|
                    \r|\e[0m                     \e[36m|
                    \r|\e[0m        $HARD         \e[36m|
                    \r|\e[0m                     \e[36m|
                    \r|\e[0m     $VERY_HARD      \e[36m|
                    \r|\e[0m                     \e[36m|
                    \r|\e[0m                     \e[36m|
                    \r|\e[0m                     \e[36m|
                    \r\e[36m+---------------------+"
            read -sn1 key1
            read -sn1 -t 0.0001 key2
            read -sn1 -t 0.0001 key3
            case $key3 in
               A)   (($selected==4)) && selected=0 || ((selected++));; # Up
               B)   (($selected==0)) && selected=4 || ((selected--));; # Down
            esac
            [ -z "$key1" ] && break
            unset key1 key2 key3
        done
    else
        difficulty=("$@")
    fi
    build 0 0
}

show_help() {
    echo -e '|\e[0m     \e[1mCheat Sheet\e[0m     \e[36m|
            \r|\e[0m                     \e[36m|
            \r|\e[0mArrow Keys - Move    \e[36m|
            \r|\e[0m    -      - Clear   \e[36m|
            \r|\e[0m    C      - Check   \e[36m|
            \r|\e[0m   P/H     - Help    \e[36m|
            \r|\e[0m    R      - Restart \e[36m|
            \r|\e[0m    S      - Colour  \e[36m|
            \r|\e[0m Q/Ctrl-C  - Quit    \e[36m|'
}

main_menu() {
    # Display the main menu
    selected=1
    while true; do
        tput reset
        case $selected in
            1)  START='\e[1;36mSTART\e[0m'
                QUIT='QUIT';;
            0)  START='START'
                QUIT='\e[1;36mQUIT\e[0m';;
        esac
        echo -en "\e[36m+---------------------+
                \r|\e[0m                     \e[36m|
                \r|\e[0m    Ben  Pitman's    \e[36m|
                \r|\e[0m \e[1mInteractive  Sudoku\e[0m \e[36m|
                \r|\e[0m                     \e[36m|
                \r|\e[0m                     \e[36m|
                \r$(show_help)
                \r|\e[0m                     \e[36m|
                \r|\e[0m                     \e[36m|
                \r|\e[0m    $START    $QUIT    \e[36m|
                \r|\e[0m                     \e[36m|
                \r\e[36m+---------------------+"
        read -sn1 key1
        read -sn1 -t 0.0001 key2
        read -sn1 -t 0.0001 key3
        # Bit-switches selected item between 0 and 1
        [[ "$key3" == [CD] ]] && ((selected^=1))
        if [ -z "$key1" ]; then
            (($selected)) && set_difficulty || exit
        fi
        unset key1 key2 key3
    done
}

# Initialise grid and check if the main menu should be displayed
declare -A grid
[ -z "$1" ] && main_menu || set_difficulty "$@"
