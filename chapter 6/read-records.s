.include "linux.s"
.include "record-def.s"
.code32
.section .data
file_name:
.ascii "test.dat\0"

record_buffer_ptr:
.long 0


.section .text
.globl _start
_start:
.equ ST_INPUT_DESCRIPTOR, -4
.equ ST_OUTPUT_DESCRIPTOR, -8

call allocate_init				#Initalize memory manager
pushl $RECORD_SIZE
call allocate
movl %eax, record_buffer_ptr

movl %esp, %ebp
subl $8, %esp					#Make room for local vars

movl $SYS_OPEN, %eax				#Open the file
movl $file_name, %ebx
movl $0, %ecx					#Open read-only
movl $0666, %edx
int $LINUX_SYSCALL

movl %eax, ST_INPUT_DESCRIPTOR(%ebp)		#Save file descriptor

movl $STDOUT, ST_OUTPUT_DESCRIPTOR(%ebp)	#Save output file descriptor
						#makes it easy to change to diff file

record_read_loop:
pushl ST_INPUT_DESCRIPTOR(%ebp)
pushl record_buffer_ptr				#Pass the pointer to our memory
call read_record
addl $8, %esp

cmpl $RECORD_SIZE, %eax				#returns number of bytes read
jne finished_reading 				#if it's not the same number as requested
						#its and end of file or error, so quit
						#print out first name, first know its size
movl record_buffer_ptr, %eax
addl $RECORD_FIRSTNAME, %eax
pushl %eax
call count_chars
addl $4, %esp
movl %eax, %edx
movl ST_OUTPUT_DESCRIPTOR(%ebp), %ebx
movl $SYS_WRITE, %eax
movl record_buffer_ptr, %ecx
addl $RECORD_FIRSTNAME, %ecx
int $LINUX_SYSCALL

push ST_OUTPUT_DESCRIPTOR(%ebp)
call write_newline
addl $4, %esp

jmp record_read_loop

finished_reading:
pushl record_buffer_ptr
call deallocate
movl $SYS_EXIT, %eax
movl $0, %ebx
int $LINUX_SYSCALL


# To run: (NOTE: I'm using x86-64 so yours may be different)

# as --32 read-record.s -o read-record.o
# as --32 count-chars.s -o count-chars.o
# as --32 write-newline.s -o write-newline.o
# as --32 read-records.s -o read-records.o
# ld -melf_i386 read-record.o count-chars.o write-newline.o \
# read-records.o -o read-records
# ./read-records
