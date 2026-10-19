from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("hill_cipher_mod36")
fn hill_cipher_mod36(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3:return -1
    let op=a[0];let raw=a[1]
    if (op!=0 and op!=1) or raw<1 or raw>256 or n!=c_size_t(raw+2):return -1
    var msg=InlineArray[Int,256](fill=0);var m=0
    for i in range(Int(raw)):
        let c=a[i+2];if c<0 or c>127:return -1
        var x=Int(c);if x>=97 and x<=122:x-=32
        if x>=65 and x<=90:msg[m]=x-65;m+=1
        elif x>=48 and x<=57:msg[m]=x-48+26;m+=1
    if m==0:return -1
    if m%2==1:msg[m]=msg[m-1];m+=1
    if cap<c_size_t(m) or o==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    for i in range(0,m,2):
        let x=msg[i];let y=msg[i+1]
        let u=(if op==0:2*x+5*y else:6*x+25*y)%36
        let v=(if op==0:x+6*y else:5*x+26*y)%36
        o[i]=UInt8(48+u if u>=26 else 65+u);o[i+1]=UInt8(48+v if v>=26 else 65+v)
    return Int64(m)
