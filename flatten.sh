#description: moves specific file types from a file hierarchy (such as google photos takeout) into a single, specified, folder

#do not run script from same path as destination directory
#revert file must be in same directory flattened

#prompt: mode: check/move/revert

#made to move pictures from a google photos takeout to a single folder

#getopts

fileTypes=("*.jpg" "*.jpeg" "*.mov" "*.png" "*.heic" "*.cr2" "*.tif" "*.psd" "*.dng" "*.xmp" "*.mp4" "*.3gp" "*.gif") 

sourceDir="C:\Users\erick\OneDrive\Pictures\Photography\Google Photos\SORT"
#sourceDir="C:/Users/erick/OneDrive/Pictures/Photography" #/Google Photos"
destDir="C:/Users/erick/OneDrive/Pictures/Photography/Google Photos 2"


#new
if [ $# -eq 0 ]; then #if no arguments, prompt for
    read -p "mode (flat/check/revert or help): " active_mode
else
    active_mode=$1;
fi

counter=0
subcounter=0

#this makes 'for fileList in "($find...)"' work by changing split from ' ' (space) to '\n'
#... or was it spaces in variable file names? idr
IFS=$'\n'



list=""

echo

#mode
if [ "$active_mode" = flat ]; then

    #if $# = 3 arguments, no need to prompt 1=active_mode=flat, 2=source, 3=dest

    #if directories not provided in argument pass
    #   read -p "enter full source directory: " sourceDir
    #   read -p "enter full destination directory: " destDir
    #else #default
    #fi

    if [ ! -d "$destDir" ]; then #if directory does not exist
        mkdir "$destDir"
        if [ $? -eq 0 ]; then
            echo "created directory"
        else
            echo "failed to create directory"
            exit 1
        fi
    else
        echo "destination directory already exists"
    fi

    #reversal log
    random=$(date +%m%d%y%H%M%S)
    ident=$(basename $destDir)
    reversalLog="$destDir/reversal-Log-$ident-$random.txt"
    
    touch $reversalLog #create log

    if [ $? -eq 0 ]; then
        echo "created log at $reversalLog"
    else
        echo "failed to create log"
        exit 1
    fi

    echo "active_mode is set flat... moving files"
    echo
    echo "source directory: $sourceDir"
    echo "destination directory $destDir"
    echo

#if in test mode, just look at find files
elif [ "$active_mode" = check ]; then
    echo "activeMode is set check... not moving files"
    echo
    echo "looking for files in $sourceDir"
    echo

elif [ "$active_mode" = revert ]; then #revert code

    echo "activeMode is set to revert... reversing moves"

    #if $# = 2 arguments, no need to prompt. $1=active_mode=revert, $2=revert file

    if [ $# -eq 1 ]; then
        read -p "enter revert file: " revertTo
    elif [ $# -eq 2 ]; then
        revertTo=$2 #second arg is revert file
    else 
        echo "invalid arguments"
        exit 1
    fi

    flatDir=$(dirname $revertTo) #get the directory of the revert file

    revertCount=0

    while read -r line; do #read file paths to move file

        if [ -z $line ]; then #check for empty line
            continue
        fi

        fName=$(basename "$line")
        fPath=$(dirname "$line")

        mv -n -v "$flatDir/$fName" "$fPath" #don't overwrite

        revertCount=$((revertCount+1))

    done < $revertTo #feed file to loop

    echo "reversed $revertCount files"

    echo
    echo "remove used log file?"
    rm -i $2

    exit 0

else
    echo "invalid active_mode"
    exit 1
fi


#sort through files
for thisType in ${fileTypes[@]}; do
    echo "looking for $thisType files..."
    for fileList in "$(find "$sourceDir" -mindepth 1 -iname $thisType)"; do
        for file in $fileList; do

            counter=$((counter+1)) #counter for total number of files of type(s) found
            subcounter=$((subcounter+1)) #counter for current number of type found

            if [ "$active_mode" = flat ]; then
                list=$list$file$'\n' #add file to list string of files mmoved
                mv -n -v "$file" "$destDir"
            fi
            
        done

        if [ "$subcounter" -eq 0 ]; then
            echo "none"
        else
            echo "$subcounter files found"
        fi

        subcounter=0
    done
done

if [ "$active_mode" = flat ]; then  
    echo "$list" >> "$reversalLog"
fi

echo
echo "total files found: $counter"
echo

if [ "$active_mode" = flat ]; then  

    echo "Run this to revert: "
    echo "./flatten.sh revert \"$reversalLog\""

fi