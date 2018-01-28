#PURPOSE: This program converts an input file
#	  to an output file with all letters 
#	  converted to uppercase.
#
#Processing: 1) Open the input file
#	     2) Open the output file
#	     3) While we're not at the end of the input file
#		a) read part of file into our memory buffer
#		b) go through each byte of memory
#			if the byte is lowercase letter,
#			convert it to uppercase
#		c) write the memory buffer to output file
.code32
.section .data

########CONSTANTS########

#system call numbers
.equ SYS_OPEN, 5
.equ SYS_WRITE, 4
.equ SYS_READ, 3
.equ SYS_CLOSE, 6
.equ SYS_EXIT, 1

#options for open
.equ O_RDONLY, 0
.equ O_CREAT_WRONLY_TRUNC, 03101

#standard file descriptors
.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

#system call interrupt
.equ LINUX_SYSCALL, 0x80

.equ END_OF_FILE, 0		#return value of read when end of file
.equ NUMBER_ARGUMENTS, 2


.section .bss
#Buffer - Data from input file loaded into, 
#	  converted to uppercase and written
#	  to output file
.equ BUFFER_SIZE, 500
.lcomm BUFFER_DATA, BUFFER_SIZE	#creates buffer called buffer_data
				#with size of 500 bytes.


.section .text

#STACK POSITIONS
.equ ST_SIZE_RESERVE, 8
.equ ST_FD_IN, -4
.equ ST_FD_OUT, -8
.equ ST_ARGC, 0			#number of arguments
.equ ST_ARGV_0, 4		#name of program
.equ ST_ARGV_1, 8		#input file name
.equ ST_ARGV_2, 12		#output file name

.globl _start
_start:

####Initialize program#####
#save stack pointer

movl %esp, %ebp

# allocate space for file descriptors on the stack
subl $ST_SIZE_RESERVE, %esp	#2 words

open_files:
open_fd_in:			#open input file
movl $SYS_OPEN, %eax		#movl 5 to %eax
movl ST_ARGV_1(%ebp), %ebx	#output filename int %ebx
movl $O_RDONLY, %ecx		#set flags
movl $0666, %edx		#mode for new file
int $LINUX_SYSCALL		#call linux

store_fd_in:
movl %eax, ST_FD_IN(%ebp)	#store file descriptor


open_fd_out:
movl $SYS_OPEN, %eax
movl ST_ARGV_2(%ebp), %ebx
movl $O_CREAT_WRONLY_TRUNC, %ecx
movl $0666, %edx
int $LINUX_SYSCALL

store_fd_out:
movl %eax, ST_FD_OUT(%ebp)	#store file descriptor

read_loop_begin:
movl $SYS_READ, %eax		#read in a block from input file
				#movl 3 %eax
movl ST_FD_IN(%ebp), %ebx	#get input file descriptor
movl $BUFFER_DATA, %ecx		#the location to read into
movl $BUFFER_SIZE, %edx		#the size of the buffer
int $LINUX_SYSCALL		#size of buffer read is returned to %eax

#exit if we have reached the end
cmpl $END_OF_FILE, %eax		#check for the end of file marker
				#%eax should be 0
jle end_loop			#if found or on error, go to end
				#found = equal
				#error = negative numbers

continue_read_loop:
#convert the block to uppercase
pushl $BUFFER_DATA		#store location of buffer
pushl %eax			#store size of buffer
call convert_to_upper		#our function that converts to uppercase
popl %eax			#get the size back
addl $4, %esp			#restore stack pointer

#write the block out to the output file
movl %eax, %edx			#buffer size
movl $SYS_WRITE, %eax		#set %eax to 4
movl ST_FD_OUT(%ebp), %ebx	#the filedescriptor of the output file
movl $BUFFER_DATA, %ecx		#location of the buffer
int $LINUX_SYSCALL		#call kernel

#Continue the loop
jmp read_loop_begin


end_loop:
#Close the files
movl $SYS_CLOSE, %eax
movl ST_FD_OUT(%ebp), %ebx	#file descriptor output file
int $LINUX_SYSCALL

movl $SYS_CLOSE, %eax		#we do it again since %eax could be
				#modified by our syscall
movl ST_FD_IN(%ebp), %ebx	#file desciptor input file
int $LINUX_SYSCALL

#exit
movl $SYS_EXIT, %eax		#set %eax to 1
movl $0, %ebx			#return 0 as success value
int $LINUX_SYSCALL



#PURPOSE: This function actually does the conversion 
#	  to uppercase for a block
#
#INPUT:	  First parameter is the location fo the block of
#	  memory to convert
#	  The second parameter is the length of that buffer
#
#OUTPUT:  This function overwrites the current buffer
#	  witht the upper-casified version
#
#VARIABLES:
#	  %eax - beginning of buffer
#	  %ebx - length of buffer
#	  %edi - current buffer offset
#	  %cl - current byte being examined (first part of %ecx)

#CONSTANTS
.equ LOWERCASE_A, 'a'		#lower boundary of our search
.equ LOWERCASE_Z, 'z'		#upper boundary of our search
.equ UPPER_CONVERSION, 'A' - 'a'#Conversion between upper
				#and lower case

#STACK STUFF
.equ ST_BUFFER_LEN, 8		#length of buffer
.equ ST_BUFFER, 12		#actual buffer

convert_to_upper:
pushl %ebp
movl %esp, %ebp

#SET UP VARIABLES
movl ST_BUFFER(%ebp), %eax
movl ST_BUFFER_LEN(%ebp), %ebx
movl $0, %edi

cmpl $0, %ebx			#check if the buffer was zero
je end_convert_loop		#if so, just leave

convert_loop:
movb (%eax,%edi,1), %cl		#get the byte and move it into %cli
				#byte = (beginning of buffer,
				#	 buffer offset - how for are we
				#	 word lenght 1
				#%cl lower end %exc

cmpb $LOWERCASE_A, %cl		#check if the byte is between a
jl next_byte			#and z
cmpb $LOWERCASE_Z, %cl		#if not, go the next byte
jg next_byte

addb $UPPER_CONVERSION, %cl	#otherwise, convert to uppercase
movb %cl, (%eax,%edi,1)		#store it back into buffer

next_byte:
incl %edi			#increment buffer offset with 1
cmpl %edi, %ebx			#continue until we have reached
				#the end
jne convert_loop


end_convert_loop:
movl %ebp, %esp			#no return value, just leave
popl %ebp
ret


# To run:  From the command line (NOTE:  I'm using an x86-64 build so you may need to assebmle differently)
# Takes the file toupper.s, changes all lowercase to uppercase and saves as a new file toupper.uppercase
#			as --32 toupper.s -o toupper.o
#			ld -melf_i386 toupper.o -o toupper
#			./toupper toupper.s toupper.uppercase     
