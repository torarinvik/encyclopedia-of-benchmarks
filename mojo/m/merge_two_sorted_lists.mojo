from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mtsl_store(out:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int64):
    let u=UInt32(Int32(x))
    for b in range(4):out[p+b]=UInt8((u>>(b*8))&255)
@export("merge_two_sorted_lists")
fn merge_two_sorted_lists(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1026:return -1
    let a=v[0];let b=v[1]
    if a<0 or b<0 or a>1024 or b>1024 or a+b>1024 or Int(n)!=Int(a+b)+2:return -1
    let bs=Int(a)+2
    for i in range(Int(a)):
        let x=v[i+2]
        if x < -2147483648 or x>2147483647 or (i>0 and v[i+1]>x):return -1
    for i in range(Int(b)):
        let x=v[bs+i]
        if x < -2147483648 or x>2147483647 or (i>0 and v[bs+i-1]>x):return -1
    let total=Int(a+b)
    if cap<c_size_t(total*4) or (total>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var i=0;var j=0
    for k in range(total):
        var x:Int64=0
        if i==Int(a):x=v[bs+j];j+=1
        elif j==Int(b):x=v[2+i];i+=1
        elif v[2+i]<=v[bs+j]:x=v[2+i];i+=1
        else:x=v[bs+j];j+=1
        mtsl_store(out,k*4,x)
    return Int64(total)
