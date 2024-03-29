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
    [get_disk_name]=0
    [partition_drive]=0
    [encrypt_root_partition]=0
    [format_partitions]=0
    [create_swap_file]=0
    [set_up_arch]=0
    [configure_locale]=0
    [configure_network]=0
    [prepare_boot_loader]=0
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
        echo -e "-------------"
        echo -e "Title"
        echo -e "-------------\n"

        if [ ${PROGRESS_ARRAY[skeleton_function]} == 0 ]
        then
            # DO STUFF
            echo "do stuff"

            # Catch error
            if [ $? -ne 0 ]
            then 
                echo -e "--- ERROR: Message. ---\n"
                ABORT=1
            else
                echo -e "--- Success ---\n"
            fi
            # Save progress
            PROGRESS_ARRAY[skeleton_function]=1
        else
            echo -e "Already done\n"
        fi
    fi
    save
}

# Verify Boot Mode
verify_boot_mode()
{
    if [ $ABORT == 0 ]
    then
        echo -e "-------------------"
        echo -e "Verifying Boot Mode"
        echo -e "-------------------\n"

        if [ ${PROGRESS_ARRAY[verify_boot_mode]} == 0 ]
        then
            # Verify that boot mode is UEFI
            ls /sys/firmware/efi/efivars

            # Catch error
            if [ $? -ne 0 ]
            then 
                echo -e "--- ERROR: Boot Mode is BIOS.  Must be UEFI.  Aborting. ---\n"
                ABORT=1
            else
                echo -e "--- Boot Mode is UEFI ---\n"
            fi

            # Save progress
            PROGRESS_ARRAY[verify_boot_mode]=1
        else
            echo -e "Already done\n"
        fi
    fi
    save
}

# Configure Clock
configure_clock()
{
    if [ $ABORT == 0 ]
    then
        echo -e "----------------"
        echo -e "Configure Clock"
        echo -e "----------------\n"

        if [ ${PROGRESS_ARRAY[configure_clock]} == 0 ]
        then
            # Set NTP to true
            echo -e "--- Setting NTP to True ---\n"
            if [[ $(timedatectl show | grep "NTP=yes") != "" ]]
            then
                echo -e "NTP already set to true\n"
            else
                timedatectl set-ntp true
            fi

            # Catch error
            # TODO: if there are multiple configurations later, create a separate error for each command
            if [ $? -ne 0 ]
            then 
                echo -e "--- ERROR: Could not configure clock. ---\n"
                ABORT=1
            else
                echo -e "--- Finished configuring clock ---\n"
            fi
            # Save progress
            PROGRESS_ARRAY[configure_clock]=1
        else
            echo -e "Already done\n"
        fi
    fi
    save
}

load_luks_modules()
{
    if [ $ABORT == 0 ]
    then
        echo -e "---------------------------"
        echo -e "Prepare for LUKS encryption"
        echo -e "---------------------------\n"

        if [ ${PROGRESS_ARRAY[load_luks_modules]} == 0 ]
        then
            # Load dm-crypt kernel modules
            modprobe dm-crypt

            # Catch error
            if [ $? -ne 0 ]
            then 
                echo -e "--- ERROR: Could not load dm-crypt. ---\n"
                ABORT=1
            fi

            # Load dm-mod kernel module
            modprobe dm-mod

            # Catch error
            if [ $? -ne 0 ]
            then 
                echo -e "--- ERROR: Could not load dm-mod. ---\n"
                ABORT=1
            fi

            # If neither failed
            if [ $ABORT == 0 ] 
            then
                echo -e "--- Success ---\n"
            fi
            # Save progress
            PROGRESS_ARRAY[load_luks_modules]=1
        else
            echo -e "Already done\n"
        fi
    fi
    save
}

# Get Disk Name
DISK_NAME=sdn
get_disk_name()
{
    if [ $ABORT == 0 ]
    then
        echo -e "-------------"
        echo -e "Get Disk Name"
        echo -e "-------------\n"


        if [ ${PROGRESS_ARRAY[get_disk_name]} == 0 ]
        then
            # Get disk name 
            if [[ $(lsblk | grep nvme0n1) != "" ]]
            then
                echo -e "--- Disk name is nvme0n1 ---\n"
                DISK_NAME=nvme0n1
            elif [[ $(lsblk | grep mmcbkl0) != "" ]]
            then
                echo -e "--- Disk name is mmcblk0 ---\n"
                echo -e "--- ERROR: mmcblk0 is not currently supported.  Aborting ---\n"
                ABORT=1
                DISK_NAME=mmcblk0
            elif [[ $(lsblk | grep sda) != "" ]]
            then
                echo -e "--- Disk name is sda ---\n"
                DISK_NAME=sda
            else
                echo -e "--- ERROR: Disk name not found. ---\n"
                ABORT=1
            fi

            # Save progress
            PROGRESS_ARRAY[get_disk_name]=1
        else
            echo -e "Already done\n"
        fi
    fi
    save
}

partition_drive()
{
    if [ $ABORT == 0 ]
    then
        echo -e "-------------------"
        echo -e "Partitioning Drive"
        echo -e "-------------------\n"

        if [[ ${PROGRESS_ARRAY[partition_drive]} == 0 ]]
        then
            # Save the current partition table
            echo -e "--- Saving partition table to ./partition.dump ---"
            echo -e "--- (to restore the partition table, run: sfdisk /dev/$DISK_NAME < partition.dump ---\n"
            sfdisk -d /dev/$DISK_NAME > partition.dump

            # Check if the command failed (i.e. there was no partition table)
            if [ $(echo $?) -ne 0 ]
            then
                # First is a 256MB UEFI parttion
                # Second is a 512MB partition for boot
                # Third is the root partition
                echo -e ",256M,U\n,512M,L\n,,+\n" | sfdisk /dev/$DISK_NAME
            else
                # TODO: Potentially ask if the user wants to override the partition table
                # since it was already saved
                echo -e "--- ERROR: Disk is already partitioned.  Aborting. ---\n"
                ABORT=1
            fi

            # Save progress
            PROGRESS_ARRAY[partition_drive]=1
        else
            echo -e "Already done\n"
        fi
    fi
    save
}

# Encrypt Root Partition
encrypt_root_partition()
{
    if [ $ABORT == 0 ]
    then
        echo -e "-------------------------"
        echo -e "Encrypting Root Partition"
        echo -e "-------------------------\n"

        if [ ${PROGRESS_ARRAY[encrypt_root_partition]} == 0 ]
        then
            # Get the name of the last partition
            PARTITION_NAME=$(sfdisk -d /dev/$DISK_NAME | gawk 'match($0, /^\/dev\/(\S+)/, a){print a[1]}' | tail -n1)

            # Catch error
            if [ $? -ne 0 ]
            then 
                echo -e "--- ERROR: Could not find root partition name. ---\n"
                ABORT=1
            else
                echo -e "--- Encrypting partition $PARTITION_NAME ---\n"
                cryptsetup luksFormat -v -s 512 -h sha512 /dev/$PARTITION_NAME
                # Repeat incase it fails (i.e. wrong password)

                if [ $? -ne 0 ]
                then
                    ABORT=1
                    exit
                fi

                echo -e "--- Opening encrypted partition ---\n"
                cryptsetup open /dev/$PARTITION_NAME luks_root
                
            fi
            # Save progress
            PROGRESS_ARRAY[encrypt_root_partition]=1
        else
            echo -e "Already done\n"
        fi
    fi
    save
}


format_partitions()
{
    if [ $ABORT == 0 ]
    then
        echo -e "---------------------"
        echo -e "Formatting Partitions"
        echo -e "---------------------\n"

        if [ ${PROGRESS_ARRAY[format_partitions]} == 0 ]
        then
            echo -e "--- Getting Partition Names ---\n"

            # Get the first partition
            PART1=$(sfdisk -d /dev/$DISK_NAME | gawk 'match($0, /^\/dev\/(\S+)/, a){print a[1]}' | sed -n '1p')
            # Catch error
            if [ $? -ne 0 ]
            then 
                echo -e "--- ERROR: Could not find first partition. ---\n"
                ABORT=1
            else
                # Get the second partition
                PART2=$(sfdisk -d /dev/$DISK_NAME | gawk 'match($0, /^\/dev\/(\S+)/, a){print a[1]}' | sed -n '2p')
                # Catch errors
                if [ $? -ne 0 ]
                then 
                    echo -e "--- ERROR: Could not find second partition. ---\n"
                    ABORT=1
                else
                    # Format all partitions
                    # TODO: In the future, if you're feeling brave, try the BtrFS for luks_root
                    echo -e "--- Formatting partitions ---"
                    echo -e "--- ($PART1, $PART2, and luks_root) ---"
                    mkfs.vfat -n "EFI" /dev/$PART1
                    #mkfs.fat -F 32 /dev/$PART1
                    mkfs.ext4 -L boot /dev/$PART2
                    mkfs.ext4 -L root /dev/mapper/luks_root

                    echo -e "--- Mounting Partitions ---\n"
                    mount /dev/mapper/luks_root /mnt
                    mkdir /mnt/boot
                    mount /dev/$PART2 /mnt/boot
                    mkdir /mnt/boot/efi
                    mount /dev/$PART1 /mnt/boot/efi
                fi
            fi
            # Save progress
            PROGRESS_ARRAY[format_partitions]=1
        else
            echo -e "Already done\n"
        fi
    fi
    save
}

create_swap_file()
{
    if [ $ABORT == 0 ]
    then
        echo -e "-------------------"
        echo -e "Creating SWAP File"
        echo -e "-------------------\n"

        if [ ${PROGRESS_ARRAY[create_swap_file]} == 0 ]
        then
            cd /mnt
            dd if=/dev/zero of=swap bs=1M count=1024
            mkswap swap
            swapon swap
            chmod 0600 swap

            # Catch error
            if [ $? -ne 0 ]
            then 
                echo -e "--- ERROR ---\n"
                ABORT=1
            else
                echo -e "--- Success ---\n"
            fi
            # Save progress
            PROGRESS_ARRAY[create_swap_file]=1
        else
            echo -e "Already done\n"
        fi
    fi
    save
}

set_up_arch()
{
    if [ $ABORT == 0 ]
    then
        echo -e "---------------------"
        echo -e "Setting Up Arch Linux"
        echo -e "---------------------\n"

        if [ ${PROGRESS_ARRAY[set_up_arch]} == 0 ]
        then
            # Install Base Packages
            pacstrap -i /mnt base base-devel efibootmgr grub linux linux-firmware networkmanager sudo vi vim bash-completion nano
            # Catch error
            if [ $? -ne 0 ]
            then 
                echo -e "--- ERROR: Could not install base packages. ---\n"
                ABORT=1
            else
                # Configure fstab
                genfstab -U /mnt >> /mnt/etc/fstab

                # Catch error
                if [ $? -ne 0 ]
                then 
                    echo -e "--- ERROR: Could not generate fstab. ---\n"
                    ABORT=1
                else
                    # Change root into new system
                    PROGRESS_ARRAY[set_up_arch]=1
                    cp -r . /mnt # copy this directory into /mnt
                    arch-chroot /mnt

                    if [ $? -ne 0 ]
                    then
                        echo -e "--- ERROR: Could not change root into /mnt ---\n"
                    fi
                fi
            fi
            # Save progress
            PROGRESS_ARRAY[set_up_arch]=1
        else
            echo -e "Already done\n"
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
get_disk_name
partition_drive 
encrypt_root_partition
format_partitions
create_swap_file
set_up_arch
