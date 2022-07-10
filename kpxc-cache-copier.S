BITS 64
global _start

SYS_STAT equ 4
SYS_EXIT equ 60
SYS_MKDIR equ 83
SYS_OPEN equ 2
SYS_CLOSE equ 3
SYS_SENDFILE equ 40
S_IFDIR equ 0x04000
S_IFREG equ 0x10000
O_CREAT equ 0x0040
O_WRONLY equ 0x0001
O_CREAT_WRONLY equ 0x0041
STRUCT_STAT_SIZEOF equ 144 ; stat struct is 144 bytes on x86-64 ?
FILEMODE_0600 equ 0x180
DIRMODE_0700 equ 0x1c0

BYTES_TO_COPY equ 1502
ENOENT equ -2

RETURN_NOTDIR equ 128

section .data
dirname: db "/home/peter/.cache/keepassxc", 0
filename: db "/home/peter/.cache/keepassxc/keepassxc.ini", 0
source_filename: db "/home/peter/.config/keepassxc-cache.ini", 0

section .bss
stat_struct: resb STRUCT_STAT_SIZEOF
source_fd: resb 4
dest_fd: resb 4

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

	; check return code 
	cmp rax,ENOENT
	jz mk_target_dir

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

	; look for ENOENT
	cmp rax,ENOENT
 	jz copy_file ; not existing is fine -- we will create it

	; return == 0 ?
	cmp rax,0x0
	jnz exit_with_rax_code

	; TODO check_file not returnign what we expect -- we are always creating it
	; check is file
	mov eax,[stat_struct+24]

	; mask off S_IFREG
	and eax,S_IFREG

	; compare with S_IFREG
	cmp eax,S_IFREG
	jz normal_exit ; nothing to do -- file exists

copy_file:
	; possible process:

	; open file descriptor for old
	mov rax,SYS_OPEN
	mov rdi,source_filename
	mov rsi,0 ; flags
	mov rdx,0 ; mode
	syscall

	; return == -1
	cmp rax,-1
	jz exit_with_rax_code

	mov [source_fd],rax

	; open file descriptor for new
	mov rax,SYS_OPEN
	mov rdi,filename
	mov rsi,O_CREAT_WRONLY ; flags
	mov rdx,FILEMODE_0600 ; mode
	syscall

	; return == -1
	cmp rax,-1
	jz exit_with_rax_code

	mov [dest_fd],rax


	; sendfile(out, in, 0, size)
	mov rax,SYS_SENDFILE
	mov rdi,[dest_fd]
	mov rsi,[source_fd]
	mov rdx, 0 ;offset
	mov r10, BYTES_TO_COPY ; count
	syscall

	cmp rax,-1
	jz exit_with_rax_code ;note -- technically doesn't tidy up in the non-happy path


	; close dest


	; close source

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
	mov rsi,DIRMODE_0700
	syscall

	cmp rax,0x0
	jnz exit_with_rax_code

	jmp check_file

