from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("prefix_to_infix")
fn prefix_to_infix(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>64 or v[0]<0 or v[0]>63 or n!=c_size_t(v[0]+1):return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8192:return -2
    let count=Int(v[0]);if count==0:return 0
    if count==1:
        let x=v[1]
        if not ((x>=65 and x<=90) or (x>=97 and x<=122)):return -1
        out[0]=UInt8(x);return 1
    var buf=InlineArray[UInt8,8192](fill=0);var starts=InlineArray[Int,63](fill=0);var lens=InlineArray[Int,63](fill=0);var top=0;var pos=256
    for j in range(count):
        let i=count-j;let x=v[i];let op=x==43 or x==45 or x==42 or x==47 or x==94
        if op:
            if top<2:return -1
            let start=pos;buf[pos]=40;pos+=1
            for q in range(lens[top-1]):buf[pos]=buf[starts[top-1]+q];pos+=1
            buf[pos]=UInt8(x);pos+=1
            for q in range(lens[top-2]):buf[pos]=buf[starts[top-2]+q];pos+=1
            buf[pos]=41;pos+=1;top-=1;starts[top-1]=start;lens[top-1]=pos-start
        else:
            if not ((x>=65 and x<=90) or (x>=97 and x<=122)):return -1
            starts[top]=pos;lens[top]=1;buf[pos]=UInt8(x);pos+=1;top+=1
        if pos>8192:return -2
    if top!=1:return -1
    for i in range(lens[0]):out[i]=buf[starts[0]+i]
    return Int64(lens[0])
