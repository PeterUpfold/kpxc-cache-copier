BITS 64
global _start

SYS_STAT equ 4
SYS_EXIT equ 60
SYS_MKDIR equ 83
S_IFDIR equ 0x04000
S_IFREG equ 0x10000
STRUCT_STAT_SIZEOF equ 144 ; stat struct is 144 bytes on x86-64 ?

RETURN_NOTDIR 128

section .data
dirname: db "/home/peter/.cache/keepassxc", 0
filename: db "/home/peter/.cache/keepassxc/keepassxc.ini", 0
dir_mode: db 0x1ed ; 755

section .bss
stat_struct: resb STRUCT_STAT_SIZEOF
section .text

;struct stat {
;    dev_t     st_dev;     /* ID of device containing file */
;    ino_t     st_ino;     /* inode number */
;    mode_t    st_mode;    /* protection */
;    nlink_t   st_nlink;   /* number of hard links */
;    uid_t     st_uid;     /* user ID of owner */
;    gid_t     st_gid;     /* group ID of owner */
;    dev_t     st_rdev;    /* device ID (if special file) */
;    off_t     st_size;    /* total size, in bytes */
;    blksize_t st_blksize; /* blocksize for file system I/O */
;    blkcnt_t  st_blocks;  /* number of 512B blocks allocated */
;    time_t    st_atime;   /* time of last access */
;    time_t    st_mtime;   /* time of last modification */
;    time_t    st_ctime;   /* time of last status change */
;};

_start:

	; sys_stat
	; int stat(const char *path, struct stat *buf)
	mov rax,SYS_STAT
	mov rdi,dirname ; const char *path
	mov rsi,stat_struct ; struct stat *buf
	syscall

	; check return code ; TODO -- do we need to ENOEXIST check?? 
	cmp rax,0x0
	jnz exit_with_rax_code

	; check is directory
	; + 25(4?) bytes into structure -- eax because it's a dword
	mov eax,[stat_struct+24]

	; eax now contains the st_mode
	; mask off the S_IFDIR
	and eax,S_IFDIR

	; compare with S_IFDIR
	cmp eax,S_IFDIR
	jnz mk_target_dir

check_file:
	; now check for the file
	mov rax,SYS_STAT
	mov rdi,filename
	mov rsi,stat_struct
	syscall

	; return == 0 ?
	cmp rax,0x0
	jnz exit_with_rax_code

	; TODO look for E_NOEXIST??


	; check is file
	mov eax,[stat_struct+24]

	; mask off S_IFREG
	and eax,S_IFREG

	; compare with S_IFREG
	cmp eax,S_IFREG
	jz normal_exit ; nothing to do -- file exists

copy_file:
	;TODO copy file from source??
		

normal_exit:
	; sys_exit
	mov rax, SYS_EXIT
	xor rdi,rdi ; exit with code 0
	syscall

exit_with_rax_code: ;expects code in rax
	; sys_exit
	mov rdi,rax
	mov rax,SYS_EXIT
	syscall

mk_target_dir:
	mov rax,SYS_MKDIR
	mov rdi,dirname
	mov rsi,dir_mode
	syscall

	cmp rax,0x0
	jnz exit_with_rax_code

	jmp check_file

