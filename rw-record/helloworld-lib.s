# 目的： 此程序打印消息”hello world“

.code32
.section .data

helloworld:
  .ascii "hello world\n\0"
.section .text
.globl _start
_start:
  pushl $helloworld
  call printf

  pushl $0
  call exit
