# BinariesData.pm
#
# This file is a module part of VNX package.
#
# Author: Fermin Galan Marquez (galan@dit.upm.es), David Fernández (david@dit.upm.es)
# Copyright (C) 2005-2014 	DIT-UPM
# 			Departamento de Ingenieria de Sistemas Telematicos
#			Universidad Politecnica de Madrid
#			SPAIN
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

# BinariesData class implementation. Contain the data related with the binary commands
# needed by the VNX parser.

package VNX::BinariesData;

use strict;
use warnings;

use VNX::Globals;
use VNX::TextManipulation;
use VNX::Execution;


###########################################################################
# CLASS CONSTRUCTOR
#
# Arguments:
#
# - the execution mode
#
sub new {
   my $class = shift;
   my $self = {};
   bless $self;

   $self->{'exe_mode'} = shift;
   
   # List of mandatory binaries
   my @binaries_mandatory = ("touch", "rm",  "mv", "echo", "modprobe", "tunctl", 
   "ifconfig", "cp", "cat", "lsof", "chown",
   "hostname", "route", "scp", "chmod", "ssh", "uml_mconsole",                                                                             
   "date", "ps", "grep", "kill", "ln", "mkisofs", "mktemp", "su", "find",
   "qemu-img", "mkfs.msdos", "mkfs.ext3", "mount", "umount", "sed", "ip", "vnx_mount_rootfs", "pv", "wmctrl");

   # Perl modules mandatory
   my @perlmods_mandatory = qw( NetAddr::IP XML::LibXML XML::Tidy AppConfig Readonly 
                                Term::ReadKey Net::Pcap Net::IPv6Addr Sys::Virt Net::Telnet 
                                Error Exception::Class DBI IO::Pty Net::IP);
#   my @perlmods_mandatory = qw( NetAddr::IP XML::LibXML XML::Tidy AppConfig Readonly 
#                                Term::ReadKey Net::Pcap Net::IPv6Addr Sys::Virt Net::Telnet 
#                                Error Exception::Class XML::DOM DBI Math::Round IO::Pty 
#                                Net::IP XML::Checker XML::Parser File::HomeDir);
   
   # List of optional binaries for xterm, vlan, screen and
   # uml_switch (defaults are empty: the add_additional_*_binaries 
   # methods add required binaries, based on the VNX specification
   my @binaries_xterm = ();
   my @binaries_vlan = ();
   my @binaries_screen = ();
   my @binaries_switch = ();
   my @binaries_bridge = ();
   my @binaries_lxc = ();
   my @binaries_libvirt = ();
   my @binaries_kvm = ();
                                           
   # Hash to store paths of binaries (empty util check_binaries method is called)
   my %bp;
  
   # Assignements by reference
   $self->{'binaries_mandatory'} = \@binaries_mandatory;
   $self->{'perlmods_mandatory'} = \@perlmods_mandatory;
   $self->{'binaries_screen'} = \@binaries_screen;
   $self->{'binaries_vlan'} = \@binaries_vlan;
   $self->{'binaries_switch'} = \@binaries_switch;
   $self->{'binaries_bridge'} = \@binaries_bridge;
   $self->{'binaries_xterm'} = \@binaries_xterm;
   $self->{'binaries_lxc'} = \@binaries_lxc;
   $self->{'binaries_libvirt'} = \@binaries_libvirt;
   $self->{'binaries_kvm'} = \@binaries_kvm;
   $self->{'binaries_path'} = \%bp;

   return $self;  
}

###########################################################################
# PUBLIC METHODS

# add_additional_xterm_binaries
#
# Arguments:
#	- The DataHandler object describin the VNX XML specification
#
sub add_additional_xterm_binaries {
	my $self = shift;

    # Check <vm_defaults>, in order to detect consoles with xterm
    my %xterm_console_default;
	my @vm_defaults_list = $dh->get_doc->getElementsByTagName("vm_defaults");
    if (@vm_defaults_list == 1) {
        #my $console_list = $vm_defaults_list[0]->getElementsByTagName("console");
        #for (my $i = 0; $i < $console_list->getLength; $i++) {
       	foreach my $console ($vm_defaults_list[0]->getElementsByTagName("console")) {
            if (&text_tag($console) eq "xterm") {
                my $console_id = $console->getAttribute("id");
                $xterm_console_default{$console_id} = 1;
            }
        }
    }

	my %xterm_binaries;
	my @vm_list = $dh->get_doc->getElementsByTagName("vm");
	#for ( my $i = 0 ; $i < $vm_list->getLength; $i++ ) {
	foreach my $vm ($dh->get_doc->getElementsByTagName("vm")) {
		# Is using the virtual machine a xterm? Check the efective
		# consoles list
						
		my $xterm_is_used = 0;
		my @console_list = $dh->merge_console($vm);
		foreach my $console (@console_list) {
	       if (&text_tag($console) eq 'xterm') {
		      $xterm_is_used = 1;
		      last;
		   }
		}
		
		if ($xterm_is_used) {
		   my $xterm;
		   my @xterm_list = $vm->getElementsByTagName("xterm");
		   if (@xterm_list > 0) {
	          $xterm = &text_tag($xterm_list[0]);
           }
		   else {
              # If <xterm> has been specified in <vm_defaults> use that value
              if (@vm_defaults_list == 1) {
                 foreach my $xterm_tag ($vm_defaults_list[0]->getElementsByTagName("xterm")) {
                    $xterm = &text_tag($xterm_tag);
                 }
                 if (!$xterm) {
                    $xterm = "xterm,-T,-e";
                 }
              }
			  else {			
			     # Get the default xterm for the kernel
			     my $kernel = $dh->get_default_kernel;
		  	     my @kernel_list = $vm->getElementsByTagName("kernel");
			     if (@kernel_list > 0) {
				    $kernel = &text_tag($kernel_list[0]);
			     }
			     my $cmd = "$kernel --help | grep \"default values are 'xterm=\"";
			     chomp(my $line = `$cmd`);
			     if ($line =~ /'xterm=([^\']+)/) {
			        $xterm = $1;
			     }
			     else {
			        $xterm = "xterm,-T,-e";
			     }
		      }
		   }
	       # Asumming the xterm string will be something as the
	       # following pattern: gnome-terminal,-t,-x (this is the 
	       # format for the xterm= UML switch)
	       $xterm =~ s/^(.+),.+,.+$/$1/;
	       $xterm_binaries{$1} = 1;		
	    }
	}
	
	my @list = keys %xterm_binaries;
	if ($#list >= 0) {
		push(@list,'xauth');
	}
	$self->{'binaries_xterm'} = \@list;
}

# add_additional_vlan_binaries
#
# Arguments:
#	- The DataHandler object describing the VNX XML specification
#
sub add_additional_vlan_binaries {
   my $self = shift;
   
   # Check that there are at least one <net> tag using vlan attribute   
   my @list = ();
   if ($dh->check_tag_attribute("net","vlan") != 0) {   
      push (@list,"vconfig");
   }
   $self->{'binaries_vlan'} = \@list;
}

# add_additional_screen_binaries
#
# Arguments:
#	- The DataHandler object describing the VNX XML specification
#
sub add_additional_screen_binaries {
    my $self = shift;
   
    my @list = ();
   
    #my $vm_list = $dh->get_doc->getElementsByTagName("vm");
    #for (my $i = 0; $i < $vm_list->getLength; $i++) {
   	foreach my $vm ($dh->get_doc->getElementsByTagName("vm")) {
        my @console_list = $dh->merge_console($vm);
        foreach my $console (@console_list) {
            if (&text_tag($console) eq 'pts') {
                push (@list,"screen");
                last;
            }
        }
    }
      
    $self->{'binaries_screen'} = \@list;
}

# add_additional_uml_switch_binaries
#
# Arguments:
#	- The DataHandler object describing the VNX XML specification
#
sub add_additional_uml_switch_binaries {
    my $self = shift;
    my @list = ();
   
    # Additional case: when using <mgmt_net autoconfigure="on"> uml_switch
    # must be added.
    if ($dh->get_vmmgmt_autoconfigure ne "") {
        @list = ("uml_switch");
    }   
   
    #my $net_list = $dh->get_doc->getElementsByTagName("net");
    #for (my $i = 0; $i < $net_list->getLength; $i++) {
    foreach my $net ($dh->get_doc->getElementsByTagName("net")) {
        if ($net->getAttribute("mode") eq "uml_switch") {
            @list  = ("uml_switch");
            last;
        }
    }   
    $self->{'binaries_switch'} = \@list;
}

# add_additional_bridge_binaries
#
# Arguments:
#	- The DataHandler object describing the VNX XML specification
#
sub add_additional_bridge_binaries {
    my $self = shift;
   
    my $vbridge;
    my $ovs;
            
    my @list = ();
    foreach my $net ($dh->get_doc->getElementsByTagName("net")) {
        if ( ($net->getAttribute("mode") eq "virtual_bridge") && !$vbridge ) {
            push (@list, "brctl");
            $vbridge = 'yes';
            next;
        } elsif( ($net->getAttribute("mode") eq "openvswitch") && !$ovs ) {
            push (@list, "ovs-vsctl");
            $ovs = 'yes';
            next;
        }
    }   
    $self->{'binaries_bridge'} = \@list;
    #print "list=@list\n";
    
}

# add_additional_lxc_binaries
#
# Arguments:
#   - The DataHandler object describing the VNX XML specification
#
sub add_additional_lxc_binaries {
    my $self = shift;
   
    my $ovs;
            
    my @list = ();
    if ( $dh->any_vmtouse_of_type('lxc') ) {
        push (@list, "lxc-info");
        push (@list, "lxc-start");
        push (@list, "lxc-stop");
        push (@list, "lxc-freeze");
        push (@list, "lxc-unfreeze");
        push (@list, "lxc-attach");
    }
    $self->{'binaries_lxc'} = \@list;
    #print "list=@list\n";    
}

# add_additional_libvirt_binaries
#
# Arguments:
#   - The DataHandler object describing the VNX XML specification
#
sub add_additional_libvirt_binaries {
    my $self = shift;
              
    my @list = ();
    if ( $dh->any_vmtouse_of_type('libvirt') ) {
        push (@list, "virsh");
    }
    $self->{'binaries_libvirt'} = \@list;
    #print "list=@list\n";    
}

# add_additional_kvm_binaries
#
# Arguments:
#   - The DataHandler object describing the VNX XML specification
#
sub add_additional_kvm_binaries {
    my $self = shift;
            
    my @list = ();
    if ( $dh->any_vmtouse_of_type('libvirt', 'kvm') ) {
        #push (@list, "kvm-ok"); # deleted: not available in Fedora
    }
    $self->{'binaries_kvm'} = \@list;
    #print "list=@list\n";    
}


# check_binaries_mandatory
sub check_binaries_mandatory {
    my $self = shift; 
    my $ref = $self->{'binaries_mandatory'};
    my @list = @$ref;
    return &check_binaries($self, @list); 
}

# check_perlmods_mandatory
sub check_perlmods_mandatory {
    my $self = shift;
    
    my $res; 
    my $ref = $self->{'perlmods_mandatory'};
    my @list = @$ref;
    foreach my $pmod (@list) {
        #print "Checking if perl module $pmod is installed\n";
        my $check=`perl -M$pmod -e 1 2>&1`;
        if ($check) {
            $res .= " $pmod";
        }
    }
    if ($res) {
    	$res = "ERROR: some perl module(s) required by VNX are not installed ($res )";
    }
    return $res;
}
    

# check_binaries_screen
sub check_binaries_screen {
   my $self = shift;   
   my $ref = $self->{'binaries_screen'};
   my @list = @$ref;
   return &check_binaries($self, @list); 
}

# check_binaries_vlan
sub check_binaries_vlan {
   my $self = shift;
   my $ref = $self->{'binaries_vlan'};
   my @list = @$ref;
   return &check_binaries($self, @list); 
}

# check_binaries_switch
sub check_binaries_switch {
   my $self = shift;   
   my $ref = $self->{'binaries_switch'};
   my @list = @$ref;
   return &check_binaries($self, @list); 
}

# check_binaries_bridge
sub check_binaries_bridge {
   my $self = shift;   
   my $ref = $self->{'binaries_bridge'};
   my @list = @$ref;
   return &check_binaries($self, @list); 
}

# check_binaries_xterm
sub check_binaries_xterm {
   my $self = shift;   
   my $ref = $self->{'binaries_xterm'};
   my @list = @$ref;
   return &check_binaries($self, @list); 
}

# check_binaries_lxc
sub check_binaries_lxc {
   my $self = shift;   
   my $ref = $self->{'binaries_lxc'};
   my @list = @$ref;
   return &check_binaries($self, @list); 
}

# check_binaries_libvirt
sub check_binaries_libvirt {
   my $self = shift;   
   my $ref = $self->{'binaries_libvirt'};
   my @list = @$ref;
   return &check_binaries($self, @list); 
}

# check_binaries_kvm
sub check_binaries_kvm {
   my $self = shift;   
   my $ref = $self->{'binaries_kvm'};
   my @list = @$ref;
   return &check_binaries($self, @list); 
}

# get_binaries_path_ref
#
# Returns the binaries path associative array reference

sub get_binaries_path_ref {
   my $self = shift;
   
   return $self->{'binaries_path'};
   
}

###########################################################################
# PRIVATE METHODS (it only must be used from this class itsefl)

# check_binaries
#
# Check if the binaries needed for VNX operation are available.
# First argument is the list of binaries to check. Return the
# number of unchecked binaries (0 if all the binaries were found).
#
# Path of checked binaries are stored in the binary_path hast hable in the
# BinariesData object.
#
sub check_binaries {
    my $self = shift;
   
    my $exe_mode = $self->{'exe_mode'};
   
    my $unchecked = 0;
    foreach (@_) {
        #print "Checking $_... " if (($exe_mode == EXE_VERBOSE) || ($exe_mode == EXE_DEBUG));
        my $fail = system("which $_ > /dev/null");
        my $where = `which $_`;
      
        # Particular cases:
        # - If mkisofs is not found, try with genisoimage (needed for Debian hosts)
        if ( ($_ eq 'mkisofs') && ($fail) ) {
            #print "which 'genisoimage' > /dev/null\n";
            $fail = system("which genisoimage > /dev/null");
            $where = `which genisoimage`;
        
        }
      
        if ($fail) {
        	#if (($exe_mode == $EXE_VERBOSE) || ($exe_mode == $EXE_DEBUG)) {
                print "$hline\nERROR: binary file missing:\n'$_' command not found\n";
        	#}
            $unchecked++;
        } else {
            chomp($where);
            #print "$where\n" if (($exe_mode == EXE_VERBOSE) || ($exe_mode == EXE_DEBUG));;
            # Add to the binary_path hash array
            $self->{'binaries_path'}->{$_} = $where;
        }
    }
   
    return $unchecked; 

}

1;
