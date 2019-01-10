#!/bin/bash




##### Define functions #####
#Print the help menu
function print_help_menu() {
    cat <<helpChunk
    
    ###########################################################################
                  This is the help menu for SequelQC version 1.1.0
    ###########################################################################
    Dependencies for this program are samtools, Python, and R.
    For this help menu use the argument -h or no arguments.
    Required argument: -u

    Notes: a subedCLR is a CLR containing at least one subread

    All arguments:
    -u : A file listing the names of subreads .bam sequence files
    -c : A file listing the names of scraps .bam sequence files
    -n : The number of threads to use for extracting information from .bam 
         files for each .bam file. Default is '1'
    -o : Folder to output results to. Default is 'SequelQCresults'
    -v : A verbose option for those who want updates as the program progresses
    -k : Keep intermediate files (these are removed by default)
    -g : Groups desired (only works when scraps files are included). Options: 
         'a' for all (CLRs, subedCLRs, subreads, and longest subreads), and 
         'b' for basic (subedCLRs and subreads).  Default is 'a'
    -p : Plots desired.  Options: 'b' for basic (N50 barplot, summary data
         table, and total bases barplot), 'i' for intermediate (N50 barplot, 
         summary data table, total bases barplot, ZOR plot, PSR plot, boxplot
         of subread read lengths with N50, boxplot of subedCLR read lengths 
         with N50), and 'a' for all (N50 barplot, L50 barplot, summary data 
         table, read length histograms, total bases barplot, ZOR plot, PSR plot 
         Boxplot of subread read lengths with N50, boxplot of subedCLR read 
         lengths with N50, subreads/CLR frequency plot, and adapters/CLR 
         frequency plot).  Default is 'i'. The boxplot of subedCLR read 
         lengths with N50, subreads/CLR frequency plot, and adapters/CLR 
         frequency plot are only produced if scraps files are included.
    -h : opens this help menu
helpChunk
    exit 1
}

#Set an array of files and line numbers to pass to R .  Arg 1=ARGS_FOR_R Arg 2 is I
function make_args_for_R_array() {
    if [ "$NOSCRAPS" == true ]; then
        FILES_FOR_R+="$BASE.SMRTcellStats_noScraps.txt,"
        FILES_FOR_R+="$BASE.readLens.sub.txt,"
        FILES_FOR_R+="$BASE.readLens.longSub.txt,"
        LENGTHS_FOR_R+="$(wc -l "$BASE.SMRTcellStats_noScraps.txt" | cut -f 1 -d ' '),"
        LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.sub.txt" | cut -f 1 -d ' '),"
        LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.longSub.txt" | cut -f 1 -d ' '),"
    else
        if [ "$GROUPS_DESIRED" == "a" ]; then
            FILES_FOR_R+="$BASE.SMRTcellStats_wScrapsA.txt,"
            FILES_FOR_R+="$BASE.readLens.sub.txt,"
            FILES_FOR_R+="$BASE.readLens.clr.txt,"
            FILES_FOR_R+="$BASE.readLens.subedClr.txt,"
            FILES_FOR_R+="$BASE.readLens.longSub.txt,"
            FILES_FOR_R+="$BASE.clrStats.txt,"
            LENGTHS_FOR_R+="$(wc -l "$BASE.SMRTcellStats_wScrapsA.txt" | cut -f 1 -d ' '),"
            LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.sub.txt" | cut -f 1 -d ' '),"
            LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.clr.txt" | cut -f 1 -d ' '),"
            LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.subedClr.txt" | cut -f 1 -d ' '),"
            LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.longSub.txt" | cut -f 1 -d ' '),"
            LENGTHS_FOR_R+="$(wc -l "$BASE.clrStats.txt" | cut -f 1 -d ' '),"

        elif [ "$GROUPS_DESIRED" == "b"   ]; then
            FILES_FOR_R+="$BASE.SMRTcellStats_wScrapsB.txt,"
            FILES_FOR_R+="$BASE.readLens.sub.txt,"
            FILES_FOR_R+="$BASE.readLens.subedClr.txt,"
            FILES_FOR_R+="$BASE.readLens.longSub.txt,"
            FILES_FOR_R+="$BASE.clrStats.txt,"
            LENGTHS_FOR_R+="$(wc -l "$BASE.SMRTcellStats_wScrapsB.txt" | cut -f 1 -d ' '),"
            LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.sub.txt" | cut -f 1 -d ' '),"
            LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.subedClr.txt" | cut -f 1 -d ' '),"
            LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.longSub.txt" | cut -f 1 -d ' '),"
            LENGTHS_FOR_R+="$(wc -l "$BASE.clrStats.txt" | cut -f 1 -d ' '),"
        fi
    fi
}




##### SCRIPT BODY #####
#If no arguments are given, print help menu and exit
if [ $# -eq 0 ]; then
    print_help_menu
fi


#Check that the user has Python and determine Python version 
command -v python >/dev/null 2>&1 || {
    echo -e >&2 "\nERROR: This program requires Python to run."
    echo >&2 "You do not seem to have Python."
    print_help_menu
}

PY_VER=$(python -c 'import sys; print("%d" % (sys.version_info[0]))')


#Check that user has R
command -v Rscript >/dev/null 2>&1 || {
    echo -e >&2 "\nERROR: This program requires Rscript to run."
    echo >&2 "You do not seem to have Rscript."
    print_help_menu
}

#Check that the user has samtools
command -v samtools >/dev/null 2>&1 || {
    echo -e >&2 "\nERROR: This program requires samtools to run."
    echo >&2 "You do not seem to have samtools."
    print_help_menu
}

#Assign defaults to variables
SUBREADS_FILES_BAM=""
SCRAPS_FILES_BAM=""
NTHREADS=1
VERBOSE=false
KEEP=false
REQUIRED_PAR=0 #used to determine whether all required parameters were used
GROUPS_DESIRED='a'
PLOTS_DESIRED='i'
OUT_FOLD='SequelQCresults'
NOSCRAPS=true #whether to run in NOSCRAPS mode or not

#Go through input and assign input arguments to variables
while getopts ":u:c:o:n:g:p:vkh" opt; do
    case ${opt} in 
      u )
        SUBREADS_FILES_BAM=$OPTARG
        (( REQUIRED_PAR++ ))
        ;;
      c )
        SCRAPS_FILES_BAM=$OPTARG
            NOSCRAPS=false
        ;;
      o )
        OUT_FOLD=$OPTARG
        ;;
      n )
        NTHREADS=$OPTARG
        ;;
      g )
        if [ "$OPTARG" == "a" ] || [ "$OPTARG" == "b" ]; then
            GROUPS_DESIRED=$OPTARG
        else
            echo -e "\nERROR: Invalid Groups Desired Option: -g $OPTARG" 1>&2
            print_help_menu
        fi
        ;;
      p )
        if [ "$OPTARG" == "b" ] || [ "$OPTARG" == "i" ] || [ "$OPTARG" == "a" ]; then
            PLOTS_DESIRED=$OPTARG
        else
            echo -e "\nERROR: Invalid Plots Desired Option: -p $OPTARG" 1>&2
            print_help_menu
        fi
        ;;
      v )
        VERBOSE=true
        ;;      
      k )
        KEEP=true
        ;;
      h )
        print_help_menu
        ;;
      \? )
        echo -e "\nERROR: Invalid Option: -$OPTARG" 1>&2
        print_help_menu
        ;;
      : )
        echo -e "\nERROR: No arguments provided" 1>&2
        print_help_menu
        ;;
    esac
done


#If required parameters are not provided throw an error and provide the help page
if (( REQUIRED_PAR != 1 )); then
    echo -e "\nERROR: The required parameters for this program is -u."
    echo "You are lacking these parameters.  See our help page below"
    print_help_menu
fi


#If in verbose mode, declare whether running with or without scraps
if [ $NOSCRAPS == true ]; then
    echo -e "\nRunning in NO_SCRAPS mode"
else
    echo -e "\nRunning in WITH_SCRAPS mode"
fi


#Go through scraps and subreads filename files and capture .bam filenames
SUBREADS_FILES_ARRAY_BAM=()
I=1
while read -r line; do
    SUBREADS_FILES_ARRAY_BAM[ $I ]="$line"
    (( I++ ))
done < "$SUBREADS_FILES_BAM"

if [ $NOSCRAPS == false ]; then
    SCRAPS_FILES_ARRAY_BAM=()
    I=1
    while read -r line; do
        SCRAPS_FILES_ARRAY_BAM[ $I ]="$line"
        (( I++ ))
    done < "$SCRAPS_FILES_BAM"
fi


#Go through BAM arrays and make arrays without the .bam at the end
SUBREADS_FILES_ARRAY_NOBAM=()
I=1
for BAM in "${SUBREADS_FILES_ARRAY_BAM[@]}"; do
    if [[ "$BAM" =~ (.*).bam ]]; then
        NOBAM=${BASH_REMATCH[1]}
        SUBREADS_FILES_ARRAY_NOBAM[ $I ]="$NOBAM"
    fi
    (( I++ ))     
done

if [ $NOSCRAPS == false ]; then
    SCRAPS_FILES_ARRAY_NOBAM=()
    I=1
    for BAM in "${SCRAPS_FILES_ARRAY_BAM[@]}"; do
        if [[ "$BAM" =~ (.*).bam ]]; then
            NOBAM=${BASH_REMATCH[1]}
            SCRAPS_FILES_ARRAY_NOBAM[ $I ]="$NOBAM"
        fi
        (( I++ ))
    done
fi


#Make an array of base filenames (before .scraps or .subreads)
FILES_BASE_ARRAY=()
I=1
for NOBAM in "${SUBREADS_FILES_ARRAY_NOBAM[@]}"; do
    if [[ "$NOBAM" =~ (.*).subreads ]]; then
        BASE=${BASH_REMATCH[1]}
        FILES_BASE_ARRAY[ $I ]="$BASE"
    fi
    (( I++ ))
done

if [ $NOSCRAPS == false ]; then
    FILES_BASE_ARRAY2=()
    I=1
    for NOBAM in "${SCRAPS_FILES_ARRAY_NOBAM[@]}"; do
        if [[ "$NOBAM" =~ (.*).scraps ]]; then
            BASE=${BASH_REMATCH[1]}
            FILES_BASE_ARRAY2[ $I ]="$BASE"
        fi
        (( I++ ))
    done
fi


#Ensure that the scraps and subreads files match
if [ $NOSCRAPS == false ]; then
    if [ "${FILES_BASE_ARRAY[*]}" != "${FILES_BASE_ARRAY2[*]}" ]; then
        echo -e "\nERROR: Your scraps and subreads files do not match"
        print_help_menu
    fi
fi

#Extract names that will contain coords necessary for calculating length
FAILED_EXTRACTION="ERROR: BAM data extraction failed!"
if [ $VERBOSE == true ]; then
    echo "Extracting data from .bam files"
fi

I=1
for BAM in "${SUBREADS_FILES_ARRAY_BAM[@]}"; do
    #Check that .bam files exist and are not empty
    if [ ! -s "$BAM" ]; then
        echo >&2 "the BAM file "$BAM" is empty or does not exist"
        print_help_menu
    fi

    NOBAM=${SUBREADS_FILES_ARRAY_NOBAM[I]}
    samtools view --threads "$NTHREADS" -O SAM "$BAM" | awk '{print $1}' > "$NOBAM.seqNames" || {
    echo >&2 "$FAILED_EXTRACTION"
    exit 1
    }
    (( I++ ))
done

if [ $NOSCRAPS == false ]; then
    I=1
    for BAM in "${SCRAPS_FILES_ARRAY_BAM[@]}"; do
        #Check that .bam files exist and are not empty
        if [ ! -s "$BAM" ]; then
            echo >&2 "the BAM file "$BAM" is empty or does not exist"
            print_help_menu
        fi

        NOBAM=${SCRAPS_FILES_ARRAY_NOBAM[I]}
        samtools view --threads "$NTHREADS" -O SAM "$BAM" | awk '{print $1,"\t",$21,"\t",$22}' > "$NOBAM.seqNamesPlus" || {
        echo >&2 "$FAILED_EXTRACTION"
        exit 1
        }
        (( I++ ))
    done
fi

if [ $VERBOSE == true ]; then
    echo "Data extraction was sucessful"
    echo "Beginning calculation of read length statistics"
fi


#Calculate read length stats (sum, mean, median, N50, L50)
FAILED_RLSTATS="ERROR: Calculation of read length statistics failed!"
FILES_FOR_R=""
LENGTHS_FOR_R=""
I=1
for SUBREADS_NOBAM in "${SUBREADS_FILES_ARRAY_NOBAM[@]}"; do
    SCRAPS_NOBAM=${SCRAPS_FILES_ARRAY_NOBAM[I]}
    BASE=${FILES_BASE_ARRAY[I]}
 
    if [ "$PY_VER" == 2 ]; then
        if [ $NOSCRAPS == true ]; then
            python generateReadLenStats_noScraps_py2.py "$SUBREADS_NOBAM.seqNames" "$BASE.SMRTcellStats_noScraps.txt" "$BASE.readLens.sub.txt" "$BASE.readLens.longSub.txt" || {
            echo >&2 "$FAILED_RLSTATS"
            exit 1
            }
        else
            if [ "$GROUPS_DESIRED" == "a" ]; then
                python generateReadLenStats_wScraps_py2.py "$SCRAPS_NOBAM.seqNamesPlus" "$SUBREADS_NOBAM.seqNames" "$BASE.SMRTcellStats_wScrapsA.txt" "$BASE.readLens.sub.txt" "$BASE.readLens.clr.txt" "$BASE.readLens.subedClr.txt" "$BASE.readLens.longSub.txt" "$BASE.clrStats.txt" "$GROUPS_DESIRED" || {
                echo >&2 "$FAILED_RLSTATS"
                exit 1
                }
            elif [ "$GROUPS_DESIRED" == "b" ]; then
                python generateReadLenStats_wScraps_py2.py "$SCRAPS_NOBAM.seqNamesPlus" "$SUBREADS_NOBAM.seqNames" "$BASE.SMRTcellStats_wScrapsB.txt" "$BASE.readLens.sub.txt" "$BASE.readLens.clr.txt" "$BASE.readLens.subedClr.txt" "$BASE.readLens.longSub.txt" "$BASE.clrStats.txt" "$GROUPS_DESIRED" || {
                echo >&2 "$FAILED_RLSTATS"
                exit 1
                }
            fi
        fi

        #Set an array of args (files and line numbers) to pass to R.
        make_args_for_R_array

    elif [ "$PY_VER" == 3 ]; then
        if [ $NOSCRAPS == true ]; then
            python generateReadLenStats_noScraps_py3.py "$SUBREADS_NOBAM.seqNames" "$BASE.SMRTcellStats_noScraps.txt" "$BASE.readLens.sub.txt" "$BASE.readLens.longSub.txt" || {
            echo >&2 "$FAILED_RLSTATS"
            exit 1
            }
        else
            if [ "$GROUPS_DESIRED" == "a" ]; then
                python generateReadLenStats_wScraps_py3.py "$SCRAPS_NOBAM.seqNamesPlus" "$SUBREADS_NOBAM.seqNames" "$BASE.SMRTcellStats_wScrapsA.txt" "$BASE.readLens.sub.txt" "$BASE.readLens.clr.txt" "$BASE.readLens.subedClr.txt" "$BASE.readLens.longSub.txt" "$BASE.clrStats.txt" "$GROUPS_DESIRED" || {
                echo >&2 "$FAILED_RLSTATS"
                exit 1
                }
            elif [ "$GROUPS_DESIRED" == "b" ]; then
                python generateReadLenStats_wScraps_py3.py "$SCRAPS_NOBAM.seqNamesPlus" "$SUBREADS_NOBAM.seqNames" "$BASE.SMRTcellStats_wScrapsB.txt" "$BASE.readLens.sub.txt" "$BASE.readLens.clr.txt" "$BASE.readLens.subedClr.txt" "$BASE.readLens.longSub.txt" "$BASE.clrStats.txt" "$GROUPS_DESIRED" || {
                echo >&2 "$FAILED_RLSTATS"
                exit 1
                }
            fi
        fi

        #Set an array of args (files and line numbers) to pass to R.
        make_args_for_R_array

    else
        echo -e "\nERROR: This program requires Python 2 or Python 3.  You seem to" 
        echo "be working with a different version."
        echo >&2 "$FAILED_RLSTATS"
        exit 1
    fi

    (( I++ ))
done

if [ $VERBOSE == true ]; then
    echo "Read length statistic calculations complete"
    echo "Creating plots"
fi

#Make plots related to read length stats in R
if [ ! -d "$OUT_FOLD" ]; then
    mkdir "$OUT_FOLD"
fi

if [ $NOSCRAPS == false ]; then
    Rscript plotForSequelQC_wScraps.R ${FILES_FOR_R::-1} ${LENGTHS_FOR_R::-1} "$GROUPS_DESIRED" "$PLOTS_DESIRED" "$VERBOSE" "$OUT_FOLD" #the '::-1' is to remove the comma at the end
else
    Rscript plotForSequelQC_noScraps.R ${FILES_FOR_R::-1} ${LENGTHS_FOR_R::-1} "$PLOTS_DESIRED" "$VERBOSE" "$OUT_FOLD" #the '::-1' is to remove the comma at the end
fi

if [ $VERBOSE == true ]; then
    echo "Plot creation complete"
fi


#Cleanup intermediate files
if [ $KEEP == false ]; then
    if [ $VERBOSE == true ]; then
        echo "Deleting intermediate files"
    fi
    I=1
    for SUBREADS_NOBAM in "${SUBREADS_FILES_ARRAY_NOBAM[@]}"; do
        if [ $NOSCRAPS == false ]; then
            SCRAPS_NOBAM=${SCRAPS_FILES_ARRAY_NOBAM[I]}
        fi
        BASE=${FILES_BASE_ARRAY[I]} 

        rm "$SUBREADS_NOBAM.seqNames"
        rm "$BASE.readLens.sub.txt"
        rm "$BASE.readLens.longSub.txt"
        rm "$BASE.SMRTcellStats_noScraps.txt"

        if [ $NOSCRAPS == false ]; then
            rm "$SCRAPS_NOBAM.seqNamesPlus"
            rm "$BASE.readLens.clr.txt"
            rm "$BASE.readLens.subedClr.txt"
            rm "$BASE.clrStats.txt"
            if [ "$GROUPS_DESIRED" == "a" ]; then
                rm "$BASE.SMRTcellStats_wScrapsA.txt"
            elif [ "$GROUPS_DESIRED" == "b" ]; then
                rm "$BASE.SMRTcellStats_wScrapsB.txt"
            fi
        fi

        (( I++ ))
    done
fi

if [ $VERBOSE == true ]; then
    echo "SequelQC has finished successfully!"
fi




