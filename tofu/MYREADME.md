Enable IOMMU in your BIOS/UEFI settings
Enable IOMMU in GRUB by modifying /etc/default/grub:

For Intel CPUs, add: intel_iommu=on
For AMD CPUs, add: amd_iommu=on



For example:
bashCopy# Edit GRUB_CMDLINE_LINUX_DEFAULT to add the IOMMU parameter
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"  # or amd_iommu=on for AMD
Then update GRUB and reboot:
bashCopyupdate-grub
reboot
