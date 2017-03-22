#!/bin/bash

# Creates a copy of the script to tmp for it to be executed in a new terminal
sed -n '8,$p' $0 > /tmp/sudoku
gnome-terminal --title "Sudoku" --geometry 23x20 -e 'bash /tmp/sudoku' 2>/dev/null
exit

extrap() {
    rm /tmp/sudoku*
    echo -en '\e[0m'
}

stats() {
    time_taken_s=$(($finish_time-$start_time))
    printf '%02dh:%02dm:%02ds\n' $(($time_taken_s/3600)) $(($time_taken_s%3600/60)) $(($time_taken_s%60))
    read
    exit
}

check_answer() {
    # Default colour
    D=$(tput setaf 9)
    # Remove text formatting from grid and output to tmp
    sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" < <(show_grid) > /tmp/sudoku_check
    # Compare files
    cmp -s /tmp/sudoku_check /tmp/sudoku_answer 2>/dev/null
    answer_bool=$?
    # If files match set colour to green, if not set to
    (($answer_bool>0)) && C=$(tput setaf 1) || C=$(tput setaf 2)
    sed 's/^/  /;1s/^/\n/;$s/.*/&\n/' < <(show_grid $ref_col $ref_row)
    if (($answer_bool>0)); then
        echo -e "       \e[31mIncorrect\e[0m       \n\n     Keep  trying?     "
        selected='1'
        # Interactive YES/NO menu
        while true; do
            case $selected in
                1)  YES='\e[1mYES\e[0m'
                    NO='NO';;
                0)  YES='YES'
                    NO='\e[1mNO\e[0m';;
            esac
            echo -en "\r       $YES    $NO       "
            read -sn1 key1
            read -sn1 -t 0.0001 key2
            read -sn1 -t 0.0001 key3
            # Bit-switches selected item between 0 and 1
            [[ "$key3" == [CD] ]] && ((selected^=1))
            if [ -z "$key1" ]; then
                finish_time=$(date '+%s')
                (($selected)) && break || stats
            fi
            unset key1 key2 key3
        done
        unset C D
    else
        finish_time=$(date '+%s')
        echo -e "        \e[32mCorrect\e[0m        \n"
        read -sp $'      Press enter      \n     to view stats     '
        stats
    fi
}

show_grid() {
    # Lopp though rows and columns printing appropriate grid referenes
    for row in {0..8}; do
        (($row%3)) || echo "${C}+-----+-----+-----+${D}"
        for col in {0..8}; do
            (($col%3)) && echo -n ' ' || echo -n "${C}|${D}"
            # Checks if grid ref is highlighted by cursor
            if (($ref_col==$col && $ref_row==$row)) 2>/dev/null; then
                echo -en "\e[1;4m${grid[$col,$row]}\e[0;24m"
            else
                echo -en "${grid[$col,$row]}"
            fi
        done
        echo "${C}|${D}"
    done
    echo "${C}+-----+-----+-----+${D}"
}

navigate() {
    # Runs extrap on exit status
    trap extrap EXIT
    # Save epoch for timer
    start_time=$(date '+%s')
    ref_col=0
    ref_row=0
    while true; do
        # Clear screen and scroll history
        tput reset
        # Print puzzle with additional formatting
        sed 's/^/  /;1s/^/\n/;$s/.*/&\n/' < <(show_grid $ref_col $ref_row)
        # Arrow keys are three characters long
        read -sn1 key1
        read -sn1 -t 0.0001 key2
        read -sn1 -t 0.0001 key3
        case $key3 in
           A)   (($ref_row==0)) && ref_row=8 || ((ref_row--));; # Up
           B)   (($ref_row==8)) && ref_row=0 || ((ref_row++));; # Down
           C)   (($ref_col==8)) && ref_col=0 || ((ref_col++));; # Right
           D)   (($ref_col==0)) && ref_col=8 || ((ref_col--));; # Left
        esac
        # Checks if selected square is editable
        if ((${unprotected[$ref_col,$ref_row]}==1)) 2>/dev/null; then
            # If a number is input then it replaces the current grid reference
            [[ "$key1" == [1-9] ]] && grid[$ref_col,$ref_row]="\e[1m$key1\e[0m"
            # If a hyphen is input then it removes the current grid reference
            [[ "$key1" == '-' ]] && grid[$ref_col,$ref_row]=' '
        fi
        case "$key1" in
            c)  tput reset
                check_answer;;
            h)  tput reset
                show_help

                ;;
        esac
        unset key1 key2 key3
    done
}

scatter() {
    # Saves the filled puzzle before it gets scattered
    show_grid > /tmp/sudoku_answer
    # Sets likelyhood of more or less squares to be cleared (difficulty)
    # High numbers increases likelyhood. Subsequent matching or lower numbers are ignored
    range4="0-$1"
    range5="$(($1+1))-$2"
    range6="$(($2+1))-$3"
    range7="$(($3+1))-$4"
    declare -A unprotected
    for block_row in 0 3 6; do
        for block_col in 0 3 6; do
            randomiser
            case $(($RANDOM%100)) in
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
    # Default is 0 unless stated
    col=${1:-0}
    row=${2:-0}
    (($row>8)) && scatter 6 7 8 9
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

main_menu() {
    # Initialise the puzzle and display the main menu
    declare -A grid
    while true; do
        echo -e "\n     Ben  Pitman's     \n\n\e[1m  Interactive  Sudoku  \e[0m"

        read
        build
        break
    done
}

main_menu
