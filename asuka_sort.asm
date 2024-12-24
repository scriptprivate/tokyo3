.data
array_size:      .word 5        # Number of elements in the array
array:           .space 20      # Allocate space for 5 integers (4 bytes each)
min_run:         .word 32       # Minimum run length for Timsort
temp_array:      .space 20      # Temporary array for merging
newline:         .asciiz "\n"   # Newline character

.text
.globl main

###############################
# Main Orchestrator Process
# Controls the flow of execution between processes
###############################
main:
    jal process_input_data     # Step 1: Input data process
    jal process_timsort        # Step 2: Timsort process
    jal process_output_data    # Step 3: Output data process
    j process_exit             # Exit process

###############################
# Process: Input Data
# Reads integers from user input and stores them in array
###############################
process_input_data:
    la $s0, array        # Load base address of array
    lw $s1, array_size   # Load array size
    li $t0, 0            # i = 0
    sll $s2, $s1, 2      # Convert size to bytes (size * 4)

input_loop:
    bge $t0, $s2, input_done    # Exit loop if i >= size in bytes
    li $v0, 5                   # Syscall: Read integer
    syscall
    add $t1, $s0, $t0           # Calculate address: base + offset
    sw $v0, ($t1)               # Store input into array[i]
    addi $t0, $t0, 4            # i++ (in bytes)
    j input_loop

input_done:
    jr $ra                     # Return to caller

###############################
# Process: Timsort
# Implements the Timsort algorithm
###############################
process_timsort:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, ($sp)

    # First step: Find runs and sort them using insertion sort
    jal process_find_runs

    # Second step: Merge runs
    jal process_merge_runs

    # Restore return address and return
    lw $ra, ($sp)
    addi $sp, $sp, 4
    jr $ra

###############################
# Process: Find Runs
# Identifies natural runs and extends them to min_run length
###############################
process_find_runs:
    la $s0, array            # Load base address of array
    lw $s1, array_size       # Load array size
    li $t0, 0                # Current position

find_runs_loop:
    bge $t0, $s1, find_runs_done
    
    # Find the length of current run
    move $a0, $t0           # Start position
    jal process_get_run_length
    
    # If run length < min_run, extend it
    lw $t2, min_run
    bge $v0, $t2, find_runs_next
    
    # Sort the extended run using insertion sort
    move $a0, $t0           # Start of run
    add $a1, $t0, $v0       # End of run
    jal process_insertion_sort

find_runs_next:
    add $t0, $t0, $v0       # Move to next run
    j find_runs_loop

find_runs_done:
    jr $ra

###############################
# Process: Get Run Length
# Returns the length of a natural run starting at given position
###############################
process_get_run_length:
    li $v0, 1               # Minimum run length is 1
    move $t1, $a0           # Current position
    addi $t2, $t1, 1        # Next position
    
    # Check if we've reached the end of array
    bge $t2, $s1, get_run_length_done
    
    # Load current and next elements
    sll $t3, $t1, 2
    add $t3, $s0, $t3
    lw $t4, ($t3)          # Current element
    
    sll $t3, $t2, 2
    add $t3, $s0, $t3
    lw $t5, ($t3)          # Next element
    
    # Compare and extend run
    bgt $t4, $t5, get_run_length_descending
    
get_run_length_ascending:
    bge $t2, $s1, get_run_length_done
    sll $t3, $t2, 2
    add $t3, $s0, $t3
    lw $t5, ($t3)
    addi $t2, $t2, 1
    addi $v0, $v0, 1
    j get_run_length_ascending

get_run_length_descending:
    bge $t2, $s1, get_run_length_done
    sll $t3, $t2, 2
    add $t3, $s0, $t3
    lw $t5, ($t3)
    addi $t2, $t2, 1
    addi $v0, $v0, 1
    j get_run_length_descending

get_run_length_done:
    jr $ra

###############################
# Process: Insertion Sort
# Sorts a run using insertion sort
###############################
process_insertion_sort:
    move $t0, $a0           # Start index
    move $t1, $a1           # End index
    
insertion_sort_outer:
    bge $t0, $t1, insertion_sort_done
    
    # Get current element
    sll $t2, $t0, 2
    add $t2, $s0, $t2
    lw $t3, ($t2)          # Current element
    
    # Inner loop
    move $t4, $t0          # j = i
    
insertion_sort_inner:
    ble $t4, $a0, insertion_sort_inner_done
    
    # Compare with previous element
    addi $t5, $t4, -1
    sll $t6, $t5, 2
    add $t6, $s0, $t6
    lw $t7, ($t6)
    
    ble $t7, $t3, insertion_sort_inner_done
    
    # Swap elements
    sll $t8, $t4, 2
    add $t8, $s0, $t8
    sw $t7, ($t8)
    
    addi $t4, $t4, -1
    j insertion_sort_inner
    
insertion_sort_inner_done:
    sll $t8, $t4, 2
    add $t8, $s0, $t8
    sw $t3, ($t8)
    
    addi $t0, $t0, 1
    j insertion_sort_outer
    
insertion_sort_done:
    jr $ra

###############################
# Process: Merge Runs
# Merges sorted runs using temporary array
###############################
process_merge_runs:
    la $s3, temp_array     # Load address of temporary array
    
    # Initialize merge parameters
    li $t0, 0              # Left run start
    lw $t1, array_size
    srl $t1, $t1, 1        # Middle (right run start)
    lw $t2, array_size     # Right run end
    
    # Merge the runs
    move $a0, $t0          # Left start
    move $a1, $t1          # Left end/Right start
    move $a2, $t2          # Right end
    jal process_merge
    
    jr $ra

###############################
# Process: Merge
# Merges two adjacent sorted runs
###############################
process_merge:
    # Save parameters
    move $t0, $a0          # Left start
    move $t1, $a1          # Left end/Right start
    move $t2, $a2          # Right end
    
    # Copy to temp array
    move $t3, $t0          # Source index
    li $t4, 0              # Temp array index
    
merge_copy:
    bge $t3, $t2, merge_copy_done
    sll $t5, $t3, 2
    add $t5, $s0, $t5
    lw $t6, ($t5)
    
    sll $t5, $t4, 2
    add $t5, $s3, $t5
    sw $t6, ($t5)
    
    addi $t3, $t3, 1
    addi $t4, $t4, 1
    j merge_copy
    
merge_copy_done:
    # Merge back to original array
    move $t3, $t0          # Target index in original array
    li $t4, 0              # Left run index in temp
    sub $t5, $t1, $t0      # Right run index in temp
    
merge_runs:
    bge $t4, $t1, merge_copy_remaining_right
    bge $t5, $t2, merge_copy_remaining_left
    
    # Compare elements
    sll $t6, $t4, 2
    add $t6, $s3, $t6
    lw $t7, ($t6)
    
    sll $t6, $t5, 2
    add $t6, $s3, $t6
    lw $t8, ($t6)
    
    bgt $t7, $t8, merge_copy_right
    
merge_copy_left:
    sll $t6, $t3, 2
    add $t6, $s0, $t6
    sw $t7, ($t6)
    addi $t4, $t4, 1
    addi $t3, $t3, 1
    j merge_runs
    
merge_copy_right:
    sll $t6, $t3, 2
    add $t6, $s0, $t6
    sw $t8, ($t6)
    addi $t5, $t5, 1
    addi $t3, $t3, 1
    j merge_runs
    
merge_copy_remaining_left:
    bge $t4, $t1, merge_done
    sll $t6, $t4, 2
    add $t6, $s3, $t6
    lw $t7, ($t6)
    sll $t6, $t3, 2
    add $t6, $s0, $t6
    sw $t7, ($t6)
    addi $t4, $t4, 1
    addi $t3, $t3, 1
    j merge_copy_remaining_left
    
merge_copy_remaining_right:
    bge $t5, $t2, merge_done
    sll $t6, $t5, 2
    add $t6, $s3, $t6
    lw $t7, ($t6)
    sll $t6, $t3, 2
    add $t6, $s0, $t6
    sw $t7, ($t6)
    addi $t5, $t5, 1
    addi $t3, $t3, 1
    j merge_copy_remaining_right
    
merge_done:
    jr $ra

###############################
# Process: Output Data
# Prints each integer in the array, followed by a newline
###############################
process_output_data:
    la $s0, array         # Load base address of array
    lw $s1, array_size    # Load array size
    li $t0, 0             # i = 0
    sll $s2, $s1, 2       # Convert size to bytes (size * 4)

output_loop:
    bge $t0, $s2, output_done    # Exit loop if i >= size in bytes
    add $t1, $s0, $t0            # Calculate address for array[i]
    lw $a0, ($t1)                # Load array[i] into $a0
    li $v0, 1                    # Syscall: Print integer
    syscall
    li $v0, 4                    # Syscall: Print newline
    la $a0, newline
    syscall
    addi $t0, $t0, 4             # i++ (in bytes)
    j output_loop

output_done:
    jr $ra                       # Return to caller

###############################
# Process: Exit Program
###############################
process_exit:
    li $v0, 10                  # Syscall: Exit program
    syscall
