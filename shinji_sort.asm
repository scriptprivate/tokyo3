.data
array_size: .word 5        # Number of elements in the array
array:      .space 20      # Allocate space for 5 integers (4 bytes each)
newline:    .asciiz "\n"   # Newline character

.text
.globl main

###############################
# Main Orchestrator Process
# Controls the flow of execution between processes
###############################
main:
    jal process_input_data    # Step 1: Input data process
    jal process_sort_data     # Step 2: Sort data process
    jal process_output_data   # Step 3: Output data process
    j process_exit            # Exit process

###############################
# Process: Input Data
# Reads integers from user input and stores them in array
###############################
process_input_data:
    la $s0, array        # Load base address of array into $s0
    lw $s1, array_size   # Load array size into $s1
    li $t0, 0            # i = 0

process_input_loop:
    bge $t0, $s1, process_input_done    # Exit loop if i >= size
    li $v0, 5                           # Syscall: Read integer
    syscall
    add $t1, $s0, $t0                   # Calculate address: base + offset
    sw $v0, ($t1)                       # Store input into array[i]
    addi $t0, $t0, 4                    # i++
    j process_input_loop

process_input_done:
    jr $ra              # Return to caller

###############################
# Process: Sort Data
# Sorts the array using Selection Sort
###############################
process_sort_data:
    li $t0, 0                                # i = 0 (outer loop counter)

process_sort_outer_loop:
    bge $t0, $s1, process_sort_done          # Exit outer loop if i >= size
    move $t1, $t0                            # min_index = i
    addi $t2, $t0, 4                         # j = i + 1 (inner loop counter)

process_sort_find_min_loop:
    bge $t2, $s1, process_sort_swap          # Exit inner loop if j >= size
    add $t7, $s0, $t2                        # Calculate address for array[j]
    lw $t3, ($t7)                            # Load array[j] into $t3
    add $t7, $s0, $t1                        # Calculate address for array[min_index]
    lw $t4, ($t7)                            # Load array[min_index] into $t4
    blt $t3, $t4, process_sort_update_min    # If array[j] < array[min_index], update min_index
    j process_sort_skip_update

process_sort_update_min:
    move $t1, $t2       # min_index = j

process_sort_skip_update:
    addi $t2, $t2, 4    # j++
    j process_sort_find_min_loop

process_sort_swap:
    beq $t0, $t1, process_sort_next_iter    # If i == min_index, skip swapping
    add $t7, $s0, $t0                       # Calculate address for array[i]
    lw $t5, ($t7)                           # temp = array[i]
    add $t7, $s0, $t1                       # Calculate address for array[min_index]
    lw $t6, ($t7)                           # Load array[min_index]
    add $t7, $s0, $t0                       # Calculate address for array[i]
    sw $t6, ($t7)                           # array[i] = array[min_index]
    add $t7, $s0, $t1                       # Calculate address for array[min_index]
    sw $t5, ($t7)                           # array[min_index] = temp

process_sort_next_iter:
    addi $t0, $t0, 4    # i++
    j process_sort_outer_loop

process_sort_done:
    jr $ra                                  # Return to caller

###############################
# Process: Output Data
# Prints each integer in the array, followed by a newline
###############################
process_output_data:
    la $s0, array        # Load base address of array
    lw $s1, array_size   # Load array size
    li $t0, 0            # i = 0

process_output_loop:
    bge $t0, $s1, process_output_done    # Exit loop if i >= size
    add $t1, $s0, $t0                    # Calculate address for array[i]
    lw $a0, ($t1)                        # Load array[i] into $a0
    li $v0, 1                            # Syscall: Print integer
    syscall
    li $v0, 4                            # Syscall: Print newline
    la $a0, newline
    syscall
    addi $t0, $t0, 4    # i++
    j process_output_loop

process_output_done:
    jr $ra              # Return to caller

###############################
# Process: Exit Program
###############################
process_exit:
    li $v0, 10          # Syscall: Exit program
    syscall
