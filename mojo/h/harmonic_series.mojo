from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn hs_put(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,v:Int):Int:
    var digits=InlineArray[UInt8,4](fill=0);var n=0;var x=v
    while x>0:digits[n]=UInt8(48+x%10);n+=1;x/=10
    for j in range(n):out[at+j]=digits[n-1-j]
    return n
@export("harmonic_series")
fn harmonic_series(value:Int64,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if value< -512 or value>512:return -1
    if value<=0:return 0
    var bytes=0
    for i in range(1,Int(value)+1):bytes+= (1 if i==1 else 2+hs_put_dummy(i))+1
    if cap<c_size_t(bytes) or out==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    var at=0
    for i in range(1,Int(value)+1):
        if i==1:out[at]=49;at+=1
        else:
            out[at]=49;out[at+1]=47;at+=2;at+=hs_put(out,at,i)
        out[at]=10;at+=1
    return Int64(at)
fn hs_put_dummy(v:Int)->Int:
    var n=1;var x=v
    while x>=10:x/=10;n+=1
    return n
