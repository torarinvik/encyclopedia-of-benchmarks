from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn ipc_operand(c:Int64)->Bool:return (c>=48 and c<=57) or (c>=65 and c<=90) or (c>=97 and c<=122)
fn ipc_operator(c:Int64)->Bool:return c==43 or c==45 or c==42 or c==47 or c==94
fn ipc_prec(c:Int64)->Int:return 1 if c==43 or c==45 else 2 if c==42 or c==47 else 3
fn ipc_emit(mut out:InlineArray[UInt8,512],mut count:Int,token:UInt8):
    if count>0:out[count]=32;count+=1
    out[count]=token;count+=1

@export("infix_to_postfix_conversion")
fn infix_to_postfix_conversion(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                               output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1:return -1
    let n=input[0]
    if n<0 or n>256 or length!=c_size_t(n+1):return -1
    var stack=InlineArray[UInt8,256](fill=0);var result=InlineArray[UInt8,512](fill=0);var top=0;var count=0;var expect=True
    for i in range(Int(n)):
        let ch=input[i+1]
        if ipc_operand(ch):
            if not expect:return -1
            ipc_emit(mut result,mut count,UInt8(ch));expect=False
        elif ch==40:
            if not expect or top==256:return -1
            stack[top]=40;top+=1
        elif ch==41:
            if expect:return -1
            while top>0 and stack[top-1]!=40:top-=1;ipc_emit(mut result,mut count,stack[top])
            if top==0:return -1
            top-=1;expect=False
        elif ipc_operator(ch):
            if expect:return -1
            while top>0 and stack[top-1]!=40 and (ipc_prec(ch)<ipc_prec(Int64(stack[top-1])) or (ipc_prec(ch)==ipc_prec(Int64(stack[top-1])) and ch!=94)):
                top-=1;ipc_emit(mut result,mut count,stack[top])
            if top==256:return -1
            stack[top]=UInt8(ch);top+=1;expect=True
        else:return -1
    if n>0 and expect:return -1
    while top>0:
        if stack[top-1]==40:return -1
        top-=1;ipc_emit(mut result,mut count,stack[top])
    result[count]=0;count+=1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(count):return -2
    for i in range(count):output[i]=result[i]
    return Int64(count)
