#!/bin/bash

##############################################
# Save Progress
##############################################
progress_file_name="Arch_Installer_Progress.txt"
declare -A PROGRESS_ARRAY
PROGRESS_ARRAY=(
    [verify_boot_mode]=1
    [configure_clock]=1
    [load_luks_modules]=1
    [get_disk_name]=1
    [partition_drive]=1
    [encrypt_root_partition]=1
    [format_partitions]=1
    [create_swap_file]=1
    [set_up_arch]=1
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
        PROGRESS_ARRAY[set_up_arch]=1
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

# Configure Arch
configure_locale()
{
    if [ $ABORT == 0 ]
    then
        echo -e "----------------"
        echo -e "Configure Locale"
        echo -e "----------------\n"

        if [ ${PROGRESS_ARRAY[configure_locale]} == 0 ]
        then
            # Time Zone
            ln -sf "/usr/share/zoneinfo/US/Eastern" /etc/localtime
            hwclock --systohc

            cd "$old_dir"
            
            # Add en_US.UTF-8 locale
            echo -e "--- Adding en_US.UTF-8 UTF-8 locale ---\n"
            echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
            locale-gen
            echo "LANG=en_US.UTF-8" >> /etc/locale.conf
            
            # Save progress
            PROGRESS_ARRAY[configure_locale]=1
        else
            echo -e "Already done\n"
        fi
    fi
    save
}   

# Network
configure_network()
{
    if [ $ABORT == 0 ]
    then
        echo -e "-------------------"
        echo -e "Configuring Network"
        echo -e "-------------------\n"

        if [ ${PROGRESS_ARRAY[configure_network]} == 0 ]
        then
            echo "ElliotYoga" > /etc/hostname
            # Save progress
            PROGRESS_ARRAY[configure_network]=1
        else
            echo -e "Already done\n"
        fi
    fi
    save
}

prepare_boot_loader()
{
    if [ $ABORT == 0 ]
    then
        echo -e "------------------------------"
        echo -e "Preparing boot loader for LUKS"
        echo -e "------------------------------\n"

        # Make sure we get the disk name
        PROGRESS_ARRAY[get_disk_name]=0
        get_disk_name
        
        if [ ${PROGRESS_ARRAY[prepare_boot_loader]} == 0 ]
        then
            # Get third partition name 
            PART2=$(sfdisk -d /dev/$DISK_NAME | gawk 'match($0, /^\/dev\/(\S+)/, a){print a[1]}' | sed -n '2p')
            PART3=$(sfdisk -d /dev/$DISK_NAME | gawk 'match($0, /^\/dev\/(\S+)/, a){print a[1]}' | sed -n '3p')

            # Catch error
            if [ $? -ne 0 ]
            then 
                echo -e "--- ERROR: Could not find third partition name. ---\n"
                ABORT=1
            else
                echo -e "--- 3rd Partition name is $PART3 ---\n"
                # Replace the line GRUB_CMDLINE_LINUX="" in
                # /etc/default/grub with
                # GRUB_CMDLINE_LINUX="cryptdevice=/dev/sda3:luks_root"
                sed -i "s/GRUB_CMDLINE_LINUX\=.*/GRUB_CMDLINE_LINUX\=\"cryptdevice=\/dev\/$PART3:luks_root\"/g" /etc/default/grub

                # Initramfs
                echo -e "--- Generating initramfs ---\n"
                sed -i 's/HOOKS=(\(.*\)\(filesystems.*\)/HOOKS=(\1encrypt \2/' /etc/mkinitcpio.conf
                mkinitcpio -p linux

                # Root Password
                echo -e "--- Please Enter your Root Password ---\n"
                passwd

                echo -e "--- Installing Boot Loader ---\n"
                grub-install --boot-directory=/boot --efi-directory=/boot/efi /dev/$PART2
                grub-mkconfig -o /boot/grub/grub.cfg
                grub-mkconfig -o /boot/efi/EFI/arch/grub.cfg

            fi
            # Save progress
            PROGRESS_ARRAY[prepare_boot_loader]=1
        else
            echo -e "Already done\n"
        fi
    fi
    save
}

####################################################3
# Main
####################################################3

configure_locale
configure_network
prepare_boot_loader
#echo -e "\n--- Done.  Now 'exit' and 'reboot' ---\n"
