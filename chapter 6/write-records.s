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

#PURPUSE: This function writes a record to the given
#	  the given file descriptor
#
#INPUT:   The file descriptor and a buffer
#
#OUTPUT:  This function produces a status code
#
#STACK LOCAL VARIABLES
.equ ST_WRITE_BUFFER, 8
.equ ST_FILEDESCRIPTOR, 12
.section .text
.globl write_record
.type write_record,@function
write_record:
pushl %ebp				#Save base pointer	
movl %esp, %ebp				#Set new base pointer

pushl %ebx				#against c calling convention?
movl $SYS_WRITE, %eax
movl ST_FILEDESCRIPTOR(%ebp), %ebx
movl ST_WRITE_BUFFER(%ebp), %ecx
movl $RECORD_SIZE, %edx
int $LINUX_SYSCALL

popl %ebx

movl %ebp, %esp
popl %ebp
ret
#PURPOSE: This function reads a record from the file descriptor
#
#INPUT:	  The file descriptor and a buffer
#
#OUTPUT:  This function writes the data to the buffer 
#	  and returns a status code.
#
#STACK LOCAL VARIABLES
.equ ST_READ_BUFFER, 8
.equ ST_FILEDES, 12
.section .text
.globl read_record
.type read_record, @function

read_record:
pushl %ebp			#Save old base pointer
movl %esp, %ebp			#Reset the base pointer

pushl %ebx			#Save value of %ebx
movl ST_FILEDES(%ebp), %ebx
movl ST_READ_BUFFER(%ebp), %ecx
movl $RECORD_SIZE, %edx		#Defined in record-def.s which 
				#is included
movl $SYS_READ, %eax
int $LINUX_SYSCALL		#execute read command

popl %ebx			#%eax has the return value, which we will
				#give back to our calling programming

movl %ebp, %esp			#Move the stack pointer back
popl %ebp			#Restore previous base pointer
ret

movl $SYS_EXIT, %eax			#Exit the program
movl $0, %ebx
int $LINUX_SYSCALL


# To run:  From the command line (NOTE:  I'm using an x86-64 build so you may need to assebmle differently)
# Takes the file toupper.s, changes all lowercase to uppercase and saves as a new file toupper.uppercase
#			as --32 write-records.s -o write-records.o
#			as --32 write-record.s -o write-record.o
#			ld -melf_i386 write-record.o write-records.o -o write-records
#			./write-records
