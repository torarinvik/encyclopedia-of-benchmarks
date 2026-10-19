from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("gas_station")
fn gas_station(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<0 or v[0]>128:return -2
    let count=Int(v[0]);if n!=c_size_t(2*count+1):return -2
    for i in range(2*count):if v[i+1]<0 or v[i+1]>1000000:return -2
    var total:Int64=0;var current:Int64=0;var start=0
    for i in range(count):
        let net=v[1+i]-v[1+count+i];total+=net;current+=net
        if current<0:start=i+1;current=0
    if total<0:return -1
    return Int64(start)
