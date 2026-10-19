from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray
from std.math import floor,isfinite

fn mord_less(a:Float64,b:Float64)->Bool:
    return a<b or (a==0.0 and b==0.0 and (bitcast[UInt64](a)>>63)!=0 and (bitcast[UInt64](b)>>63)==0)

@export("median_of_running_array_double")
fn median_of_running_array_double(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<1 or n>66:return -1
    let cv=v[0];if not isfinite(cv) or floor(cv)!=cv or cv<1.0 or cv>64.0 or n!=c_size_t(1+Int(cv)):return -1
    let count=Int(cv);var sorted=InlineArray[Float64,64](fill=0.0);var staged=InlineArray[Float64,64](fill=0.0)
    for i in range(count):
        let x=v[i+1];if not isfinite(x) or x< -1000000.0 or x>1000000.0:return -1
        var j=i;while j>0 and mord_less(x,sorted[j-1]):sorted[j]=sorted[j-1];j-=1;sorted[j]=x
        let size=i+1;let middle=size/2
        staged[i]=sorted[middle] if size%2!=0 else (sorted[middle-1]+sorted[middle])/2.0
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(count):return -2
    for i in range(count):out[i]=staged[i]
    return Int64(count)
