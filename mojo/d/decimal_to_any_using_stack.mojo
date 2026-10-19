from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("decimal_to_any_using_stack")
fn decimal_to_any_using_stack(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=2:return -1
    var value=input[0];let base=input[1]
    if value<0 or base<2 or base>16:return -1
    var width=1;var n=value
    while n>=base:width+=1;n/=base
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(width):return -2
    var top=0
    if value==0:output[top]=48;top+=1
    while value>0:
        let digit=value%base
        if digit<10:output[top]=UInt8(48+digit)
        else:output[top]=UInt8(65+digit-10)
        top+=1;value/=base
    var left=0;var right=top-1
    while left<right:
        let temp=output[left];output[left]=output[right];output[right]=temp
        left+=1;right-=1
    return Int64(top)
