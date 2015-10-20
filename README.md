# NetApp Powershell Tools / Enhanced Flexclone (sis clone) of Directories with Powershell

This script gets used to advance the cloning process on NetApp volumes. We use it to clone complete directories (scripted from powershell) in an efficent and easy way instead of cloning file by file manually. 

Below, you find the use details and requirements to execute the script.


## Overview
This small Netapp Data ONTAP PowerShell Toolkit allows you create scripted Enhanced Flexclone from a complete (nfs exported) Directory inside a volume. We've used this to create highly storage-efficient automated copy-on-write clones from a bunch of Virtual Machines store on NFS exported Netapp Volumes:

See the example where a 153GB VM has been cloned 1000 times with a storage saving / deduplication of 99%.

<img src="https://github.com/iunera/netapptools/blob/master/enhanced-flexclone-power.PNG" />


Requires the Data ONTAP PowerShell Toolkit installed on the executing system
http://support.netapp.com/NOW/download/tools/powershell_toolkit/
## Howto 

1. load script
 <code> ./NetappTools.psm1 </code>
 

2. logon to the storage 
<code>logonToNaNode -NaNode "your node FQDN/IP"</code>

(optionally) Autologon. Modify the following parameters:

<code>		$strUsername = "root"
    Apply the password as secure string NetappRootEncString.txt</code>
    
- Create a Volume Snapshot:

<code>createVolumeSnapshot -NaNode "nodename/ip" -Volume "volumename" -SnapName "snapname"  </code>

- Remove Volume Snapshot: 

<code>removeVolumeSnapshot -NaNode "nodename/ip" -Volume "volumename" -SnapName "snapname"  </code>


- Enhanced Flexclone of an Directory inside a (NFS Exported) volume: 

<code>cloneFolder -SourceFolder "source" -TargetFolder "target" </code>

example <code>cloneFolder -SourceFolder "vm1" -TargetFolder "vm1_clone" </code>


Contact: christian.schmitt@iunera.com
