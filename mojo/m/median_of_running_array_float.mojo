from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray
from std.math import floor,isfinite

fn morf_less(a:Float32,b:Float32)->Bool:
    return a<b or (a==0.0 and b==0.0 and (bitcast[UInt32](a)>>31)!=0 and (bitcast[UInt32](b)>>31)==0)

@export("median_of_running_array_float")
fn median_of_running_array_float(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<1 or n>66:return -1
    let cv=v[0];if not isfinite(cv) or floor(cv)!=cv or cv<1.0 or cv>64.0 or n!=c_size_t(1+Int(cv)):return -1
    let count=Int(cv);var sorted=InlineArray[Float32,64](fill=0.0);var staged=InlineArray[Float64,64](fill=0.0)
    for i in range(count):
        let raw=v[i+1];if not isfinite(raw) or raw< -1000000.0 or raw>1000000.0:return -1
        let x=Float32(raw)
        if Float64(x)!=raw or (raw==0.0 and ((bitcast[UInt32](x)>>31)!=(bitcast[UInt64](raw)>>63))):return -1
        var j=i;while j>0 and morf_less(x,sorted[j-1]):sorted[j]=sorted[j-1];j-=1;sorted[j]=x
        let size=i+1;let middle=size/2
        if size%2!=0:staged[i]=Float64(sorted[middle])
        else:
            let total:Float32=sorted[middle-1]+sorted[middle]
            let median:Float32=total/2.0
            staged[i]=Float64(median)
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(count):return -2
    for i in range(count):out[i]=staged[i]
    return Int64(count)
