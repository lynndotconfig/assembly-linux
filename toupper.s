# 目的：本程序将输入文件的所有字母转换成大写字母

# 处理过程：
# 1. 打开输入文件
# 2. 打开输出文件
# 3. 如果未达到输入文件尾部：
#	a. 将部分文件读入到内存缓冲区
#	b. 读取内存缓冲区的每个字节， 如果该字节为小写字母，就将其转换为大写字母
#	c. 将内存缓冲区写入到输出文件

.code32

#### 常数 ####
.section .data

# 系统调用号
.equ SYS_OPEN, 5
.equ SYS_WRITE, 4
.equ SYS_READ, 3
.equ SYS_CLOSE, 6
.equ SYS_EXIT, 1

# 文件打开选项
# 你可以通过将选项相加或者进行OR操作组合使用选项
.equ O_WRONLY, 0
.equ O_CREATE_WRONLY_TRUNC, 03101

#　标准文件描述符
.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

#　系统调用中断
.equ LINUX_SYSCALL, 0x80
.equ END_OF_FILE, 0  # 这是读操作的返回值，表明到达文件结束处
.equ NUMBER_ARGUMENTS, 2

.section .bss
# 缓冲区　－　从文件中将数据加载到这里，　也要从这里将数据写入输出文件，　由于种种原因，　缓冲区大小不超过16000字节
.equ BUFFER_SIZE, 500
.lcomm BUFFER_DATA, BUFFER_SIZE

.section .text

# 栈位置
.equ ST_SIZE_RESERVE, 8
.equ ST_FD_IN, -4
.equ ST_FD_OUT, -8
.equ ST_ARGC, 0  # 参数数目
.equ ST_ARGV_0, 4  # 程序名
.equ ST_ARGV_1, 8  # 输入文件名
.equ ST_ARGV_2, 12  # 输出文件名

.globl _start
_start:
#### 程序初始化 ####
# 保存指针 #
movl %esp, %ebp

# 在栈上为文件描述符分配空间
subl $ST_SIZE_RESERVE, %esp

open_files:
open_fd_in:
### 打开输入文件
# 打开系统调用， open调用所需的参数：文件名， 模式和权限
movl $SYS_OPEN, %eax
movl ST_ARGV_1(%ebp), %ebx # 保存输入文件名到%ebx
movl $O_WRONLY, %ecx  # 保存读取模式到%ecx
movl $0666, %edx  # 保存读取权限到%edx
# 调用linux， 并将返回的文件描述符到%eax
int $LINUX_SYSCALL

store_fd_in:
# 保存给定的文件描述符
movl %eax, ST_FD_IN(%ebp)

open_fd_out:
### 打开输出文件 ###
# 打开open的系统调用， open调用所需的参数：文件名， 模式和权限
# open返回的是文件描述符
movl $SYS_OPEN, %eax  # 保存系统调用号
movl ST_ARGV_2(%ebp), %ebx  # 保存输出文件名到%ebx
movl $O_CREATE_WRONLY_TRUNC, %ecx  # 保存读取模式到%ecx
movl $0666, %edx  # 保存读取权限到%edx
# 调用linux, 并将返回的文件描述符到%eax
int $LINUX_SYSCALL

store_fd_out:
# 保存输出文件的描述符
movl %eax, ST_FD_OUT(%ebp)

### 主循环开始 ###
read_loop_begin:

# 从输入文件中读取一个数据块

# read系统调用, read系统调用所需参数： 文件描述符， 缓冲区地址， 缓冲区大小
# read返回的是从文件中读取的字符数
movl $SYS_READ, %eax
movl ST_FD_IN(%esp), %ebx  # 将文件描述符存入%ebx
movl $BUFFER_DATA, %ecx  # 将存储数据的缓冲区地址存入%ecx
movl $BUFFER_SIZE, %edx  # 将缓冲区大小放入%edx
int $LINUX_SYSCALL  # # 读取缓冲区大小将返回到%eax中

### 如到达文件结尾就退出###
# 检测文件结束标记
cmpl $END_OF_FILE, %eax
# 如果发现文件结束符或出现错误， 就跳转到程序结束处
jp end_loop

continue_read_loop:
### 将字符块内容转换成大写形式
pushl $BUFFER_DATA  # 缓冲区位置
pushl %eax  # 缓冲区大小
call convert_to_upper
popl %eax  # 重新获取大小
addl $4, %esp  # 恢复%esp

### 将字符块写入输出文件 ###

# write系统调用， 所需参数：文件描述符， 缓冲区地址， 缓冲区大小。
# 与read的区别是： 缓冲区应该是已经填满了要写入的数据。
# write的返回: 将写入的字节数或错误代码存入%eax
# 缓冲区大小 #
movl %eax, %edx # 保存读取的大小到%edx
movl $SYS_WRITE, %eax  # 启用write系统调用
movl ST_FD_OUT(%ebp), %ebx  # 获取输入文件描述符到%ebx
movl $BUFFER_DATA, %ecx  # 保存缓冲区地址到%ecx
int $LINUX_SYSCALL # 启用write系统调用， 并将写入的字节数保存到%eax

### 循环继续 ###
jmp read_loop_begin

end_loop:
### 关闭文件 ###
# close系统调用， 参数： 文件描述符（应该存储在%ebx中）
# 注意 - 这里我们无需进行错误检测， 因为错误情况不代表任何特殊含义
# 关闭输出文件
movl $SYS_CLOSE, %eax
movl ST_FD_OUT(%ebp), %ebx  # 保存输出文件描述符到%ebx
int $LINUX_SYSCALL
# 关闭输入文件
movl $SYS_CLOSE, %eax #
movl ST_FD_IN(%ebp), %ebx  # 保存输入文件描述符到%ebx
int $LINUX_SYSCALL



# 目的： 这个函数实际上是将字符块内容转换为大写形式

# 输入： 第一个参数是要转换的内存块的位置
#		第二个参数是缓冲区的长度

# 输出： 这个函数以大写的字符块覆盖的当前缓冲区

# 变量：
#	%eax - 缓冲区起始地址
#	%ebx - 缓冲区长度
#	%edi - 当前缓冲区的偏移量
# 	%cl  - 当前正在检测的字节(%ecx的第一部分)

### 常数 ####
# 我们搜索的下边界 #
.equ LOWERCASE_A, 'a'
# 我们搜索的下边界
.equ LOWERCASE_Z, 'z'
# 大小写转换
.equ UPPER_CONVERSION, 'A' - 'a'

### 栈相关信息
.equ ST_BUFFER_LEN, 8  # 缓冲区长度
.equ ST_BUFFER, 12  # 实际缓冲区

convert_to_upper:
 pushl %ebp
 movl %esp, %ebp

 ## 设置变量 ##
 movl ST_BUFFER(%ebp), %eax
 movl ST_BUFFER_LEN(%ebp), %ebx
 movl $0 , %edi

 # 如果给定的缓冲区长度为0即离开
 cmpl $0, %ebx
 je end_convert_loop

 convert_loop:
 # 获取当前字节
 movb (%eax, %edi, 1), %cl

 # 除非该字节在’a‘和’Z‘之间， 否则读取下一字节
 cmpb $LOWERCASE_A, %cl
 jl next_byte
 cmpb $LOWERCASE_Z, %cl
 jg next_byte

 # 否则将字符转换为大写形式
 addb $UPPER_CONVERSION, %cl
 # 并放回原处
 movb %cl, (%eax, %edi, 1)
 next_byte:
 incl %edi  # 下一字节
 cmpl %edi, %ebx  # 继续执行程序， 直到文件结束
 jne convert_loop

 end_convert_loop:
 # 无返回值， 离开程序即可
 movl %ebp, %esp
 popl %ebp
 ret




