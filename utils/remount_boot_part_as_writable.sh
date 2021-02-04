#!/bin/bash

remount_boot_partition_as_writable() {
  # for upgrading the linux kernel, firmware, video drivers 
  # and other stuff requiring mkinitcpio regenerationn

  echo "=========================="
  echo "Finding EFI boot partition"
  echo "--------------------------"
  echo

  BOOT_PARTITION=$(sudo fdisk -l | grep EFI | cut -d' ' -f1)
  echo $BOOT_PARTITION

  echo
  echo "======================================"
  echo "Finding EFI boot partition mount point"
  echo "--------------------------------------"
  echo

  BOOT_PARTITION_MOUNT_POINT=$(mount -v | grep /dev/sda1 | cut -d' ' -f3)
  echo $BOOT_PARTITION_MOUNT_POINT
  
  echo
  echo "=========================================="
  echo "Checking partition stats before remounting"
  echo "------------------------------------------"
  echo

  mount -v | grep $BOOT_PARTITION
  
  echo
  echo "================================================================"
  echo "Remounting EFI boot partition to the same boot point as writable"
  echo "----------------------------------------------------------------"
  echo

  sudo mount -o remount,rw $BOOT_PARTITION $BOOT_PARTITION_MOUNT_POINT

  echo "========================================="
  echo "Checking partition stats after remounting"
  echo "-----------------------------------------"
  echo

  mount -v | grep $BOOT_PARTITION
}

main() {
  remount_boot_partition_as_writable
}

main

