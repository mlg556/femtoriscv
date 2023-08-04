@echo off 

riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -mno-relax %1.S -o %1.elf && riscv64-unknown-elf-objdump.exe -S %1.elf