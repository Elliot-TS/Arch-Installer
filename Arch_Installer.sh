#!/bin/bash

##############################################
# Save Progress
##############################################
progress_file_name="Arch_Installer_Progress.txt"
declare -A PROGRESS_ARRAY
PROGRESS_ARRAY=(
    [verify_boot]=0
)

# Save the current progress
save()
{
    declare -p PROGRESS_ARRAY > $progress_file_name
    echo $(sed -e "s/-A/-Ag/g" $progress_file_name) > $progress_file_name
}

load_progress()
{
    eval $(cat "./$progress_file_name")
}

init_progress_file()
{
    if [ ! -e "./$progress_file_name" ]
    then
        save
    fi
}


##############################################
# Main
##############################################
init_progress_file
load_progress
declare -p PROGRESS_ARRAY
echo ${PROGRESS_ARRAY[verify_boot]}
        
