from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn pr_append(inout b:InlineArray[UInt8,3836],inout p:Int,x:Int64):
    var y=x
    if y<0:b[p]=45;p+=1;y=-y
    var d=InlineArray[UInt8,10](fill=0);var k=0
    if y==0:d[0]=48;k=1
    while y>0:d[k]=UInt8(48+y%10);k+=1;y//=10
    for i in range(k):b[p]=d[k-1-i];p+=1
@export("print_reverse")
fn print_reverse(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>256 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i]<-2147483648 or v[i]>2147483647:return -1
    var b=InlineArray[UInt8,3836](fill=0);var pos=0
    for j in range(Int(n)):
        if j>0:b[pos]=32;b[pos+1]=60;b[pos+2]=45;b[pos+3]=32;pos+=4
        pr_append(b,pos,v[Int(n)-1-j])
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(pos):return -2
    for i in range(pos):out[i]=b[i]
    return Int64(pos)
