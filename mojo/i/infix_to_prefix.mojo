from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn ipx_operand(c:Int64)->Bool:return (c>=48 and c<=57) or (c>=65 and c<=90) or (c>=97 and c<=122)
fn ipx_op(c:Int64)->Bool:return c==43 or c==45 or c==42 or c==47 or c==94
fn ipx_prec(c:Int64)->Int:return 1 if c==43 or c==45 else 2 if c==42 or c==47 else 3

@export("infix_to_prefix")
fn infix_to_prefix(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                   output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if length>256 or (length>0 and input==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    if length==0:return 0
    var stage=InlineArray[UInt8,256](fill=0);var depth=0;var rootdone=False
    for i in range(Int(length)):
        let ch=input[i]
        if depth==0:
            if rootdone:return -1
            if ipx_operand(ch):rootdone=True
            elif ch==40:stage[depth]=0;depth+=1
            else:return -1
        elif stage[depth-1]==0 or stage[depth-1]==2:
            if ipx_operand(ch):stage[depth-1]=UInt8(1 if stage[depth-1]==0 else 3)
            elif ch==40 and depth<256:stage[depth]=0;depth+=1
            else:return -1
        elif stage[depth-1]==1:
            if not ipx_op(ch):return -1
            stage[depth-1]=2
        else:
            if ch!=41:return -1
            depth-=1
            if depth==0:rootdone=True
            elif stage[depth-1]==0:stage[depth-1]=1
            elif stage[depth-1]==2:stage[depth-1]=3
            else:return -1
    if depth!=0 or not rootdone:return -1
    var stack=InlineArray[UInt8,256](fill=0);var postfix=InlineArray[UInt8,256](fill=0);var top=0;var count=0
    var i=Int(length)
    while i>0:
        i-=1;let ch=input[i]
        if ipx_operand(ch):postfix[count]=UInt8(ch);count+=1
        elif ch==41:stack[top]=41;top+=1
        elif ch==40:
            while top>0 and stack[top-1]!=41:top-=1;postfix[count]=stack[top];count+=1
            if top>0:top-=1
        else:
            while top>0 and stack[top-1]!=41 and ipx_prec(ch)<ipx_prec(Int64(stack[top-1])):top-=1;postfix[count]=stack[top];count+=1
            stack[top]=UInt8(ch);top+=1
    while top>0:top-=1;postfix[count]=stack[top];count+=1
    if capacity<c_size_t(count) or (count>0 and output==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for j in range(count):output[j]=postfix[count-1-j]
    return Int64(count)
