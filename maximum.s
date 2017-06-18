# 目的： 本程序寻找一组数据中的最大值

# 变量： 寄存器有如下用途

# %edi = 保存正在检测的数据项索引
# %edx = 保存已经找到的最大数据项
# %eax = 当前数据项

# 使用以下内存位置：

# data_item -包含数据项
# 		0 表示数据结束

.section .data

data_item:
.long 3,67,34,222,45,75,54,34,44,33,22,11,66,0

.section .text

.globl _start
_start:
movl $0, %edi
movl data_item(,%edi,4), %eax
movl %eax, %ebx

start_loop:
cmpl $0, %eax
je loop_exit
incl %edi
movl data_item(, %edi, 4), %eax
cmpl %ebx, %eax
jle start_loop

movl %eax, %ebx

jmp start_loop

loop_exit:
movl $1, %eax
int $0x80
