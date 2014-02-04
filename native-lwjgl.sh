#!/bin/ksh
# Lighly modified from a script posted by the user amracks in the
# FreeBSD forums at http://forums.freebsd.org/viewtopic.php?f=5&t=42932

WORKDIR="$HOME/workdir/lwjgl-lwjgl2.9.1"
LWJGL_JLP_OVRD="$WORKDIR/libs/openbsd"
LWJGL_OVRD="$WORKDIR/libs/lwjgl.jar"
LWJGL_UTIL_OVRD="$WORKDIR/libs/lwjgl_util.jar"

export JAVA_HOME=/usr/local/jdk-1.7.0

build_classpath() {
    j=0
    ocp=`echo ${1} | sed 's/:/ /g'`
    for p in ${ocp}
    do
        if [[ $p == *lwjgl-* ]]
        then
            ncp[$j]=${LWJGL_OVRD}
        elif [[ $p == *lwjgl_util* ]]
        then
            ncp[$j]=${LWJGL_UTIL_OVRD}
        else
            ncp[$j]=${p}
        fi
        j=$(( j + 1 ))
    done

    cp=`echo ${ncp[@]} | sed 's/ /:/g'`
}

i=0
for var in "${@}"
do
    if [[ "$var" == -Djava.library* ]]
    then
	# Yes, the next line is supposed to have 'FreeBSD' because OpenBSD
	# is not (yet) recognized as a supported platform in lwjgl.
        args[$i]="-Djava.library.path=${LWJGL_JLP_OVRD} -Dos.name=FreeBSD"
    elif [[ "$var" == *lwjgl_util* ]]
    then
        build_classpath "${var}"
        args[$i]="$cp"
    else
        args[$i]=$var
    fi
        i=$(( i + 1 ))
done

${JAVA_HOME}/jre/bin/java ${args[@]}
