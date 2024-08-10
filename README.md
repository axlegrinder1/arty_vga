# ARTY VGA project by Alexander Cooke

Based initially on the example vga design from digilent

### Current features:
- Displays test image taken directly from digilent example design
- Modify output resolution up and down by pressing btn0(up) and btn1(down)

### Required hardware:
- Arty A7-35t
- Digilent PMOD VGA (connected to Pmod JB and JC)

### Required software:
- Vivado 2023.2
- [Digilent board files](https://github.com/Digilent/vivado-boards)

### Re-building the project:
1. Run vivado's tcl shell
2. Navigate to arty_vga/vivado
3. Run arty_vga_1.tcl