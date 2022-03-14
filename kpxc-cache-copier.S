BITS 64
global _start

SYS_EXIT equ 60

section .text

_start:

	; sys_exit
	mov rax, SYS_EXIT
	xor rdi,rdi
	syscall	
