BITS 64
global _start

SYS_STAT equ 4
SYS_EXIT equ 60

section .data
filename: db 'test\0'

section .text

_start:

	; sys_stat
	; int stat(const char *path, struct stat *buf)
	mov rax, SYS_STAT
	mov rdi,filename ; const char *path
	xor rsi,rsi ; 0 for now
	syscall

	; sys_exit
	mov rax, SYS_EXIT
	xor rdi,rdi ; exit with code 0
	syscall
