# usb              list partitions on every USB disk
# usb m [dev]      mount (default: the first unmounted partition)
# usb u [dev]      unmount (default: every mounted partition)
# usb e [dev]      unmount the whole disk, then power it down for unplugging

def usb-disks [] {
    lsblk -Jpo NAME,TYPE,TRAN,SIZE,FSTYPE,LABEL,MOUNTPOINT
    | from json | get blockdevices
    | where type == disk and tran == usb
}

def usb-parts [] {
    usb-disks | each {|d|
        $d.children? | default [] | where type == part | insert disk $d.name
    } | flatten
}

def usb-cmds [] {
    [
        {value: list, description: "list partitions"}
        {value: m, description: "mount"}
        {value: u, description: "unmount"}
        {value: e, description: "unmount + power off"}
    ]
}

def usb-devs [] {
    usb-parts | each {|p| {value: $p.name, description: $"($p.size) ($p.label? | default '') ($p.mountpoint? | default '')"} }
}

# Mount/unmount/eject USB drives via udisksctl
export def main [
    cmd?: string@usb-cmds   # list | m | u | e, or a /dev path to mount
    dev?: string@usb-devs   # device to act on
] {
    let disks = usb-disks
    if ($disks | is-empty) { error make -u {msg: "no usb disks attached"} }

    let parts = usb-parts
    let formatted = $parts | where fstype != null
    let mounted = $formatted | where mountpoint != null | get name
    let free = $formatted | where mountpoint == null | get name

    let cmd = $cmd | default list
    let dev = if ($cmd | str starts-with /dev/) { $cmd } else { $dev }
    let cmd = if ($cmd | str starts-with /dev/) { "mount" } else { $cmd }

    match $cmd {
        list | l => { $parts | select disk name size fstype label mountpoint }
        mount | m => {
            let d = $dev | default ($free | get 0?)
            if $d == null { error make -u {msg: "nothing left to mount"} }
            udisksctl mount -b $d
        }
        umount | unmount | u => {
            let targets = if $dev != null { [$dev] } else { $mounted }
            if ($targets | is-empty) { error make -u {msg: "nothing mounted"} }
            for p in $targets { udisksctl unmount -b $p }
        }
        eject | e => {
            let d = $dev | default ($disks | first | get name)
            let d = if $d in $disks.name { $d } else { $"/dev/(lsblk -nro PKNAME $d | str trim)" }
            for p in ($mounted | where {|p| $p | str starts-with $d }) { udisksctl unmount -b $p }
            udisksctl power-off -b $d
            print $"safe to unplug ($d)"
        }
        _ => { error make -u {msg: "usage: usb [list|m|u|e] [dev]"} }
    }
}
