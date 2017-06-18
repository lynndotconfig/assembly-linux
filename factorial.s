# 目的： 给定一个数字， 本程序将计算其阶乘。
# 例如：3的阶乘是3x2x1,即6;4的阶乘是4x3x2x1，即24。

.code32
.section .data
.section .text

.globl _start
.globl factorial
_start:
  pushl $4
  call factorial
  addl $4, %esp # 将指针向后移动1字
  movl %eax, %ebx
  
  movl $1, %eax
  int $0x80

.type factorial, @function
factorial:
  pushl %ebp
  movl %esp, %ebp
  movl 8(%ebp), %eax
  cmpl $1, %eax
  je end_factorial
  decl %eax
  pushl %eax
  call factorial
  movl 8(%ebp), %ebx
  imull %ebx, %eax

end_factorial:
  movl %ebp, %esp
  popl %ebp
  ret 
