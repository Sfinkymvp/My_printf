OBJ_DIR = obj
SRC_DIR = source

FILES = $(OBJ_DIR)/my_printf.o $(OBJ_DIR)/main.o

compile: $(FILES)
	@gcc -no-pie $(FILES) -o program.out

$(OBJ_DIR)/main.o:
	@mkdir -p obj
	@gcc -c $(SRC_DIR)/main.c -o $(OBJ_DIR)/main.o

$(OBJ_DIR)/my_printf.o:
	@mkdir -p obj
	@nasm -f elf64 $(SRC_DIR)/my_printf.asm -o $(OBJ_DIR)/my_printf.o

run:
	@./program.out

all: clean compile run

clean:
	@rm -rf obj
	@rm -rf program.out
