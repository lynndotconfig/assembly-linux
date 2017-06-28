# 目的： 将一个整数转换成适合显示的十进制字符串
# 输入： 一个足够大的缓冲区，足以存放可能的最大数
#		一个有待转换的整数
# 输出： 缓冲区将被十进制字符串覆盖

# 变量：
#   %ecx将保存已处理的字符数
#  	%eax将保存当前值
#	%edi将保存基数（10）

.equ ST_VALUE, 8
.equ ST_BUFFER, 12

.globl integer2string
.type integer2string, @function
integer2string:
  # 一般函数开始
  pushl %ebp
  movl %esp, %ebp

  # 当前字符计数
  movl %0, %ecx

  # 将值移动到所需位置
  movl ST_VALUE(%esp), %eax

  # 当除以10时， 数字10必须保存在寄存器或内存位置中
  movl $10, %edi

conversion_loop:
  # 除法实际在%edx:%eax两个寄存器上进行
  # 因此先清除%edx
  movl$0, %edx

  # 将%edx：%eax(这是默认的)除以10
  # 商存储在%eax中， 余数存储在%edx(两者都是默认的)
  divl %edi

  # 商是在正确的位置上， %edx中含有余数， 现在需要将其转换成数字
  # 因此， %edx中有一个0～9的数字， 你可以认为该数字是ASCII表上从字符0开始的索引。
  # 0的ASCII码加上0仍然得到0的ASCII码，0的ASCII码加1为字符1的ASCII码。
  # 因此， 以下指令将会让我们获得%edx中数字对应的ASCII码
  addl $'0', %edx

  # 现在， 我们将这个值入栈。这样，完成转换后就能以正确顺序逐个弹出字符
  # 注意， 我们是将整个寄存器入栈， 但字符只需要寄存器%dl部分的字节
  # （%edx寄存器的最后一个字节）
  pushl %edx

  # 递增数位计数
  incl %ecx

  # 检查%eax是否为0, 若为0则执行下一条指令
  cmpl $0, %eax
  je end_conversion_loop

  # %eax中已经有新值

  jmp conversion_loop

end_conversion_loop:
  # 现在整个字符都在栈中， 如果我们一次弹出一个字符，
  # 就能将其复制到缓冲区中并完成任务

  # 获得%edx中指向缓冲区的指针
  movl ST_BUFFER(%ebp), %edx

copy_reversing_loop:
  # 我们将整个寄存器入栈， 但只需要寄存器的最后一个字节
  # 因此， 我们要弹出字符到整个%eax寄存器， 但随后只移动
  # %eax寄存器的低位部分（%al)到字符串
  popl %eax
  movb %al, (%edx)

  # 递减%ecx， 这样我们就能判断是否完成
  decl %ecx
  # 递增%edx, 使指针指向下一个字节
  incl %edx

  # 检查是否完成
  cmpl $0, %ecx
  # 如果完成，就跳转到函数结束处
  jpe end_conversion_loop
  # 否则重复循环
  jmp copy_reversing_loop

end_copy_reversing_loop:
  # 完成复制， 现在写入一个空字节， 并返回
  movb $0, (%edx)

  movl %ebp, %esp
  popl %ebp
  ret
