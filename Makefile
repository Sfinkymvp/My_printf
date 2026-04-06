MAKEFLAGS += --no-print-directory

OBJ_DIR = obj
BIN_DIR = bin
SRC_DIR = source

C_CASE_FILES = $(OBJ_DIR)/my_printf.o $(OBJ_DIR)/c_main.o
ASM_CASE_FILES = $(OBJ_DIR)/my_printf.o $(OBJ_DIR)/asm_main.o

build_c: $(BIN_DIR) $(C_CASE_FILES)
	@gcc -fPIE $(C_CASE_FILES) -o $(BIN_DIR)/program_c.out
	@$(MAKE) run_c

build_asm: $(BIN_DIR) $(ASM_CASE_FILES)
	@gcc -fPIE $(ASM_CASE_FILES) -o $(BIN_DIR)/program_asm.out
	@$(MAKE) run_asm

$(OBJ_DIR)/asm_main.o: $(OBJ_DIR)
	@nasm -f elf64 $(SRC_DIR)/asm_main.asm -o $(OBJ_DIR)/asm_main.o

$(OBJ_DIR)/c_main.o: $(OBJ_DIR)
	@gcc -fPIE -c $(SRC_DIR)/c_main.c -o $(OBJ_DIR)/c_main.o

$(OBJ_DIR)/my_printf.o: $(OBJ_DIR)
	@nasm -f elf64 $(SRC_DIR)/my_printf.asm -o $(OBJ_DIR)/my_printf.o

$(OBJ_DIR):
	@mkdir -p $(OBJ_DIR)

$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

run_c:
	@./$(BIN_DIR)/program_c.out

run_asm:
	@./%(BIN_DIR)/program_asm.out

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
