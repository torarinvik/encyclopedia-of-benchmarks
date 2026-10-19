from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("wiggle_sort")
fn wiggle_sort(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    let count=Int(n);var v=InlineArray[Int32,4096]()
    for i in range(count):if a[i]< -2147483648 or a[i]>2147483647:return -1;else:v[i]=Int32(a[i])
    if cap<c_size_t(count*4) or (count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(1,count):
        if (i%2==1 and v[i-1]>v[i]) or (i%2==0 and v[i-1]<v[i]):let t=v[i];v[i]=v[i-1];v[i-1]=t
    for i in range(count):let bits=bitcast[UInt32](v[i]);for b in range(4):o[i*4+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(count)
