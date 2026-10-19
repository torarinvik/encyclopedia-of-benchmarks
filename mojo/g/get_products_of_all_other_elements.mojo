from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gpo_put(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt64(8*b))&255)
@export("get_products_of_all_other_elements")
fn get_products_of_all_other_elements(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>33 or v[0]<0 or v[0]>32:return -1
    let count=Int(v[0]);if n!=c_size_t(count+1):return -1
    for i in range(count):if v[i+1]< -2 or v[i+1]>2:return -1
    if count<2:return 0
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count*8):return -2
    var result=InlineArray[Int64,32](fill=0);result[0]=1
    for i in range(count-1):result[i+1]=v[i+1]*result[i]
    var suffix:Int64=1
    for rev in range(count-1):
        let i=count-1-rev;let value=v[i+1];result[i-1]*=suffix*value;suffix*=value
    for i in range(count):gpo_put(out,i*8,result[i])
    return Int64(count*8)
