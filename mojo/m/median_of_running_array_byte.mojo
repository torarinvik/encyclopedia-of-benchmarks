from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("median_of_running_array_byte")
fn median_of_running_array_byte(v:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int32,ImmutAnyOrigin]() or n<1 or n>66 or v[0]<1 or v[0]>64 or n!=c_size_t(1+v[0]):return -1
    let count=Int(v[0]);var sorted=InlineArray[Int32,64](fill=0);var medians=InlineArray[UInt8,64](fill=0)
    for i in range(count):
        let x=v[i+1];if x< -128 or x>127:return -1
        var j=i;while j>0 and sorted[j-1]>x:sorted[j]=sorted[j-1];j-=1;sorted[j]=x
        var median:Int32=0
        if (i+1)%2!=0:median=sorted[(i+1)/2]
        else:
            let sum=sorted[(i+1)/2-1]+sorted[(i+1)/2]
            median= -((-sum)/2) if sum<0 else sum/2
        medians[i]=UInt8(Int8(median))
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count):return -2
    for i in range(count):out[i]=medians[i]
    return Int64(count)
