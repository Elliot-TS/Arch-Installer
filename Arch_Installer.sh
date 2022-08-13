#!/bin/bash

##############################################
# Save Progress
##############################################
progress_file_name="Arch_Installer_Progress.txt"
declare -A PROGRESS_ARRAY
PROGRESS_ARRAY=(
    [verify_boot_mode]=0
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

# Verify Boot Mode
verify_boot_mode()
{
    if [ $ABORT == 0 ]
    then
        echo "-------------------"
        echo "Verifying Boot Mode"
        echo "------ -------------"

        if [ ${PROGRESS_ARRAY[verify_boot_mode]} == 0 ]
        then
            # Check if the computer uses UEFI (no error) or BIOS (error)
            ls /sys/firmware/efi/efivars
            if [ $? == 0 ]
            then
                echo "---- Boot mode confirmed to be UEFI"
                PROGRESS_ARRAY[verify_boot_mode]=1
            else
                echo "---- ERROR: BIOS is currently unsupported.  Must use UEFI."
                PROGRESS_ARRAY[verify_boot_mode]=1
                ABORT=1
            fi

        else
            echo "Already Done"
        fi
    fi
    save
}

# Configure Clock
configure_clock()
{
    if [ $ABORT == 0 ]
    then
        if [ ${PROGRESS_ARRAY[configure_clock]} == 0 ]
        then
            echo "-----------------"
            echo "Configuring Clock"
            echo "-----------------"

            echo "Setting NTP to true"
            timedatectl set-ntp true

            PROGRESS_ARRAY[configure_clock]=1
        fi
    fi
    save
}

load_luks_modules()
{
    if [ $ABORT == 0 ]
    then
        if [ ${PROGRESS_ARRAY[load_luks_modules]} == 0 ]
        then
            echo "-----------------------------"
            echo "Preparing for LUKS encryption"
            echo "-----------------------------"
            echo "Loading dm-crypt and dm-mod kernel modules"
            modprobe dm-crypt
            modprobe dm-mod

            PROGRESS_ARRAY[load_luks_modules]=1
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
#configure_clock
#load_luks_modules
        
