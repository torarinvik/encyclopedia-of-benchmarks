from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray
@export("jewels_and_stones")
fn jewels_and_stones(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>4225 or v[0]<0 or v[0]>127 or v[1]<0 or v[1]>4096:return -1
    let nj=Int(v[0]);let ns=Int(v[1]);if n!=c_size_t(2+nj+ns):return -1
    var has=InlineArray[Bool,128](fill=False)
    for i in range(nj):let x=v[2+i];if x<1 or x>127 or has[Int(x)]:return -1;has[Int(x)]=True
    var total:Int64=0
    for i in range(ns):let x=v[2+nj+i];if x<1 or x>127:return -1;if has[Int(x)]:total+=1
    return total
