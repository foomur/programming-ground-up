.include "linux.s"
.include "record-def.s"
.code32
.section .data
input_file_name:
.ascii "test.dat\0"

output_file_name:
.ascii "testout.dat\0"

.section .bss
.lcomm record_buffer, RECORD_SIZE

#Stack offsets of local variables
.equ ST_INPUT_DESCRIPTOR, -4
.equ ST_OUTPUT_DESCRIPTOR, -8

.section .text
.globl _start
_start:
movl %esp, %ebp
subl $8, %ebp

#Open input file
movl $SYS_OPEN, %eax
movl $input_file_name, %ebx
movl $0, %ecx
movl $0666, %edx
int $LINUX_SYSCALL

movl %eax, ST_INPUT_DESCRIPTOR(%ebp)

#Error checking, neg numbers are error codes
cmpl $0, %eax
jg continue_processing

#Send the error
.section .data
no_open_file_code:
.ascii "0001: \0"
no_open_file_msg:
.ascii "Can't open input file\0"

.section .text
pushl $no_open_file_msg
pushl $no_open_file_code
call error_exit

continue_processing:


#Open file for writing
movl $SYS_OPEN, %eax
movl $output_file_name, %ebx
movl $0101, %ecx
movl $0666, %edx
int $LINUX_SYSCALL

movl %eax, ST_OUTPUT_DESCRIPTOR(%ebp)


loop_begin:
pushl ST_INPUT_DESCRIPTOR(%ebp)
pushl $record_buffer
call read_record
addl $8, %esp

#Returns the number of bytes read.
#Check for end of file or zero.
cmpl $RECORD_SIZE, %eax
jne loop_end

#Increment the age
incl record_buffer + RECORD_AGE

#Write the record out
pushl ST_OUTPUT_DESCRIPTOR(%ebp)
pushl $record_buffer
call write_record
addl $8, %esp

jmp loop_begin


loop_end:
movl $SYS_EXIT, %eax
movl $0, %ebx
int $LINUX_SYSCALL

# To run, from the command line (note:  I'm using x86-64)
#     as --32 add-year.s -o add-year.o
#     ld -melf_i386 add-year.o read-record.o write-record.o -o add-year
#     ./add-year
