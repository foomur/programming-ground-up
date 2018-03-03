#PURPOSE: Count the characters until a null byte is reached.
#
#INPUT:   The address of the character string
#
#OUTPUT: Returns the count in %eax
#
#PROCESS:
#  Registers used:
#	%ecx - chararcter count
#	%al - current character
#	%edx - current character address
.code32
.type count_chars, @function
.globl count_chars

.equ ST_STRING_START_ADDRESS, 8
count_chars:
pushl %ebp
movl %esp, %ebp

movl $0, %ecx					#Counter starts at 0
movl ST_STRING_START_ADDRESS(%ebp), %edx

count_loop_begin:
movb (%edx), %al
cmpb $0, %al					#Current char zero?
je count_loop_end				#If yes, we're done
incl %ecx					#If no, increment counter
incl %edx					
jmp count_loop_begin				#Loop again

count_loop_end:
movl %ecx, %eax					#Return our value

popl %ebp
ret
