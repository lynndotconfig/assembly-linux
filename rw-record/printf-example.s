# 目的：　这个程序用于说明如何调用printf

.code32
.section .data

# 这个字符串称为格式字符串，是第一个参数，　printf用这个参数来确定给定多少个参数，以及它们分别是什么类型
firststring:
  .ascii "Hello! %s is a %s who loves the number %d\n\0"
name:
  .ascii "Jonathon\0"
personstring:
  .ascii "person\0"
# 这个也可以用.equ, 但是为量有趣，我们决定给其一个实际内存位置
numberloved:
  .long 3
.section .text
.globl _start
_start:
  # 注意，参数传递顺序与函数原型中列出的顺序相反
  pushl numberloved
  pushl $personstring
  pushl $name
  pushl $firststring
  call printf
  pushl $0
  call exit


# 编译方法：
# as printf-example.s -o printf-example.o
# ld printf-example.o -o printf-example.bin -lc -dynamic-linker /lib/ld-linux.so.2 
# 运行: ．／printf-example.bin
