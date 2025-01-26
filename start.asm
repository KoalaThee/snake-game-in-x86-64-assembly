.section .bss
    .lcomm snake_length, 8    # Reserve 8 bytes for snake_length (64-bit)
    .lcomm n_apples, 8        # Reserve 8 bytes for n_apples (64-bit)
    .lcomm buffer, 32         # Temporary buffer for string storage (32 bytes)

.section .text
.global _start

_start:
    # Ensure that there are at least 3 arguments (program name, snake_length, n_apples)
    movq (%rsp), %rdi
    cmpq $3, %rdi              # argc is in %rdi (check if argc < 3)
    jl error_exit              # If less than 3 arguments, exit with error
    leaq 8(%rsp), %rsi
    # Align the stack before function calls (stack must be 16-byte aligned)
    subq $8, %rsp              # Align the stack by subtracting 8 bytes

    # Load argv[1] (snake_length as string "10")
    movq 8(%rsi), %rdi         # argv[1] is at 8(%rsi)
    call str_to_int            # Convert string to integer

    movq %rax, snake_length    # Store the result in snake_length (use qword for 64-bit)

    # Load argv[2] (n_apples as string "3")
    movq 16(%rsi), %rdi        # argv[2] is at 16(%rsi)
    call str_to_int            # Convert string to integer

    movq %rax, n_apples        # Store the result in n_apples (use qword for 64-bit)

    # Restore the stack pointer after function calls
    addq $8, %rsp              # Restore stack pointer (undo alignment adjustment)

    movq snake_length, %rdi
    movq n_apples, %rsi

    # Call start_game function (defined elsewhere)
    call start_game

    # Exit the program
    movq $60, %rax             # syscall number for exit (sys_exit)
    xorq %rdi, %rdi            # Return code 0 (success)
    syscall

error_exit:
    movq $60, %rax             # syscall number for exit
    movq $1, %rdi              # Return code 1 (error)
    syscall

# Helper function to convert string to integer (ASCII to integer)
str_to_int:
    xorq %rax, %rax            # Clear rax (result accumulator)
    xorq %rcx, %rcx            # Clear rcx (loop counter)

convert_loop:
    movzbl (%rdi, %rcx), %edx  # Load a byte from the string (zero-extend into rdx)
    testb %dl, %dl             # Check if byte is null (end of string)
    jz done_convert            # If null terminator, jump to done

    subb $'0', %dl             # Convert ASCII character to integer ('0' -> 0, etc.)
    imulq $10, %rax            # Multiply the current result by 10 (for next digit)
    addq %rdx, %rax            # Add the current digit to rax (result)

    incq %rcx                  # Move to the next character in the string
    jmp convert_loop           # Repeat the loop

done_convert:
    ret                        # Return with the result in rax
