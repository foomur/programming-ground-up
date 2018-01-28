.include "record-def.s"
.include "linux.s"

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
