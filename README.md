# FPGA Cosmic Radiation Sensor (AICoRS)

This repository contains all materials related to the development of a cosmic radiation sensor board based on a Field-Programmable Gate Array (FPGA), as part of the project:

**"Artificial Intelligence-enabled Hardware Cosmic Radiation Sensor for Space Applications (AICoRS)"**  
PN-IV-P8-8.3-ROMD-2023-0068, in partnership between Transilvania University of Brașov and the Technical University of Moldova.

---

## Abstract

In the terrestrial space environment, radiation from Galactic Cosmic Rays (GCR), solar events, and trapped particles in the Earth's magnetosphere can interact with electronic circuits and cause **Single Event Effects (SEE)**, such as **Single Event Upsets (SEU)** and **Single Event Transients (SET)**. These effects pose significant challenges for high-performance and critical space systems, requiring dedicated detection methods and mitigation strategies.

This project presents the **design, implementation, and validation** of an FPGA-based cosmic radiation sensor board. The work includes:  

- FPGA device selection optimized for space applications  
- Hardware Description Language (HDL) development for SEU detection and communication  
- Printed Circuit Board (PCB) design for nanosatellite integration  
- Testing and validation of all components  
- Theoretical analysis of the space radiation environment and conversion of physical radiation parameters to memory bit change rates  

The developed sensor board has successfully passed validation and will be integrated with two other radiation detectors and a local On-Board Computer (OBC) as a Moldovan payload in the 3U **BIRDS-RPM** nanosatellite, scheduled for launch into **Low Earth Orbit (LEO)** via a resupply mission to the **International Space Station (ISS)** by **JAXA**.

---

## Repository Structure
FPGA_Cosmic_Radiation_Sensor<br>
├─ Arduino Test projects       --- Arduino experiments and test code <br>
├─ Kicad PCB projects          --- PCB designs for sensor board <br>
├─ Thesis latex project        --- Full thesis LaTeX source <br>
├─ Thesis latex template       --- Custom LaTeX template for IESC faculty <br>
├─ Verilog parts test projects --- Test benches and simulation projects for various subsystems <br>
├─ Verilog source code - V7.10 --- Full latest FPGA HDL source code for SEU detection <br>
├─ .gitignore                  --- Git ignore for Vivado, KiCdas, Latex and generated files <br>
├─ LICENSE                     --- CC BY-NC 4.0 license <br>
├─ LICENTA_Final.pdf           --- Final compiled thesis PDF <br>
├─ README.md                   --- This file <br>


---

## License

This work is licensed under a **[Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0)](https://creativecommons.org/licenses/by-nc/4.0/)**.  

You are free to **share** and **adapt** the content for **non-commercial purposes**, with proper attribution to the author.

---

## Publications

The work conducted in this project has led to several scientific publications covering different stages, results, and aspects of the system development:

1. **Preliminary SEU Detection Algorithm**  
S. Popa, A. Kazak, A. Dinu et al., *“Architecture and Design Choices for an AI-enabled FPGA-based Cosmic Radiation Sensor,”* in 2024 International Symposium on Electronics and Telecommunications (ISETC), 2024, pp. 1–4.  
DOI: [10.1109/ISETC63109.2024.10797366](https://doi.org/10.1109/ISETC63109.2024.10797366)

2. **BIRDS Project Architecture & FPGA Sensor Comparison**  
N. Secrieru, V. Carbune, T. Zadorojneac et al., *“ARCHITECTURE OF THE SPACE RADIATION SENSOR SATELLITE MODULE BASED ON ARTIFICIAL INTELLIGENCE,”* JOURNAL OF ENGINEERING SCIENCE, vol. 31, nr. 4, pp. 73–83, Jan. 2025.  
DOI: [10.52326/jes.utm.2024.31(4).05](https://press.utm.md/index.php/jes/article/view/2024-31-4-05)

3. **FPGA-Based Radiation Sensor PCB Design**  
A. Bertescu and S. Popa, *“The Design and Implementation of an FPGA-Based Cosmic Radiation Sensor PCB,”* in 2025 18th International Conference on Engineering of Modern Electric Systems (EMES), 2025, pp. 1–4.  
DOI: [10.1109/EMES65692.2025.11045622](https://doi.org/10.1109/EMES65692.2025.11045622)

4. **Power and Cross-Section Optimization for FPGA Sensor**  
S. Popa, A. Bertescu, C. Furtună et al., *“Power and Cross-Section Optimization for an FPGA-Based Cosmic Radiation Sensor,”* in 2025 32nd IEEE International Conference on Electronics, Circuits and Systems (ICECS), 2025, pp. 1–4.

---

## Photos
![Photo no longer available]("/Kicad PCB projects/Rev_3.2/PCB_photos/JLCPCB_photos/Final_changes.png")
