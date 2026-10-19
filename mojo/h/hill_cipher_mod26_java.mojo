from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("hill_cipher_mod26_java")
fn hill_cipher_mod26_java(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257 or (a[0]!=0 and a[0]!=1):return -1
    var msg=InlineArray[Int,256](fill=0);var m=0
    for i in range(1,Int(n)):
        let c=a[i]
        if c<0 or c>127:return -1
        var x=Int(c)
        if x>=97 and x<=122:x-=32
        if x>=65 and x<=90:msg[m]=x-65;m+=1
    if m%2==1:msg[m]=23;m+=1
    if cap<c_size_t(m) or (m>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    let decrypt=a[0]==1
    for i in range(0,m,2):
        let x=msg[i];let y=msg[i+1]
        let u=(if decrypt:15*x+17*y else:3*x+3*y)%26
        let v=(if decrypt:20*x+9*y else:2*x+5*y)%26
        o[i]=UInt8(65+u);o[i+1]=UInt8(65+v)
    return Int64(m)
