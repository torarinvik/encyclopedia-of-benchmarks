from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn i2_operand(c:Int64)->Bool:return (c>=48 and c<=57) or (c>=65 and c<=90) or (c>=97 and c<=122)
fn i2_operator(c:Int64)->Bool:return c==43 or c==45 or c==42 or c==47 or c==37
fn i2_prec(c:Int64)->Int:return 1 if c==42 or c==47 or c==37 else 0

@export("infix_to_postfix2")
fn infix_to_postfix2(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                     output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length==0 or length>24:return -1
    var stack=InlineArray[UInt8,10](fill=0);var result=InlineArray[UInt8,25](fill=0);var top=0;var count=0;var expect=True
    for i in range(Int(length)):
        let ch=input[i]
        if i2_operand(ch):
            if not expect:return -1
            result[count]=UInt8(ch);count+=1;expect=False
        elif ch==40:
            if not expect or top==10:return -1
            stack[top]=40;top+=1
        elif ch==41:
            if expect:return -1
            while top>0 and stack[top-1]!=40:top-=1;result[count]=stack[top];count+=1
            if top==0:return -1
            top-=1;expect=False
        elif i2_operator(ch):
            if expect:return -1
            while top>0 and stack[top-1]!=40 and i2_prec(ch)<=i2_prec(Int64(stack[top-1])):top-=1;result[count]=stack[top];count+=1
            if top==10:return -1
            stack[top]=UInt8(ch);top+=1;expect=True
        else:return -1
    if expect:return -1
    while top>0:
        if stack[top-1]==40:return -1
        top-=1;result[count]=stack[top];count+=1
    result[count]=0;count+=1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(count):return -2
    for i in range(count):output[i]=result[i]
    return Int64(count)
