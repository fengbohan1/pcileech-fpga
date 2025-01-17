Enigma X1 - PCIe to USB-C:
=================
This project contains software and HDL code for the [Enigma X1 board](https://enigma-x1.com/).

Once flashed it may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) or [MemProcFS - The Memory Process File System](https://github.com/ufrisk/MemProcFS/) to perform DMA attacks, dump memory or perform research.


Capabilities:
=================
* Retrieve memory from the target system over USB3/USB-C around 180MB/s.
* Access physical memory of target system unless protected with VT-d/IOMMU.
* Raw PCIe Transaction Layer Packet (TLP) access.

For information about more capabilities check out the general readme and info wiki pages at: [PCILeech](https://github.com/ufrisk/pcileech/), [MemProcFS](https://github.com/ufrisk/MemProcFS/) and [LeechCore](https://github.com/ufrisk/LeechCore/) for information about features and capabilities.

For information about other supported FPGA based devices please check out [PCILeech FPGA](https://github.com/ufrisk/pcileech-fpga/).


The Hardware: Enigma X1
========================
The Enigma x1 PCIe board contains a large Artix7 75T FPGA which allows for good performance and also interesting applications besides PCILeech/MemProcFS. The Enigma x1 may be purchased from: [Smart Hardware Solution / enigma-x1.com](https://enigma-x1.com/). For more information about the hardware please check out [Smart Hardware Solution / enigma-x1.com](https://enigma-x1.com/). Please note that the Enigma x1 is sold by a 3rd party and not by the PCILeech project itself!

The picture below depicts an Enigma x1. The Enigma x1 contains a SuperSpeed USB-C port for data transfer and an update port for easy updating without the need for additional hardware.

When using PCILeech gateware the button will reset the device on press, for full reset hold it 5 seconds. LED1 show the PCIe link status; LED2 will blink 3 times on startup and light up if there are data to read.

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/bb6d57bcb214b7ac0252b0a175885d55cc0438c2/enigmax1.jpg" height=480/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/18b31ebe0823b05744353694ced79a51294057ce/enigmax1-2.jpg" height=480/>


Flashing:
=================
Please note that this instruction applies to the built-in update port. There is a separate JTAG port as well for experienced users.
1) Install Vivado WebPACK or Lab Edition (only for flashing).
2) Build PCILeech Enigma X1 (see below) alternatively download and unzip pre-built binary (see below in releases section).
3) Open Vivado Tcl Shell command prompt.
4) cd into the directory of your unpacked files, or this directory (forward slash instead of backslash in path).
5) Make sure the update port is connected to the computer running Vivado.
6) Run `source vivado_flash.tcl -notrace` to flash the PCILeech bitstream onto the Enigma x1 board.<br>
   Alternatively flash using Xilinx Vivado Hardware Manager (shown below). Please select memory part: `is25lp128f`.
7) Finished !!!

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/a2372c9df7b0aa078f682abfbdf11ab30f4a49ca/enigmax1_flash.png"/>


Building:
=================
1) Install Xilinx Vivado WebPACK 2020.2 or later.
2) Open Vivado Tcl Shell command prompt.
3) cd into the directory of ScreamerM2 (forward slash instead of backslash in path).
4) Run `source vivado_generate_project.tcl -notrace` to generate required project files.
5) Run `source vivado_build.tcl -notrace` to generate Xilinx proprietary IP cores and build bitstream.
6) Finished !!!

Building the project may take a very long time (~1 hour).

The PCIe device will show as Xilinx Ethernet Adapter with Device ID 0x0666 on the target system by default. For instructions how to change the device id and other advanced build properties check out the [build readme](build.md) for information.


Other Notes:
=================
The completed solution contains Xilinx proprietary IP cores licensed under the Xilinx CORE LICENSE AGREEMENT. This project as-is published on Github contains no Xilinx proprietary IP. Published source code are licensed under the MIT License. The end user that have downloaded the no-charge Vivado WebPACK from Xilinx will have the proper licenses and will be able to re-generate Xilinx proprietary IP cores by running the build detailed above.


Support PCILeech/MemProcFS development:
=======================================
**Thank You Smart Hardware Solution / Enigma x1 for supporting the PCILeech project :sparkling_heart:**

Some other hardware sellers have chosen not to support the project! If you think PCILeech and/or MemProcFS is awesome or if you had a use for it it's now possible to support the project via Github Sponsors: [`https://github.com/sponsors/ufrisk`](https://github.com/sponsors/ufrisk).

To all my sponsors, Thank You :sparkling_heart:


Releases / Version History:
=================
v4.10
* Initial Release
* Download pre-built binaries below:
  * [Enigma x1](https://mega.nz/file/FfwyWBoI#SNNV4k-K11Hr39hvrNVNdPGWi4ZBxMPG3wnHftp4MBo) SHA256: `7fbb3891f600443e2b9966d778d6d27363ea4dbca6863bef9ceabdbfb4425a24`
