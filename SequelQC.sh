#!/bin/bash




##### Define functions #####
#Print the help menu
function print_help_menu() {
    cat <<helpChunk
    
    ###########################################################################
                  This is the help menu for SequelQC version 0.9.0
    ###########################################################################
    Dependencies for this program are samtools, Python, and R
    For this help menu use the parameter -h or no parameters
    Required parameters are -u and -c

    Notes: a subedZMW is a ZMW containing at least one subread

    All parameters:
    -u : A file listing the names of subreads .bam sequence files
    -c : A file listing the names of scraps .bam sequence files
    -n : The number of threads to use for extracting information from .bam 
         files for each .bam file. Default is '1'
    -v : A verbose option for those who want updates as the program progresses
    -k : Keep intermediate files (these are removed by default)
    -g : Groups desired. Options: 'a' for all (ZMWs, subedZmws, 
         subreads, and longest subreads), and 'b' for basic (subedZmws and 
         subreads).  Default is 'a'
    -p : Plots desired.  Options: 'b' for basic (N50 barplot, summary data
         table, and total bases barplot), 'i' for intermediate (N50 barplot, 
         summary data table, total bases barplot, ZOR plot, PSR plot, boxplot
         of subread read lengths with N50, boxplot of subedZMW read lengths 
         with N50), and 'a' for all (N50 barplot, L50 barplot, summary data 
         table, read length histograms, total bases barplot, ZOR plot, PSR plot,
         histograms of subreads per subedZMW, histograms of adapters per ZMW, 
         Boxplot of subread read lengths with N50, boxplot of subedZMW read 
         lengths with N50).  Default is 'i'
    -h : opens this help menu
helpChunk
    exit 1
}

#Set an array of files and line numbers to pass to R .  Arg 1=ARGS_FOR_R Arg 2 is I
function make_args_for_R_array() {
    if [ "$GROUPS_DESIRED" == "a" ]; then
        FILES_FOR_R+="$BASE.SMRTcellStats.txt,"
        FILES_FOR_R+="$BASE.readLens.sub.txt,"
        FILES_FOR_R+="$BASE.readLens.zmw.txt,"
        FILES_FOR_R+="$BASE.readLens.subedZmw.txt,"
        FILES_FOR_R+="$BASE.readLens.longSub.txt,"
        FILES_FOR_R+="$BASE.zmwStats.txt,"
        LENGTHS_FOR_R+="$(wc -l "$BASE.SMRTcellStats.txt" | cut -f 1 -d ' '),"
        LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.sub.txt" | cut -f 1 -d ' '),"
        LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.zmw.txt" | cut -f 1 -d ' '),"
        LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.subedZmw.txt" | cut -f 1 -d ' '),"
        LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.longSub.txt" | cut -f 1 -d ' '),"
        LENGTHS_FOR_R+="$(wc -l "$BASE.zmwStats.txt" | cut -f 1 -d ' '),"

    elif [ "$GROUPS_DESIRED" == "b"   ]; then
        FILES_FOR_R+="$BASE.SMRTcellStats.txt,"
        FILES_FOR_R+="$BASE.readLens.sub.txt,"
        FILES_FOR_R+="$BASE.readLens.subedZmw.txt,"
        FILES_FOR_R+="$BASE.readLens.longSub.txt,"
        FILES_FOR_R+="$BASE.zmwStats.txt,"
        LENGTHS_FOR_R+="$(wc -l "$BASE.SMRTcellStats.txt" | cut -f 1 -d ' '),"
        LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.sub.txt" | cut -f 1 -d ' '),"
        LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.subedZmw.txt" | cut -f 1 -d ' '),"
        LENGTHS_FOR_R+="$(wc -l "$BASE.readLens.longSub.txt" | cut -f 1 -d ' '),"
        LENGTHS_FOR_R+="$(wc -l "$BASE.zmwStats.txt" | cut -f 1 -d ' '),"
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


#Go through input and assign input arguments to variables
while getopts ":u:c:n:g:p:vkh" opt; do
    case ${opt} in 
      u )
        SUBREADS_FILES_BAM=$OPTARG
        (( REQUIRED_PAR++ ))
        ;;
      c )
        SCRAPS_FILES_BAM=$OPTARG
        (( REQUIRED_PAR++ ))
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
if (( REQUIRED_PAR != 2 )); then
    echo -e "\nERROR: The required parameters for this program are -u and -c."
    echo "You are lacking these parameters.  See our help page below"
    print_help_menu
fi


#Go through scraps and subreads filename files and capture .bam filenames
SUBREADS_FILES_ARRAY_BAM=()
I=1
while read -r line; do
    SUBREADS_FILES_ARRAY_BAM[ $I ]="$line"
    (( I++ ))
done < "$SUBREADS_FILES_BAM"

SCRAPS_FILES_ARRAY_BAM=()
I=1
while read -r line; do
    SCRAPS_FILES_ARRAY_BAM[ $I ]="$line"
    (( I++ ))
done < "$SCRAPS_FILES_BAM"


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

SCRAPS_FILES_ARRAY_NOBAM=()
I=1
for BAM in "${SCRAPS_FILES_ARRAY_BAM[@]}"; do
    if [[ "$BAM" =~ (.*).bam ]]; then
        NOBAM=${BASH_REMATCH[1]}
        SCRAPS_FILES_ARRAY_NOBAM[ $I ]="$NOBAM"
    fi
    (( I++ ))
done


#Make an array of base filenames (before .scraps or .subreads)
FILES_BASE_ARRAY=()
I=1
for NOBAM in "${SCRAPS_FILES_ARRAY_NOBAM[@]}"; do
    if [[ "$NOBAM" =~ (.*).scraps ]]; then
        BASE=${BASH_REMATCH[1]}
        FILES_BASE_ARRAY[ $I ]="$BASE"
    fi
    (( I++ ))
done

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

if [ $VERBOSE == true ]; then
    echo "Data extraction was sucessful"
    echo "Beginning calculation of read length statistics"
fi


#Calculate read length stats (sum, mean, median, N50, L50)
FAILED_RLSTATS="ERROR: Calculation of read length statistics failed!"
FILES_FOR_R=""
LENGTHS_FOR_R=""
I=1
for SCRAPS_NOBAM in "${SCRAPS_FILES_ARRAY_NOBAM[@]}"; do
    SUBREADS_NOBAM=${SUBREADS_FILES_ARRAY_NOBAM[I]}
    BASE=${FILES_BASE_ARRAY[I]}
  
    if [ "$PY_VER" == 2 ]; then
        python generateReadLenStats.py "$SCRAPS_NOBAM.seqNamesPlus" "$SUBREADS_NOBAM.seqNames" "$BASE.SMRTcellStats.txt" "$BASE.readLens.sub.txt" "$BASE.readLens.zmw.txt" "$BASE.readLens.subedZmw.txt" "$BASE.readLens.longSub.txt" "$BASE.zmwStats.txt" "$GROUPS_DESIRED" || {
        echo >&2 "$FAILED_RLSTATS"
        exit 1
        }

        #Set an array of args (files and line numbers) to pass to R.
        make_args_for_R_array

    elif [ "$PY_VER" == 3 ]; then
        python generateReadLenStats_py3.py "$SCRAPS_NOBAM.seqNamesPlus" "$SUBREADS_NOBAM.seqNames" "$BASE.SMRTcellStats.txt" "$BASE.readLens.sub.txt" "$BASE.readLens.zmw.txt" "$BASE.readLens.subedZmw.txt" "$BASE.readLens.longSub.txt" "$BASE.zmwStats.txt" "$GROUPS_DESIRED" || {
        echo >&2 "$FAILED_RLSTATS"
        exit 1
        }

        #Set an array of args (files and line numbers) to pass to R.
        make_args_for_R_array

    else
        echo "ERROR: This program requires Python 2 or Python 3.  You seem to" 
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
Rscript plotForSequelQC.R ${FILES_FOR_R::-1} ${LENGTHS_FOR_R::-1} "$GROUPS_DESIRED" "$PLOTS_DESIRED" "$VERBOSE"  #the '::-1' is to remove the comma at the end

if [ $VERBOSE == true ]; then
    echo "Plot creation complete"
fi


#Cleanup intermediate files
if [ $KEEP == false ]; then
    if [ $VERBOSE == true ]; then
        echo "Deleting intermediate files"
    fi
    I=1
    for SCRAPS_NOBAM in "${SCRAPS_FILES_ARRAY_NOBAM[@]}"; do
        SUBREADS_NOBAM=${SUBREADS_FILES_ARRAY_NOBAM[I]}
        BASE=${FILES_BASE_ARRAY[I]} 

        rm "$SCRAPS_NOBAM.seqNamesPlus"
        rm "$SUBREADS_NOBAM.seqNames"
        rm "$BASE.readLens.sub.txt"
        rm "$BASE.readLens.zmw.txt"
        rm "$BASE.readLens.longSub.txt"
        rm "$BASE.readLens.subedZmw.txt"
        rm "$BASE.SMRTcellStats.txt"
        rm "$BASE.zmwStats.txt"

        (( I++ ))
    done
fi

if [ $VERBOSE == true ]; then
    echo "SequelQC has finished successfully!"
fi




