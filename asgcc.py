from subprocess import Popen, PIPE
from sys import argv

fname = argv[1]
fname_woext = fname.split(".")[0]


cmd_as = Popen(
    [
        "riscv64-unknown-elf-as",
        "-march=rv32i",
        "-mabi=ilp32",
        "-mno-relax",
        fname,
        "-o",
        f"{fname_woext}.elf",
    ],
    stdin=PIPE,
    stdout=PIPE,
    stderr=PIPE,
    shell=True,
)

_, err = cmd_as.communicate(b"")

if err:
    print(err)

cmd_objdump = Popen(
    ["riscv64-unknown-elf-objdump.exe", "-S", f"{fname_woext}.elf"],
    stdin=PIPE,
    stdout=PIPE,
    stderr=PIPE,
    shell=True,
)

code, err = cmd_objdump.communicate(b"")

code = code.decode("utf-8")

print(code)

codet = [
    x.strip() for x in code.split("\n") if "\t" in x
]  # extract lines containing \t
code_hex = [(x.split("\t")[1]).strip() for x in codet]  # extract hex instructions

# currently only outputs .text section, which is a problem:
# we also need to be able to load .data section into MEM

with open(f"{fname_woext}.v", "w+") as f:
    f.write("task LOADMEM;\n")
    f.write("\tbegin\n")
    for i, line in enumerate(code_hex):
        f.write(f"\t\tMEM[{i}] = 32'h{line};\n")
    f.write("\tend\n")
    f.write("endtask\n")
