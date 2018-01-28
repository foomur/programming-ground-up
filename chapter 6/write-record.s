.include "linux.s"
.include "record-def.s"

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
