.include "linux.s"
.include "record-def.s"

.code32

.section .data

#Constant data of the records we want to write
#Each text data item is padded to the proper
#length with null (i.e. 0) bytes.

#.rept is used to pad each item. .rept tells
#the assembler to repeat the section between
#.rept and .endr the number of times specified.
#This is used in this program to add extra null
#characters at the end of each field to fill
#it up
record1:
.ascii "Frederick\0"
.rept 31				#Padding to 40 bytes
.byte 0
.endr

.ascii "Barlett\0"
.rept 31
.byte 0
.endr

.ascii "4242 S Prairie\nTulsa, OK 55555\0"
.rept 209
.byte 0
.endr

.long 45

record2:
.ascii "Marilyn\0"
.rept 32
.byte 0
.endr

.ascii "Taylor\0"
.rept 33
.byte 0
.endr

.ascii "2224 S Johannan St\nChicago, IL 12345\0"
.rept 203
.byte 0
.endr

.long 29

record3:
.ascii "Derrick\0"
.rept 32
.byte 0
.endr

.ascii "McIntire\0"
.rept 31
.byte 0
.endr

.ascii "500 W Oakland\nSan Diego, CA 54321\0"
.rept 206
.byte 0
.endr

.long 36

file_name:
.ascii "test.dat\0"			#The name of the file we will write to
.equ ST_FILE_DESCRIPTOR, -4
.globl _start
_start:
movl %esp, %ebp				#Copy the stack pointer to the
					#base pointer
subl $4, %esp				#Reserve space for file desciptor

movl $SYS_OPEN, %eax			#Open the file
movl $file_name, %ebx
movl $0101, %ecx			#Open if doesn't exit, open to write
movl $0666, %edx			#File permissions
int $LINUX_SYSCALL

movl %eax, ST_FILE_DESCRIPTOR(%ebp)	#Store file desciptor as local var

pushl ST_FILE_DESCRIPTOR(%ebp)		#Write first record
pushl $record1				#This is a pointer to the data
call write_record
addl $8, %esp

pushl ST_FILE_DESCRIPTOR(%ebp)		#Write second record
pushl $record2
call write_record
addl $8, %esp

pushl ST_FILE_DESCRIPTOR(%ebp)		#Write third record
pushl $record3
call write_record
addl $8, %esp

movl $SYS_CLOSE, %eax			#Close file descriptor
movl ST_FILE_DESCRIPTOR(%ebp), %ebx
int $LINUX_SYSCALL

movl $SYS_EXIT, %eax			#Exit the program
movl $0, %ebx
int $LINUX_SYSCALL
