.text
.global main
main:

/* _____FROM_SCRATCH-START_____ */
0:
	xorl	%eax,	%eax
	xorl	%ebx,	%ebx
	xorl	%ecx,	%ecx
	xorl	%edx,	%edx
	xorl	%edi,	%edi
	xorl	%esi,	%esi
/* _____FROM_SCRATCH-END_____ */


/* _____GETENV_PATH-START_____ */
	pushl	$s_path
	call	getenv
	addl	$4,		%esp
	
	pushl	%eax
	call	strdup
	addl	$4,		%esp
	movl	%eax,	b_path
/* _____GETENV_PATH-END_____ */


/* _____PROMPT-GETLINE-START_____ */
	pushl	$prompt
	call	printf
	addl	$4,		%esp
	
	movl	$0,		cmd_in
	movl	$0,		n
	
	movl	stdin, 	%eax
	pushl	%eax
	pushl	$n
	pushl	$cmd_in
	call	getline
	addl	$12, 	%esp
/* _____PROMPT-GETLINE-END_____ */


/* _____CHECK_NULL_INPUT-START_____ */
	movl	cmd_in,		%ebx
	movb	(%ebx),		%al
	cmpb	$0xa,		%al
	jz		0b
	
	movl	cmd_in,		%ebx
	movb	(%ebx),		%al
	movl	$1,		%ecx
	
1:
	cmpb	$0xa,			%al
	jz		0b
	cmpb	$0x20,			%al
	jnz		2f
	movb	(%ebx, %ecx),	%al
	incl	%ecx
	jmp		1b
/* _____CHECK_NULL_INPUT-END_____ */


/* _____ALLOC_MEM (CMD) START_____ */
2:
	movl	$500,	%ebx
	pushl	%ebx
	call	malloc
	addl	$4,		%esp
	movl	%eax,	cmd
/* _____ALLOC_MEM (CMD) END_____ */


/* _____CLEAR_WHITESPACES-START_____ */
	movl	cmd_in,		%edi
3:
	pushl	$delim1
	pushl	%edi
	call	strtok
	addl	$8,		%esp
	
	test	%eax,	%eax
	jz		4f
	
	movl	%eax,	%esi
	movl	%edx,	%edi
	
	pushl	%esi
	pushl	cmd
	call	strcat
	addl	$8,		%esp
	
	cmpl	$0,		(%edi)
	jz		4f
	
	pushl	$delim1
	pushl	cmd
	call	strcat
	addl	$8,		%esp
	
	jmp		3b
	
4:
	pushl	$enter
	pushl	cmd
	call	strtok
	addl	$8,		%esp
/* _____CLEAR_WHITESPACES-START_____ */


/* _____CHECK_EXIT-START_____ */
	pushl	cmd
	call	strdup
	addl	$4,		%esp
	movl	%eax,	cmd_cpy
	
	pushl	$delim1
	pushl	cmd_cpy
	call	strtok
	addl	$8,		%esp
	movl	%eax,	%edi
	
	pushl	%eax
	call	strlen
	addl	$4,		%esp
	
	cmpl	$4,		%eax
	jnz		5f
	
	cmpl	$0x74697865,	(%edi)
	jz		18f
/* _____CHECK_EXIT-END_____ */


/* _____FREE_MEM (CMD_CPY) START_____ */
5:
	pushl	cmd_cpy
	call	free
	addl	$4,		%esp
	movl	$0,		cmd_cpy
/* _____FREE_MEM (CMD_CPY) END_____ */


/* _____FORKING!!!-START_____ */
	call	fork
	movl	%eax,	c_pid
	
	cmpl	$0,		%eax
	jg		16f
	
	cmpl	$0,		%eax
	jl		17f
/* _____FORKING!!!-END_____ */


/* CHILD_PROC-START */
/* _____PARSE_STRING-START_____ */
	movl	cmd,	%edi
	movl	$10,	%esi			/* starting from argv[10] */
	
6:
	movb	1(%edi),		%al
	cmpb	$0x22,		%al
	jz		7f
	
	movb	(%edi),		%al
	cmpb	$0x22,		%al
	jz		8f
	
	jmp		9f

7:
	pushl	$quote
	pushl	%edi
	call	strtok
	addl	$8,		%esp
	movl	%edx,	%edi
	
	pushl	$quote
	pushl	%edi
	call	strtok
	addl	$8,		%esp
	movl	%edx,	%edi
	
	jmp		10f

8:
	pushl	$quote
	pushl	%edi
	call	strtok
	addl	$8,		%esp
	movl	%edx,	%edi
	
	jmp		10f
	
9:
	pushl	$delim1
	pushl	%edi
	call	strtok
	addl	$8,		%esp
	movl	%edx,	%edi
	
10:
	movl	8(%esp),	%ebx
	movl	%eax,		(%ebx, %esi, 4)
	
	incl	%esi
	
	cmpl	$0,		(%edi)
	jnz		6b
	
	movl	$0,		(%ebx, %esi, 4)
/* _____PARSE_STRING-END_____ */


/* _____SEARCH_PATH-START_____ */
	movl	8(%esp),	%ebx
	
	pushl	40(%ebx)
	pushl	$msg
	call	printf
	addl	$8,		%esp
	
	pushl	$1
	pushl	40(%ebx)
	call	access
	addl	$8,		%esp
	
	cmpl	$0,		%eax
	jz		14f
	
	movl	b_path,		%edi

11:
	pushl	$delim2
	pushl	%edi
	call	strtok
	addl	$8,		%esp
	movl	%eax,	%esi
	movl	%edx,	%edi
	
	cmpl	$0,		(%edx)
	jz		12f
	
	pushl	%esi
	call	strdup
	addl	$4,		%esp
	movl	%eax,	buf
	
	pushl	$slsh
	pushl	buf
	call	strcat
	addl	$8,		%esp
	
	movl	8(%esp),	%ebx
	
	pushl	40(%ebx)
	pushl	buf
	call	strcat
	addl	$8,		%esp
	
	//pushl	buf
	//call	puts
	//addl	$4,		%esp
	
	pushl	$1
	pushl	buf
	call	access
	addl	$8,		%esp
	
	cmpl	$0,		%eax
	jz		13f
	jmp		11b
	
12:
	/* CHECKING_LAST_PART_OF_PATH-START */
	pushl	%esi
	call	strdup
	addl	$4,		%esp
	movl	%eax,	buf
	
	pushl	$slsh
	pushl	buf
	call	strcat
	addl	$8,		%esp
	
	movl	8(%esp),	%ebx
	
	pushl	40(%ebx)
	pushl	buf
	call	strcat
	addl	$8,		%esp
	
	//pushl	buf
	//call	puts
	//addl	$4,		%esp
	
	pushl	$1
	pushl	buf
	call	access
	addl	$8,		%esp
	
	cmpl	$0,		%eax
	jz		13f
	/* CHECKING_LAST_PART_OF_PATH-END */
	
	movl	8(%esp),	%ebx
	
	pushl	40(%ebx)
	pushl	$error1
	call	printf
	addl	$8,		%esp
	
	pushl	$enter
	call	printf
	addl	$4,		%esp
	
	jmp		15f
/* _____SEARCH_PATH-END_____ */


/* _____EXECUTE-START_____ */
13:
	movl	8(%esp),	%ebx
	movl	buf,		%eax
	movl	%eax,		40(%ebx)
	
14:
	movl	8(%esp),	%ebx			/* ebx = argv */
	addl	$40,		%ebx			/* ebx = argv + 10 */
	movl	(%ebx),		%eax			/* eax = argv[10] */
	
	movl	12(%esp),	%ecx			/* ecx = env */
	
	pushl	%ecx
	pushl	%ebx
	pushl	%eax
	call	execve
	addl	$12,	%esp
	
15:
	xorl	%esi,	%esi
	xorl	%edi,	%edi
	xorl	%eax,	%eax
	decl	%eax					/* %eax = -1 */
	ret						/* return -1 */
/* _____EXECUTE-END_____ */
/* CHILD-PROC-END */


/* FATHER-PROC-START */
16:
	pushl	$status
	call	wait
	addl	$4,		%esp
	movl	%eax,	pid
	
	/* FREE_MEM (CMD) START */
	/*pushl	cmd
	call	free
	addl	$4,		%esp
	movl	$0,		cmd
	
	pushl	cmd_in
	call	free
	addl	$4,		%esp
	movl	$0,		cmd_in*/
	/* FREE_MEM (CMD) END */
	
	jmp		0b
/* FATHER-PROC-END */


/* PERROR_FORK-START */
17:
	pushl	$error2
	call	perror
	addl	$4, %esp
	
	xorl	%esi,	%esi
	xorl	%edi,	%edi
	xorl	%eax, %eax
	decl	%eax
	decl	%eax				/* %eax = -2 */
	ret					/* return -2 */
/* PERROR_FORK-END */


/* _____END_PROG-START_____ */
18:
	pushl	$quit2
	call	printf
	addl	$4,		%esp
	
	xorl	%eax,	%eax
	ret
/* _____END_PROG-END_____ */


prompt:		.string ">_ "
error1:		.string "%s: command not found\n"
error2:		.string "*** ERROR: forking child process failed\n"
msg:		.string "exec command: %s\n"
quit1:		.string "exit"
quit2:		.string "Exiting terminal...\n"
delim1:		.string " "
delim2:		.string ":"
quote:		.string "\""
enter:		.string "\n"
s_path:		.string "PATH"
slsh:		.string "/"
	.data
cmd_in:		.long 0
n:			.long 0
c_pid:		.int 0
status:		.int 0
pid:		.int 0
	.bss
.lcomm		cmd,		4
.lcomm		buf,		4
.lcomm		b_path,		4
.lcomm		cmd_cpy,	4
