#!/bin/bash

sbox_L1_1=( "101" "010" "001" "110" "011" "100" "111" "000" )
sbox_L1_2=( "001" "100" "110" "010" "000" "111" "101" "011" )

sbox_R1_1=( "100" "000" "110" "101" "111" "001" "011" "010" )
sbox_R1_2=( "101" "011" "000" "111" "110" "010" "001" "100" )

while getopts "he:d:k:" opt
do
        case $opt in
                h) clear
                echo -e "

███████ ██ ███    ███ ██████  ██      ███████         ██████  ███████ ███████
██      ██ ████  ████ ██   ██ ██      ██              ██   ██ ██      ██
███████ ██ ██ ████ ██ ██████  ██      █████           ██   ██ █████   ███████
     ██ ██ ██  ██  ██ ██      ██      ██              ██   ██ ██           ██
███████ ██ ██      ██ ██      ███████ ███████ ███████ ██████  ███████ ███████

-e encrypt
-d decrypt
-k key
                "
                exit;;
                e) data=$OPTARG
                        what=0;;
                d) data=$OPTARG
                        what=1;;
                k) m_key=$OPTARG
                [[ "$m_key" =~ ${m_key//?/(.)} ]]
                m_key=( "${BASH_REMATCH[@]:1}")
                ;;

        esac
done





function split_data {
        local set1=$1
        L=$(echo $set1 | cut -c -6)
        R=$(echo $set1 | cut -c 7-)
}

function key_gen {


        #m_key="010011001"


        if [ "${#m_key[@]}" != 9 ]
        then
                echo "No key given / key lenght invalid"
                exit
        fi
        local i=0
        local shiftr=$(("$1"))
        while [ $i -le 7 ]
        do
                local sw="$(($i + $shiftr))"
                if [ $sw -gt 9 ]
                then
                        local sw="$(($sw-9))"
                fi


                if [ $sw -le 0 ]
                then
                        local sw="$(($sw+9))"
                fi
                cur_key+="${m_key[$(($sw))]}"
                ((i++))

        done

}
# xor
function XOR {
        local set1=$1
        [[ "$set1" =~ ${set1//?/(.)} ]]
        local set1=( "${BASH_REMATCH[@]:1}")

        local set2=$2
        [[ "$set2" =~ ${set2//?/(.)} ]]
        local set2=( "${BASH_REMATCH[@]:1}")

        local i=0
        xor_res=""
        while [ $i -le $(("${#set2[@]}"-1)) ]
        do
                xor_res+=$(( ("${set1[$i]}"+"${set2[$i]}") % 2 ))

                ((i++))
        done
}

function expand_f {
        local set1="$1"
        [[ "$set1" =~ ${set1//?/(.)} ]]
        local set1=( "${BASH_REMATCH[@]:1}")

        expanded="${set1[0]}""${set1[1]}""${set1[3]}""${set1[2]}""${set1[3]}""${set1[2]}""${set1[3]}""${set1[5]}"
}
function f {
        local set1="$1"
        local key="$2"
        XOR "$set1" "$key"
        # $xor_res => split 4bit L1 R1 => s-Box



        sbox_L="$(echo $xor_res | cut -c -4)"

        sbox_Lr="$(echo $sbox_L | cut -c 2-4 )"

        sbox_Lr=$( echo "obase=10;ibase=2;$sbox_Lr" | bc)

        if [ "$(echo $sbox_L | cut -c 1)" = 0 ]
        then

                sbox_L="${sbox_L1_1[$sbox_Lr]}"
        else

                sbox_L="${sbox_L1_2[$sbox_Lr]}"
        fi

        sbox_R=$(echo "$xor_res" | cut -c 5-)
        sbox_Rr="$(echo $sbox_R | cut -c 2-4 ) "
        sbox_Rr=$( echo "obase=10;ibase=2;$sbox_Rr" | bc)

        if [ "$(echo $sbox_R | cut -c 1)" = 0 ]
                then

                        sbox_R="${sbox_R1_1[$sbox_Rr]}"
                else

                        sbox_R="${sbox_R1_2[$sbox_Rr]}"
                fi
        enc_R="$sbox_L$sbox_R"


}

if [ "$what" = 0 ]
then

        i=0

        split_data $data
        while [ $i -le 4 ]
        do
                ((i++))

                expand_f $R


                key_gen $i



                f "$expanded" "$cur_key"


                XOR $L $enc_R
                L=$R
                R="$xor_res"
                cur_key=""


                echo "--$i. key round"

        done
        echo "enc: $R $L"

else
        i=5

        split_data $data
        while [ $i -gt 0 ]
        do
                expand_f $R
                key_gen $i
                f $expanded $cur_key
                XOR $L $enc_R
                L=$R
                R=$xor_res
                cur_key=""


                echo "--$i. key round"
                ((i--))
        done
        echo "dec: $R $L"
fi
