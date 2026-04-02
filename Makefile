OBJ_DIR = obj
SRC_DIR = source

C_CASE_FILES = $(OBJ_DIR)/my_printf.o $(OBJ_DIR)/c_main.o
ASM_CASE_FILES = $(OBJ_DIR)/my_printf.o $(OBJ_DIR)/asm_main.o

c_case: $(C_CASE_FILES)
	@gcc -fPIE $(C_CASE_FILES) -o program_c.out

asm_case: $(ASM_CASE_FILES)
	@gcc -fPIE $(ASM_CASE_FILES) -o program_asm.out

$(OBJ_DIR)/asm_main.o:
	@mkdir -p obj
	@nasm -f elf64 $(SRC_DIR)/asm_main.asm -o $(OBJ_DIR)/asm_main.o

$(OBJ_DIR)/c_main.o:
	@mkdir -p obj
	@gcc -fPIE -c $(SRC_DIR)/c_main.c -o $(OBJ_DIR)/c_main.o

$(OBJ_DIR)/my_printf.o:
	@mkdir -p obj
	@nasm -f elf64 $(SRC_DIR)/my_printf.asm -o $(OBJ_DIR)/my_printf.o

run_c:
	@./program_c.out

run_asm:
	@./program_asm.out

all_c: clean c_case run_c

all_asm: clean asm_case run_asm

all_all: clean c_case asm_case
	@echo "Calling functions from c:"
	@./program_c.out

	@echo "\nCalling functions from nasm:"
	@./program_asm.out

clean:
	@rm -rf obj
	@rm -rf program_c.out
	@rm -rf program_asm.out
