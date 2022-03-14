kpxc-cache-copier: kpxc-cache-copier.S
	nasm -felf64 kpxc-cache-copier.S
	ld kpxc-cache-copier.o -o kpxc-cache-copier
