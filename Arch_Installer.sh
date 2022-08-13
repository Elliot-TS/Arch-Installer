#!/bin/bash

##############################################
# Save Progress
##############################################
progress_file_name="Arch_Installer_Progress.txt"
declare -A PROGRESS_ARRAY
PROGRESS_ARRAY=(
    [verify_boot_mode]=0
    [configure_clock]=0
    [load_luks_modules]=0
)
ABORT=0

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
# Installation
# Initial installation steps were adapted
# from https://medium.com/hacker-toolbelt/arch-install-with-full-disk-encryption-6192e9635281
##############################################

skeleton_function()
{
    if [ $ABORT == 0 ]
    then
        echo "-------------"
        echo "Title"
        echo "-------------"

        if [ ${PROGRESS_ARRAY[skeleton_function]} == 0 ]
        then
            # DO STUFF
            echo "do stuff"

            # Catch error
            if [ $? -ne 0 ]
            then 
                echo "--- ERROR: Message. ---"
                ABORT=1
            else
                echo "--- Success ---"
            fi
            # Save progress
            PROGRESS_ARRAY[skeleton_function]=1
        else
            echo "Already done"
        fi
    fi
    save
}

# Verify Boot Mode
verify_boot_mode()
{
    if [ $ABORT == 0 ]
    then
        echo "-------------------"
        echo "Verifying Boot Mode"
        echo "-------------------"

        if [ ${PROGRESS_ARRAY[verify_boot_mode]} == 0 ]
        then
            # Verify that boot mode is UEFI
            ls /sys/firmware/efi/efivars

            # Catch error
            if [ $? -ne 0 ]
            then 
                echo "--- ERROR: Boot Mode is BIOS.  Must be UEFI.  Aborting. ---"
                ABORT=1
            else
                echo "--- Boot Mode is UEFI ---"
            fi

            # Save progress
            PROGRESS_ARRAY[verify_boot_mode]=1
        else
            echo "Already done"
        fi
    fi
    save
}

# Configure Clock
configure_clock()
{
    if [ $ABORT == 0 ]
    then
        echo "----------------"
        echo "Configure Clock"
        echo "----------------"

        if [ ${PROGRESS_ARRAY[configure_clock]} == 0 ]
        then
            # DO STUFF
            echo "--- Setting NTP to True ---"
            timedatectl set-ntp true

            # Catch error
            # TODO: if there are multiple configurations later, create a separate error for each command
            if [ $? -ne 0 ]
            then 
                echo "--- ERROR: Could not configure clock. ---"
                ABORT=1
            else
                echo "--- Finished configuring clock ---"
            fi
            # Save progress
            PROGRESS_ARRAY[configure_clock]=1
        else
            echo "Already done"
        fi
    fi
    save
}

load_luks_modules()
{
    if [ $ABORT == 0 ]
    then
        echo "---------------------------"
        echo "Prepare for LUKS encryption"
        echo "---------------------------"

        if [ ${PROGRESS_ARRAY[load_luks_modules]} == 0 ]
        then
            # Load dm-crypt kernel modules
            modprobe dm-crypt

            # Catch error
            if [ $? -ne 0 ]
            then 
                echo "--- ERROR: Could not load dm-crypt. ---"
                ABORT=1
            fi

            # Load dm-mod kernel module
            modprobe dm-mod

            # Catch error
            if [ $? -ne 0 ]
            then 
                echo "--- ERROR: Could not load dm-mod. ---"
                ABORT=1
            fi

            # If neither failed
            if [ $ABORT == 0 ] 
                echo "--- Success ---"
            fi
            # Save progress
            PROGRESS_ARRAY[load_luks_modules]=1
        else
            echo "Already done"
        fi
    fi
    save
}

##############################################
# Main
##############################################
init_progress_file
load_progress
declare -p PROGRESS_ARRAY

verify_boot_mode
configure_clock
load_luks_modules
        
