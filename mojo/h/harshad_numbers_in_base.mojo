from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn hn_put(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,v:Int,base:Int)->Int:
    var ds=InlineArray[UInt8,16](fill=0);var n=0;var x=v
    let alphabet="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    while x>0:ds[n]=UInt8(alphabet[x%base]);n+=1;x/=base
    for j in range(n):out[at+j]=ds[n-j-1]
    out[at+n]=0;return n+1
fn hn_sum(v:Int,base:Int)->Int:
    var x=v;var s=0
    while x>0:s+=x%base;x/=base
    return s
@export("harshad_numbers_in_base")
fn harshad_numbers_in_base(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or a[1]<2 or a[1]>36 or a[0]>10000:return -1
    var count=0
    if a[0]>1:
        for v in range(1,Int(a[0])):if v%hn_sum(v,Int(a[1]))==0:count+=hn_put_dummy(v,Int(a[1]))
    if cap<c_size_t(count) or (count>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var at=0
    if a[0]>1:
        for v in range(1,Int(a[0])):if v%hn_sum(v,Int(a[1]))==0:at+=hn_put(out,at,v,Int(a[1]))
    return Int64(at)
fn hn_put_dummy(v:Int,base:Int)->Int:
    var x=v;var n=1
    while x>=base:x/=base;n+=1
    return n+1
