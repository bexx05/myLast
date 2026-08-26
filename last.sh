#!/bin/bash

N=$((2**20-1))
SINCE=""
TILL=""
PRESENT=""
USER=""
CONTOR=0
declare -a NAME=()
declare -a METHOD=()
declare -a BEGIN=()
declare -a END=()
declare -A PID=()
# key=process id, value=index. key=0 pentru gdm-greeter

verificare_user(){
    if [ -z "$USER" ]; then
        cat
    else
        grep -aF "$USER"
    fi
    #F fixed regex
}

flag_s(){
    
    ok=0
    if [ -z "$SINCE" ]; then
        cat
    else
        while read -r linie; do
            tmp=$(echo "$linie" | awk '{print $1}')
            tmp=$(date +%s -d "$tmp")
            if [ "$tmp" -ge "$SINCE" ]; then
                echo "$linie"
            else
                ok=1
            fi
        done
    fi
    if [ "$ok" -eq 1 ];then
    	SINCE=""
    fi
}

flag_t(){
    if [ -z "$TILL" ]; then
        cat
    else
        while read -r linie; do
            tmp=$(echo "$linie" | awk '{print $1}')
            tmp=$(date +%s -d "$tmp")
            if [ "$tmp" -lt "$TILL" ]; then
                echo "$linie"
            else
                break
            fi
        done
    fi
}

prelucrare(){
    while read -r line; do
        if [[ "$line" =~ pam_unix\(gdm-launch-environment:session\):\ session\ opened\ for\ user\ gdm-greeter ]]; then
        #2026-01-01T00:42:29.409797+00:00 Ubuntu25 gdm-launch-environment]: pam_unix(gdm-launch-environment:session): session opened for user gdm-greeter(uid=60578) by (uid=0)
            if [[ -v PID[0] ]]; then
                continue
            else
                PID[0]=$CONTOR
            fi
            BEGIN+=("$(awk '{print $1}' <<< "$line")")
            END+=("")
            NAME+=("gdm-greeter")
            METHOD+=("tty1")
            CONTOR=$((CONTOR+1))

        elif [[ "$line" =~ pam_unix\(gdm-launch-environment:session\):\ session\ closed\ for\ user\ gdm-greeter ]]; then
        #2026-01-01T00:43:29.947226+00:00 Ubuntu25 gdm-launch-environment]: pam_unix(gdm-launch-environment:session): session closed for user gdm-greeter
            if [[ -v PID[0] ]]; then
                I=${PID[0]}
                if [[ $I =~ ^[0-9]+$ ]]  ; then
                    END[$I]="$(awk '{print $1}' <<< "$line")"
                fi
                unset PID[0]
            fi

        elif [[ "$line" =~ systemd-logind\[[0-9]+\]:\ New\ session\ [0-9]+\ of\ user ]] && [[ ! "$line" =~ gdm-greeter ]]; then
            #2026-01-01T00:43:17.270924+00:00 Ubuntu25 systemd-logind[1132]: New session 2 of user admin.
            # 1                                2        3                    4    5      6 7   8    9
            KEY="$(awk '{print $3}' <<< "$line" | grep -oP '\d+')"
            if [[ -n "$KEY" ]] && [[ -v PID["$KEY"] ]]; then
                continue
            else
                PID["$KEY"]=$CONTOR
            fi
            BEGIN+=("$(awk '{print $1}' <<< "$line")")
            END+=("")
            NAME+=("$(awk '{print $9}' <<< "$line" | sed 's/\.$//')")
            METHOD+=("tty$(awk '{print $6}' <<< "$line")")
            CONTOR=$((CONTOR+1))

        elif [[ "$line" =~ systemd-logind\[[0-9]+\]:\ Session\ [0-9]+\ logged\ out ]] && [[ ! "$line" =~ gdm-greeter ]]; then
            #2026-01-01T00:39:22.959322+00:00 Ubuntu25 systemd-logind[1129]: Session 2 logged out. Waiting for processes to exit.
            KEY="$(awk '{print $3}' <<< "$line" | grep -oP '\d+')"
            if [[ -n "$KEY" ]] && [[ -v PID["$KEY"] ]]; then
                I=${PID["$KEY"]}
                if [[ $I =~ ^[0-9]+$ ]] ; then
                    END[$I]="$(awk '{print $1}' <<< "$line")"
                fi
                unset PID["$KEY"]
            fi
	
	elif [[ "$line" =~ sshd ]] && [[ "$line" =~ session\ opened\ for\ user ]]; then
	#2025-12-08T23:11:08.030045+02:00 elizaboros-VirtualBox sshd[6054]: pam_unix(sshd:session): session opened for user elizaboros(uid=1000) by elizaboros(uid=0)
	    KEY="$(awk '{print $3}' <<< "$line" | grep -oP '\d+')"
            if [[ -n "$KEY" ]] && [[ -v PID["$KEY"] ]]; then
                continue
            else
                PID["$KEY"]=$CONTOR
            fi
            BEGIN+=("$(awk '{print $1}' <<< "$line")")
            END+=("")
            NAME+=("$(awk '{print $9}' <<< "$line" | sed 's/(.*//')")
            METHOD+=("ssh")
            CONTOR=$((CONTOR+1))

	elif [[ "$line" =~ pam_unix\(sshd:session\):\ session\ closed\ for\ user ]]; then
	#2025-12-08T23:11:08.190851+02:00 elizaboros-VirtualBox sshd[6054]: pam_unix(sshd:session): session closed for user elizaboros
	    KEY="$(awk '{print $3}' <<< "$line" | grep -oP '\d+')"
            if [[ -n "$KEY" ]] && [[ -v PID["$KEY"] ]]; then
                I=${PID["$KEY"]}
                if [[ $I =~ ^[0-9]+$ ]] ; then
                    END[$I]="$(awk '{print $1}' <<< "$line")"
                fi
                unset PID["$KEY"]
            fi
            
        elif [[ "$line" =~ su\[[0-9]+\]:\ \(to\ root\)\ root\ on ]]; then
            #2026-01-01T00:45:25.422637+00:00 Ubuntu25 su[6035]: (to root) root on pts/1
            KEY="$(awk '{print $3}' <<< "$line" | grep -oP '\d+')"
            if [[ -n "$KEY" ]] && [[ -v PID["$KEY"] ]]; then
                continue
            else
                PID["$KEY"]=$CONTOR
            fi
            BEGIN+=("$(awk '{print $1}' <<< "$line")")
            END+=("")
            NAME+=("root")
            METHOD+=("$(awk '{print $8}' <<< "$line")")
            CONTOR=$((CONTOR+1))

        elif [[ "$line" =~ su\[[0-9]+\]:\ pam_unix\(su:session\):\ session\ closed\ for\ user\ root ]]; then
            #2026-01-01T00:45:25.448198+00:00 Ubuntu25 su[6035]: pam_unix(su:session): session closed for user root
            KEY="$(awk '{print $3}' <<< "$line" | grep -oP '\d+')"
            #echo "$KEY"
            if [[ -n "$KEY" ]] && [[ -v PID["$KEY"] ]]; then
                I=${PID["$KEY"]}
                if [[ $I =~ ^[0-9]+$ ]] ; then
                    END[$I]="$(awk '{print $1}' <<< "$line")"
                fi
                unset PID["$KEY"]
            fi
        fi
    done

    if [[ -v PID[0] ]]; then
        unset PID[0]
    fi
}

afisare(){
#echo "$INDEX"
    CONTOR=$((CONTOR-1))
    for ((i=CONTOR; i>=0; i--)); do
        printf "%s   %s   " "${NAME[i]}" "${METHOD[i]}"
        printf "%s   " "$(date -d "${BEGIN[i]}" +"%a %b %d %H:%M")"
        if [ -z "${END[i]}" ]; then
            printf "still logged in"
        else
            printf "%s    " "$(date -d "${END[i]}" +"%a %b %d %H:%M")"
            end=$(date +%s -d "${END[i]}")
            begin=$(date +%s -d "${BEGIN[i]}")
            time=$(($end - $begin))
            if [ "$time" -lt 0 ];then
            	printf "\n"
            	continue
            fi
            if [ $time -lt 60 ]; then
                printf "%s seconds" "$time"
            elif [ $time -lt 86400 ]; then
                printf "%s:%s" "$(($time/(3600)))" "$(($time%(60)))"
            else
                days=$(($time/(86400)))
                if [ $days -eq 1 ]; then
                    printf "1 day"
                elif [ $days -lt 7 ]; then
                    printf "%s days" "$days"
                elif [ $days -eq 7 ]; then
                    printf "1 week"
                else
                    printf "%s weeks" "$(($days/(7)))"
                fi
            fi
        fi
        printf "\n"
    done
    NAME=()
    METHOD=()
    BEGIN=()
    END=()

}

verificare_optiune(){
    CONTOR=0
    INDEX=0
    FISIERE=("/var/log/auth.log"
    "/var/log/auth.log.1"
    "/var/log/auth.log.2.gz"
    "/var/log/auth.log.3.gz"
    "/var/log/auth.log.4.gz")
    
    if [ -n "$SINCE" ];then
    	SINCE=$(date +%s -d "$SINCE")
    fi
    
    if [ -n "$TILL" ];then
        TILL=$(date +%s -d "$TILL")
    fi
    
    if [ -n "$PRESENT" ];then
    	PRESENT=$(date +%s -d "$PRESENT")
    	NEXTDAY=$(($PRESENT+ 86400))
    	if [ -z "$SINCE" ];then
    		SINCE="$PRESENT"
    	else
    		SINCE=$(( SINCE > PRESENT ? SINCE : PRESENT ))
    	fi
    	if [ -z "$TILL" ]; then
    		TILL="$NEXTDAY"
    	else
    		TILL=$(( TILL < NEXTDAY ? TILL : NEXTDAY))
    	fi
    fi
    
    if [ -n "$TILL" ] && [ -n "$SINCE" ] && [ "$TILL" -lt "$SINCE" ];then
    	echo "Interval de timp invalid"
    	exit 1
    fi
    
    while [ "$N" -gt 0 ] && [ "$INDEX" -lt 5 ]; do
        CONTOR=0
        prelucrare < <(
            if [ "$INDEX" -lt 2 ]; then
                cat "${FISIERE[INDEX]}" |
                grep -a -v "polkit" |
                grep -a -v "CRON" |
                verificare_user |
                flag_s |
                flag_t 
            else
                gunzip -c "${FISIERE[INDEX]}" 2>/dev/null |
                grep -a -v "polkit" |
                grep -a -v "CRON" |
                verificare_user |
                flag_s |
                flag_t 
            fi
        )

        INDEX=$((INDEX + 1))
        if [ "$CONTOR" -gt "$N" ]; then
            CONTOR="$N"
            N=0
        else
            N=$((N - CONTOR))
        fi
        afisare
    done
}

get_input(){
    while [ "$#" -gt 0 ]; do
        case "$1" in
        -n)
            N=$2
            shift 2
            ;;
        -s)
            SINCE=$2
            shift 2
            ;;
        -t)
            TILL=$2
            shift 2
            ;;
        -p)
            PRESENT=$2
            shift 2
            ;;
        *)
            if [ "$#" = 1 ] && id "$1" &>/dev/null; then
                USER="$1"
                shift 1
            else
                echo "Eroare de sintaxa"
                exit 1
            fi
            ;;
        esac
    done
}

get_input "$@"
verificare_optiune
