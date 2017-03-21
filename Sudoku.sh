#!/bin/bash

sed -n '8,$p' $0 > /tmp/sudoku
gnome-terminal --title "Ben's Sudoku" --geometry 23x20 -e 'bash /tmp/sudoku' 2>/dev/null
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
    D=$(tput setaf 9)
    sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" < <(show_grid) > /tmp/sudoku_check
    cmp -s /tmp/sudoku_check /tmp/sudoku_answer 2>/dev/null
    answer_bool=$?
    (($answer_bool>0)) && C=$(tput setaf 1) || C=$(tput setaf 2)
    sed 's/^/  /;1s/^/\n/;$s/.*/&\n/' < <(show_grid $ref_col $ref_row)
    if (($answer_bool>0)); then
        echo -e "       \e[31mIncorrect\e[0m       \n\n     Keep  trying?     "
        selected='1'
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
    for row in {0..8}; do
        (($row%3)) || echo "${C}+-----+-----+-----+${D}"
        for col in {0..8}; do
            (($col%3)) && echo -n ' ' || echo -n "${C}|${D}"
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
    trap extrap EXIT
    start_time=$(date '+%s')
    ref_col=0
    ref_row=0
    while true; do
        tput reset
        sed 's/^/  /;1s/^/\n/;$s/.*/&\n/' < <(show_grid $ref_col $ref_row)
        read -sn1 key1
        read -sn1 -t 0.0001 key2
        read -sn1 -t 0.0001 key3
        case $key3 in
           A)   (($ref_row==0)) && ref_row=8 || ((ref_row--));;
           B)   (($ref_row==8)) && ref_row=0 || ((ref_row++));;
           C)   (($ref_col==8)) && ref_col=0 || ((ref_col++));;
           D)   (($ref_col==0)) && ref_col=8 || ((ref_col--));;
        esac
        if ((${unprotected[$ref_col,$ref_row]}==1)) 2>/dev/null; then
            [[ "$key1" == [0-9] ]] && grid[$ref_col,$ref_row]="\e[1m$key1\e[0m"
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
    show_grid > /tmp/sudoku_answer
    # Sets difficulty
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
                        unprotected[$del_col,$del_row]=1
                    fi
                done
            done
        done
    done
    navigate
}

check_position() {
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
            grid_num=${grid[$((block_col+square_col)),$((block_row+square_row))]}
            [ -z $grid_num ] && continue
            (($grid_num==$current_num)) && return 0
        done
    done
    return 1
}

randomiser() {
    unset random_numbers
    while ((${#random_numbers[@]}<9)); do
        num=$(($RANDOM%9+1))
        ((${random_numbers[@]/[^$num]/})) || random_numbers+=($num)
    done
}

build() {
    col=${1:-0}
    row=${2:-0}
    (($row>8)) && scatter 6 7 9 9
    ((count++))
    randomiser
    for number in ${random_numbers[@]}; do
        check_position $col $row $number
        check_bool=$?
        if (($check_bool==1)); then
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
    declare -A grid
    while true; do
        echo -e "\n     Ben  Pitman's     \n\n\e[1m  Interactive  Sudoku  \e[0m"

        read
        build
        break
    done
}

main_menu
