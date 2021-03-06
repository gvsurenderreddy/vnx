#!/bin/bash

#
# Name: vnx_download_rootfs
#
# Description: download, uncompress and optionally create links to root filesystems 
#               for VNX to current directory
#
# This file is a module part of VNX package.
#
# Authors: Jorge Somavilla (somavilla@dit.upm.es), David Fernández (david@dit.upm.es)
# Copyright (C) 2012,2016   DIT-UPM
#           Departamento de Ingenieria de Sistemas Telematicos
#           Universidad Politecnica de Madrid
#           SPAIN
#           
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
# An online copy of the licence can be found at http://www.gnu.org/copyleft/gpl.html
#

#
# Constant and variables
#
VNXACED_VER='2.0b.5815'
VNXACED_BUILT='02/05/2016_19:03'
#fsdir="/usr/share/vnx/filesystems"
vnx_rootfs_repo="http://vnx.dit.upm.es/vnx/filesystems/"
create_sym_link=""
cmds_required="wget curl md5sum w3m"
rootfs_links_array=''

USAGE="
vnx_download_rootfs: download, uncompress and optionally create links to 
                     root filesystems for VNX to current directory

Usage:  vnx_download_rootfs [-l] [-r <rootfsname>] [-y]
        vnx_download_rootfs -s
        
Options:    -s -> show root filesystems available at VNX repository
            -l -> creates a "rootfs_*" link to the root filesystem download
            -r <rootfsname> -> use it to download a specific root filesystem
            -y -> overwrite local files without asking for permission
            -n -> execute wget in no-verbose mode (--nv option)
            -p -> pattern to filter rootfs names (no regular expressions allowed)
            -h -> show this help

When no rootfs (-r option) is specified, vnx_download_rootfs starts in interactive mode            
"
HEADER1="
----------------------------------------------------------------------------------
Virtual Networks over LinuX (VNX) -- http://www.dit.upm.es/vnx - vnx@dit.upm.es
Version: $VNXACED_VER ($VNXACED_BUILT)
----------------------------------------------------------------------------------"

HEADER2="
vnx_download_rootfs: download, uncompress and optionally create links to
                     root filesystems for VNX to current directory
 
Repository:    $vnx_rootfs_repo"


#------------------------------------------------------------------

#
# Return name of symbolic link for a root_fs
#
function get_link_name {

   if [[ $1 == *honeydrive* ]] ; then
      echo "rootfs_honeydrive"; return
   fi

   if [[ $1 == *honeywall* ]] ; then
      echo "rootfs_honeywall"; return
   fi

   if [[ $1 == *metasploitable* ]] ; then
      echo "rootfs_metasploitable"; return
   fi

   if [[ $1 == *caine* ]] ; then
      echo "rootfs_caine"; return
   fi

   if [[ $1 == *remnux64* ]] ; then
      echo "rootfs_remnux64"; return
   fi

   if [[ $1 == *uml* ]] ; then
      if [[ $1 == *debian* ]] ; then
         echo "rootfs_tutorial"; return
      else
         echo "rootfs_light"; return      
      fi
   fi
   
   if [[ $1 == *lxc*ubuntu64* ]] ; then
      echo "rootfs_lxc_ubuntu64"; return
   elif [[ $1 == *lxc*ubuntu* ]] ; then
      echo "rootfs_lxc rootfs_lxc_ubuntu"; return
   elif [[ $1 == *ubuntu64* ]] ; then
      if [[ $1 == *gui* ]] ; then
         echo "rootfs_ubuntu64-gui"; return
      else
         echo "rootfs_ubuntu64"; return
      fi   
   elif [[ $1 == *ubuntu* ]] ; then
      if [[ $1 == *gui* ]] ; then
         echo "rootfs_ubuntu-gui"; return
      else
         echo "rootfs_ubuntu"; return
      fi
   fi

   if [[ $1 == *freebsd64* ]] ; then
      if [[ $1 == *gui* ]] ; then
         echo "rootfs_freebsd64-gui"; return
      else
         echo "rootfs_freebsd64"; return
      fi   
   elif [[ $1 == *freebsd* ]] ; then
      if [[ $1 == *gui* ]] ; then
         echo "rootfs_freebsd-gui"; return
      else
         echo "rootfs_freebsd"; return
      fi
   fi

   if [[ $1 == *openbsd64* ]] ; then
      if [[ $1 == *gui* ]] ; then
         echo "rootfs_openbsd64-gui"; return
      else
         echo "rootfs_openbsd64"; return
      fi   
   elif [[ $1 == *openbsd* ]] ; then
      if [[ $1 == *gui* ]] ; then
         echo "rootfs_openbsd-gui"; return
      else
         echo "rootfs_openbsd"; return
      fi
   fi

   if [[ $1 == *fedora64* ]] ; then
      if [[ $1 == *gui* ]] ; then
         echo "rootfs_fedora64-gui"; return
      else
         echo "rootfs_fedora64"; return
      fi
   elif [[ $1 == *fedora* ]] ; then
      if [[ $1 == *gui* ]] ; then
         echo "rootfs_fedora-gui"; return
      else
         echo "rootfs_fedora"; return
      fi
   fi

   if [[ $1 == *centos64* ]] ; then
      if [[ $1 == *gui* ]] ; then
         echo "rootfs_centos64-gui"; return
      else
         echo "rootfs_centos64"; return
      fi
   elif [[ $1 == *centos* ]] ; then
      if [[ $1 == *gui* ]] ; then
         echo "rootfs_centos-gui"; return
      else
         echo "rootfs_centos"; return
      fi
   fi

   if [[ $1 == *android* ]] ; then
      echo "rootfs_android"; return
   fi

   if [[ $1 == *kali64* ]] ; then
      echo "rootfs_kali64"; return
   elif [[ $1 == *kali* ]] ; then
      echo "rootfs_kali"; return
   fi

}

#------------------------------------------------------------------

function show_rootfs_array {

    OLD_IFS=$IFS; IFS=$'\n'
    if [ "$pattern" ]; then
        rootfs_links_array=($(curl $vnx_rootfs_repo -s | w3m -dump -T text/html | grep $pattern | grep -e 'bz2' -e 'tgz'))
    else
        rootfs_links_array=($(curl $vnx_rootfs_repo -s | w3m -dump -T text/html | grep -e 'bz2' -e 'tgz'))
    fi
    IFS=$OLD_IFS

    printf "%-4s %-60s %-11s %6s\n" "Num" "Rootfs name" "Date" "Size" 
    echo "------------------------------------------------------------------------------------"

    # Show filesystems on server in columns
    for (( i = 0 ; i < ${#rootfs_links_array[@]} ; i++ ))
    do
        OLD_IFS=$IFS; IFS=$'\n'
        rootfs_num=$(( i + 1 ))  
        #echo ${rootfs_links_array[$i]} | sed -e "s/\[ \]/$NUM/g" | column
        rootfs_name=$( echo ${rootfs_links_array[$i]} | awk '{ print $3 }' )
        rootfs_date=$( echo ${rootfs_links_array[$i]} | awk '{ print $4 }' )
        rootfs_size=$( echo ${rootfs_links_array[$i]} | awk '{ print $5 }' )
        printf "%-4s %-60s %-11s %6s\n" "$rootfs_num" "$rootfs_name" "$rootfs_date" "$rootfs_size" 
        IFS=$OLD_IFS
    done
    echo "------------------------------------------------------------------------------------"

}

#------------------------------------------------------------------

function download_rootfs {

    rootfs_url=(${vnx_rootfs_repo}${rootfs_bzname})
    rootfs_ext=${rootfs_bzname##*.}
    rootfs_md5=${rootfs_name}.md5
    rootfs_md5_url=(${vnx_rootfs_repo}${rootfs_md5}) 
          
    echo "rootfs_bzname=$rootfs_bzname"
    echo "rootfs_name=$rootfs_name"
    echo "rootfs_md5=$rootfs_md5"
    
    if [ -e $rootfs_bzname ]; then
        echo "Compressed root filesystem '$rootfs_bzname' already exists."
        if [ ! $yes ]; then 
            echo -n "Do you want to overwrite it (y/n)? "
            read choice
            if [ "$choice" == "y" -o  "$choice" = "Y" ] ; then
                echo "Deleting ${rootfs_bzname}..."
                rm 
                -v ./$rootfs_bzname 
            else
                echo ""
                return
            fi
        else
            echo "Deleting ${rootfs_bzname}..."
            rm -v ./$rootfs_bzname 
        fi
    fi
    
    error404=""
    wget $NV --progress=dot:giga -N $rootfs_url || error404="true"
    #echo $error404
    if [ "$error404" == "true" ] ; then
        echo "------------------------------------------------------------------------"
        echo "ERROR: Root filesystem ($rootfs_name) not found in repository"
        echo "       Use 'vnx_download_rootfs -s' to see the list of rootfs available"
        echo "------------------------------------------------------------------------"
        exit
    fi
    
    if [ -e $rootfs_name ]; then
        echo "Uncompressed root filesystem '$rootfs_name' already exists."
        if [ ! $yes ]; then 
            echo -n "Do you want to overwrite it (y/n)? "
            read choice
            if [ "$choice" == "y" -o  "$choice" = "Y" ] ; then
                echo "Deleting ${rootfs_name}..."
                rm -r ./$rootfs_name 
            else
                echo ""
                return
            fi
        else
            echo "Deleting ${rootfs_name}..."
            rm -r ./$rootfs_name 
        fi
    fi
    
    echo "Extracting $rootfs_bzname..."
    case $rootfs_ext in
    bz2) bunzip2 $rootfs_bzname
         ;;
    tgz) tar --numeric-owner -xzpf $rootfs_bzname
         ;;
    esac

    if [ "$create_sym_link" == "yes" ] ; then
        # Create symbolic link if -l
        link_names=$(get_link_name $rootfs_name)
        for link_name in $link_names; do
            echo "Creating simbolic link: '$link_name'->'$rootfs_name'"
            rm -f ./$link_name
            ln -s $rootfs_name $link_name
        done
    elif [ $interactive ]; then
        link_names=$(get_link_name $rootfs_name)
        for link_name in $link_names; do
            echo -n "Do you want to create a symbolic link: '$link_name'->'$rootfs_name' (y/n)? "
            read choice
            if [ "$choice" == "y" -o  "$choice" = "Y" ] ; then
                echo "Creating simbolic link..."
                rm -f ./$link_name
                ln -s $rootfs_name $link_name
                sleep 1
            fi
        done
    fi
    
    # Check md5sum
    rm -f ./$rootfs_md5
    wget $NV --progress=dot:binary -N $rootfs_md5_url
    md5_in_file=`cat $rootfs_md5 | awk '{print $1}'`
    case $rootfs_ext in
    bz2) md5_calculated=`md5sum $rootfs_name | awk '{print $1}'`
         ;;
    tgz) md5_calculated=`md5sum $rootfs_bzname | awk '{print $1}'`
         ;;
    esac
    
    rm -f ./$rootfs_md5
    if [ "$md5_in_file" != "$md5_calculated" ]; then
        echo "-----------------------------------------------------------------------------"
        echo "ERROR: incorrect md5sum for rootfs downloaded ($rootfs_name)."
        echo "       md5 in repository:      $md5_in_file"
        echo "       md5 of downloaded file: $md5_calculated"
        echo "-----------------------------------------------------------------------------"
        echo ""
        sleep 5
    else
        echo "------------------------------------------------------------------------"
        echo "$rootfs_name successfully installed."
        echo "   md5 in repository:      $md5_in_file"
        echo "   md5 of downloaded file: $md5_calculated"
        echo "------------------------------------------------------------------------"
        echo ""
    fi
            
}                
                                
#------------------------------------------------------------------

function check_access_to_repository {

    # Check if the filesystem repository is available
    wget "$vnx_rootfs_repo" --timeout 5 -O /dev/null 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "--"; echo "ERROR: cannot access filesystem repository ($vnx_rootfs_repo)"; echo "--"; exit 1
    fi

}

#------------------------------------------------------------------

function download_rootfs_interactive {

    # show filesystems in server and ask user to choose

    check_access_to_repository

    OLD_IFS=$IFS; IFS=$'\n'
    if [ "$pattern" ]; then
        rootfs_links_array=($(curl $vnx_rootfs_repo -s | w3m -dump -T text/html | grep $pattern | grep -e 'bz2' -e 'tgz'))
    else
        rootfs_links_array=($(curl $vnx_rootfs_repo -s | w3m -dump -T text/html | grep -e 'bz2' -e 'tgz'))
    fi
    IFS=$OLD_IFS

    while true; do

        show_rootfs_array {

        # Read choice from user
        echo ""
        echo -n "Type the number [0-`expr ${#rootfs_links_array[@]} - 1`] of rootfs to download or 'q' to quit: "
        read choice

        # Check empty choice
        if [[ -z $choice ]] ; then
            echo "Your choice is not valid, please try again."
            echo ""
            sleep 2
            continue
        fi

        # Check for choice f = finish installing filesystems
        if [ $choice = q ] ; then
            echo ""
            #sleep 1
            exit 0
        fi

        # Check that chosen number is on the list (0<=$choice<=max) and install
        choice=$(($choice-1)) # rootfs numbers start in 1
        if [ $choice -ge 0 ] ; then 
            if [ $choice -le `expr ${#rootfs_links_array[@]} - 1` ] ; then

                rootfs_bzname=$(echo ${rootfs_links_array[$choice]} | awk '{print $3}')
                rootfs_name=$(echo $rootfs_bzname | sed -e "s/.bz2//g" -e "s/.tgz//g")

                download_rootfs

                sleep 3
                continue
            fi

            echo "Your choice is not valid, please try again."
            echo ""
            sleep 2
            continue
        fi
   done
}

#------------------------------------------------------------------

# 
# Main
#

#
# Check curl and wget are installed
#
for cmd in $cmds_required; do 
    #echo -n "Checking if $cmd is available..." 
    if [ ! $( which $cmd ) ]; then
        echo ""
        echo "-----------------------------------------"
        echo "ERROR: command '$cmd' not installed"
        echo "-----------------------------------------"
        exit 1;
    fi
    #echo "OK"
done


while getopts ":nyshl :r:p:" opt; do
    case $opt in

    l)
        #echo "-l was triggered" >&2
        create_sym_link="yes"
        ;;
    y)
        #echo "-Y was triggered" >&2
        yes="true"
        ;;
    r)
        #echo "-r was triggered, Parameter: $OPTARG" >&2
        
        check_access_to_repository

        rootfs_bzname=$OPTARG
        
        NAME=$OPTARG
        if [ $( echo $NAME | egrep -e '\.bz2$' -e '\.tgz$') ]; then
            # Name with extension
            echo Name with extension
            rootfs_bzname=$NAME
            rootfs_name=$( echo $NAME | sed -e 's/\.bz2//' -e 's/\.tgz//')
        else
            # Name without .bz2 or .tgz extension
            echo Name without extension            
            rootfs_name=$NAME
            if [ `echo "$NAME" | grep _lxc_` ]; then
                rootfs_bzname=${NAME}.tgz
            else
                rootfs_bzname=${NAME}.bz2
            fi
        fi
        echo "rootfs_name=$rootfs_name"
        echo "rootfs_bzname=$rootfs_bzname"
        ;;
    s)
        #echo "-s was triggered, Parameter: $OPTARG" >&2
        check_access_to_repository
        show_listing='yes' 
        ;;
    n)
        #echo "-n was triggered" >&2
        NV="-nv"
        ;;
    p)
        #echo "-p was triggered" >&2
        pattern="$OPTARG"
        ;;
    h)
        #echo "-h was triggered, Parameter: $OPTARG" >&2
        echo "$USAGE"
        exit 0
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        echo "$USAGE"
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;

    esac
done

echo "$HEADER1"
echo "$HEADER2"
echo -n "Current dir:   "
pwd 
echo ""

if [ "$show_listing" == "yes" ] ; then

    echo "$HEADER1"
    echo ""
    echo "Repository:    $vnx_rootfs_repo"
    echo ""
    show_rootfs_array

elif [ ! $rootfs_bzname = "" ] ; then
    download_rootfs

else # No rootfs specified; go to interactive mode
    interactive="yes"
    download_rootfs_interactive
fi

exit 0






