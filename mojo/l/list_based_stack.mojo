from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("list_based_stack")
fn list_based_stack(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>162:return -1
    let init=v[0]
    if init<0 or init>32 or 1+init>=Int(n):return -1
    var stack=InlineArray[Int64,96](fill=0);var size=Int(init)
    for i in range(size):
        if v[1+i] < -2147483648 or v[1+i]>2147483647:return -1
        stack[i]=v[1+i]
    let opidx=1+size;let ops=v[opidx]
    if ops<0 or ops>64:return -1
    var records=InlineArray[Int64,128](fill=0);var cursor=opidx+1
    for i in range(Int(ops)):
        if cursor>=Int(n):return -1
        let op=v[cursor];cursor+=1;var arg:Int64=0
        if op==1 or op==5:
            if cursor>=Int(n):return -1
            arg=v[cursor];cursor+=1
            if arg < -2147483648 or arg>2147483647:return -1
            if op==1:size+=1
        elif op==2 or op==3:
            if size==0:return -1
            if op==2:size-=1
        elif op==4:pass
        elif op==6:size=0
        else:return -1
        records[2*i]=op;records[2*i+1]=arg
    if cursor!=Int(n):return -1
    size=Int(init)
    for i in range(size):stack[i]=v[1+i]
    var output=InlineArray[UInt8,1024](fill=UInt8(0));var written=0
    for i in range(Int(ops)):
        let op=records[2*i];let arg=records[2*i+1];var result:Int64=0
        if op==1:stack[size]=arg;size+=1
        elif op==2:size-=1;result=stack[size]
        elif op==3:result=stack[size-1]
        elif op==4:result=Int64(size)
        elif op==5:
            for j in range(size):
                if stack[j]==arg:result=1;break
        else:size=0
        for field in range(2):
            let x=if field==0:op else:result;let bits=UInt64(x)
            for j in range(8):output[written+field*8+j]=UInt8((bits>>(8*j))&255)
        written+=16
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(written):return -2
    for i in range(written):out[i]=output[i]
    return Int64(written)
