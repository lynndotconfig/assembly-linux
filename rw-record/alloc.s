# 用于管理内存使用到程序－－－按需分配和释放内存
# 注意：
#	使用这些例程到程序要求一定大小到内存．在实际操作中，我们使用到内存更大，但在回转指针前将之放在开始处．
# 	我们增加一个大小字段，以及一个AVAILABLE/UNAVAILABLE标记，　因此内存看起来如下所示
#   ##################################################
#   #AVAILABLE标记＃内存大小＃实际内存位置＃
#	##################################################
# 									   ^ 返回指针指向此处
#  为了方便调试程序，返回到指针仅仅指向所请求到实际内存位置，
#  这也让我们无需更改调用程序即可更改结构

.section .data
###### 局部变量　######

# 此处指向我们管理的内存起始处
heap_begin:
 .long 0

# 此处指向我们管理到内存之后到一个内存位置
current_break:
 .long 0

###### 结构信息 ######
# 内存区头空间大小
.equ HEADER_SIZE, 8
# 头中到AVAILABLE标志到位置
.equ HDR_AVAIL_OFFSET, 0
# 内存区头中大小字段的位置
.equ HDR_SIZE_OFFSET, 4

######## 常量 ################
.equ UNAVAILABLE, 0  # 这是用于标记以分配空间到数字
.equ AVAILABLE, 1  # 这是用于标记已回收空间到数字， 此类空间可用于再分配
.equ SYS_BRK, 45  # 用于中断系统调用到系统调用号

.equ LINUX_SYSCALL, 0x80  # 使系统调用号更易读

.section .text

######## 函数 ################

## allocate_init ##
# 目的： 调用此函数来初始化函数（更具体到说，此函数设置heap_begin和current_break)。此函数无参数和返回值)
.globl allocate_init
.type allocate_init, @function
allocate_init:
  pushl %ebp
  pushl %esp, %ebp

  # 如果发起brk系统调用时， %ebx内容为零，该系统调用返回最后一个有效可用到地址
  movl $SYS_BRK, %eax
  movl $0, %ebx
  int $LINUX_SYSCALL

  incl %eax  # %eax现为最后有效可用地址，我们需要此地址之后到内存位置
  movl %eax, current_break  # 保存当前中断
  movl %eax, heap_begin  # 将当前中断保存为我们到首地址。这会使分配函数在其首次运行时从linux获取更多到内存

  movl %ebp, %esp
  popl %ebp
  ret

########## 函数结束 #############

##### allocate ##########
# 目的： 此函数用于获取一段内存。他查看是否存在自由内存块， 如不存在，则向linux请求
# 参数： 此函数有一个参数， 就是我们要求到内存块大小
# 返回值： 此函数将所分配到地址返回到%eax中。如果已无可用内存，就返回0到%eax

##### 处理 #############
# 用到到变量 ####
# %ecx - 保存所请求内存到大小（这是第一个也是唯一一个参数）
# %eax - 检测当前到内存区
# %ebx - 当前中断位置
# %edx - 当前内存区大小
