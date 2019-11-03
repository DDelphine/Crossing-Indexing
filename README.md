# Crossing-Indexing

test.c and func.c are source code files, func.c defines a function which is called in test.c

test is the compiled file of test.c and func.c

ASSEMBLY is the output of 'objdump -d test'

DWARF is the output of 'llvm-dwarfdump --debug-line test'

main.rb is the code for analyzing the ASSEMBLY and DWARF


