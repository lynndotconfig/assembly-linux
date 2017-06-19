.include "linux.s"
.include "record-def.s"

.code32
.section .data
file_name:
  .ascii "test.dat\0"
 
.section .bss
.lcomm record_buffer, RECORD_SIZE
.section .text

# 主程序
.globl _start
_start:
# 这些是我们将存储输入输出描述符打栈位置
# （仅供参考： 也可以用一个.data段中段内存地址替代
.equ ST_INPUT_DESCRIPTOR, -4
.equ ST_OUTPUT_DESCRIPTOR, -8

# 复制栈指针到%ebp
movl %esp, %ebp
# 为保存文件描述符分配空间
subl $8, %ebp

# 打开文件
movl $SYS_OPEN, %eax
movl $file_name, %ebx
movl $0, %ecx
movl $0666, %edx
int $LINUX_SYSCALL

# 保存文件描述符
movl %eax, ST_OUTPUT_DESCRIPTOR(%ebp)

# 即使输出文件描述符是常数， 我们将其保存到本地变量， 这样如果稍后决定不将其输入到STOUT， 很容易加以更改
movl $STDOUT, ST_OUTPUT_DESCRIPTOR(%ebp)

record_read_loop:
  pushl ST_INPUT_DESCRIPTOR(%ebp)
  pushl $record_buffer
  call read_record
  addl $8, %esp

  # 返回读取到字节数， 如果字节数和我们请求的字节数不同，说明已到达文件结束处或出现错误，我们就要退出
  cmpl $RECORD_SIZE, %eax
  jne finished_reading

  # 否则打印出名， 但我们首先必须知道名大小
  pushl $RECORD_FIRSTNAME + record_buffer
  call count_chars
  addl $4, %esp
  movl %eax, %edx
  movl ST_OUTPUT_DESCRIPTOR(%esp), %ebx
  movl $SYS_WRITE, %eax
  movl $RECORD_FIRSTNAME + record_buffer, %ecx
  int $LINUX_SYSCALL

  pushl ST_OUTPUT_DESCRIPTOR(%ebp)
  call write_newline
  addl $4, %esp

  jmp record_read_loop

finished_reading:
  movl $SYS_EXIT, %eax
  movl $0, %ebx
  int $LINUX_SYSCALL

