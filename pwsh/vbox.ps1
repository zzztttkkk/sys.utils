Set-Alias vbox "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

function vboxctrl(){
    param (
		[String] $vmname,
        [String] $op
	)

    if ( $vmname -eq "" ) {
        $tmp = gum choose (vbox list vms)
        if ( $tmp -eq $null ) {
            return
        }
        $vmname = (($tmp -split "{")[1] -split "}")[0]
    }

    if ( $op -eq "" ) {
        $op = gum choose "pause" "resume" "poweroff" "reboot" "shutdown" "start"
        if ( $op -eq $null ) {
            return
        }
    }

    if ( $op -eq "start" ) {
        vbox startvm --type=headless $vmname
        return
    }
    vbox controlvm $vmname $op $args
}
