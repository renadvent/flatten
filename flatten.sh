#description: moves specific file types from a file hierarchy (such as google photos takeout) into a single, specified, folder

#functionality to be added to deal with duplicates
#   --move duplicate items to a separate folder? or rename?
#       --check if file name already exists in destDir, and if it does, create a new folder named "duplicates" and move subsequent there

#file types that will be moved
fileTypes=("*.jpg" "*.jpeg" "*.mov" "*.png" "*.heic" "*.cr2" "*.tif" "*.psd" "*.dng" "*.xmp" "*.mp4" "*.3gp" "*.gif") 

if [ $# -eq 0 ]; then #if no arguments, prompt for mode
    read -p "mode (flat/check/revert/test or help): " active_mode
else
    active_mode=$1;
fi
echo

#this makes 'for fileList in "($find...)"' work by changing split from ' ' (space) to '\n'
#... or was it spaces in variable file names? idr

#flat mode
if [ "$active_mode" = flat ]; then

    #read arguments/set source and target directories
    if [ $# = 1 ]; then
       read -r -p "enter full source directory: " sourceDir
       read -r -p "enter full destination directory: " destDir
    elif [ $# = 2 ]; then
        sourceDir=$2
        read -r -p "enter full destination directory: " destDir
    elif [ $# = 3 ]; then  
        sourceDir=$1
        destDir=$2
    else
        echo "invalid number of flat mode arguments"
        echo "format: flat (optional)source_Directory (optional)destination_Directory"
        exit 1
    fi

    #create source directory if necessary
    if [ ! -d "$destDir" ]; then #if directory does not exist
        mkdir "$destDir"
        if [ $? -eq 0 ]; then #check if made successfully
            echo "created directory"
        else
            echo "failed to create directory"
            exit 1
        fi
    else
        echo "destination directory already exists"
    fi

    #set reversal log name
    random=$(date +%m%d%y%H%M%S)
    ident=$(basename $destDir)
    reversalLog="$destDir/reversal-Log-$ident-$random.txt"

    #create reversal log
    touch $reversalLog #create log
    if [ $? -eq 0 ]; then
        echo "created log at $reversalLog"
    else
        echo "failed to create log"
        exit 1
    fi

    #printing info to terminal
    echo "active_mode is set flat... moving files"
    echo
    echo "source directory: $sourceDir"
    echo "destination directory $destDir"
    echo

#check mode
elif [ "$active_mode" = check ]; then

    if [ $# = 1 ]; then
        read -r -p "enter source directory: " sourceDir
    elif [ $# = 2 ]; then
        sourceDir=$2 #dropping slashes....
    else
        echo "invalid check arguments"
        exit 1
    fi

    echo "activeMode is set check... not moving files"
    echo
    echo "looking for files in $sourceDir"
    echo

#revert mode
elif [ "$active_mode" = revert ]; then #revert code

    #read arguments/get revert file
    if [ $# -eq 1 ]; then
        read -r -p "enter revert file: " revertTo
    elif [ $# -eq 2 ]; then
        revertTo=$2 #second arg is revert file
    else 
        echo "invalid number of arguments"
        exit 1
    fi

    echo "activeMode is set to revert... reversing moves"
    revertCount=0

    #get the directory of the revert file to use as folder to move files from
    flatDir=$(dirname $revertTo) 

    #read the reversal log
    while read -r line; do #read file paths to move file

        #check for empty line
        if [ -z $line ]; then 
            continue
        fi

        #get the file name and, separately, the original path
        #so we can move it back to original folder
        fName=$(basename "$line")
        fPath=$(dirname "$line")

        #mmove and don't overwrite
        mv -n -v "$flatDir/$fName" "$fPath" 

        #keeps track of # of files moved
        revertCount=$((revertCount+1))

    done < $revertTo #feed reversal log file to loop

    #print info to terminal, and ask to delete used reversal log
    echo "reversed $revertCount files"
    echo
    echo "remove used log file?"
    rm -i $2

    #exit script after reversal
    exit 0

elif [ "$active_mode" = test ]; then

sourceDir="C:\Users\erick\OneDrive\Pictures\Photography\Google Photos\SORT"
#sourceDir="C:/Users/erick/OneDrive/Pictures/Photography" #/Google Photos"
destDir="C:/Users/erick/OneDrive/Pictures/Photography/Google Photos 2"

else
    echo "invalid active_mode"
    exit 1
fi

counter=0
subcounter=0 #to drop "unary operator expected" warning

IFS=$'\n' #required so space doesn't break file names in variables for "for" loops

#sort through files
for thisType in ${fileTypes[@]}; do #loop file types
    echo "looking for $thisType files..."
    for fileList in "$(find "$sourceDir" -mindepth 1 -iname $thisType)"; do #IFS set fixes this
        #echo $fileList
        for file in $fileList; do

            echo $file

            counter=$((counter+1)) #counter for total number of files of type(s) found
            subcounter=$((subcounter+1)) #counter for current number of type found

            if [ "$active_mode" = flat ]; then
                list=$list$file$'\n' #add file to list string of files mmoved
                mv -n -v "$file" "$destDir"
            fi
            
        done

        #check how many files found of current type
        if [ $subcounter = 0 ]; then
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

    echo "Run this command to revert: "
    echo "./flatten.sh revert \"$reversalLog\""

fi