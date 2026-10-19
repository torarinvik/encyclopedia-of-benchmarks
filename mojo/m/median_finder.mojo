from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray

fn mf_store(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt64(8*b))&255)

@export("median_finder")
fn median_finder(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>65 or v[0]<1 or v[0]>64 or n!=c_size_t(v[0]+1):return -1
    let count=Int(v[0]);var sorted=InlineArray[Int64,64](fill=0);var staged=InlineArray[Float64,64](fill=0.0)
    for i in range(count):
        let x=v[i+1];if x< -1000000 or x>1000000:return -1
        var j=i;while j>0 and sorted[j-1]>x:sorted[j]=sorted[j-1];j-=1;sorted[j]=x
        if (i+1)%2==0:staged[i]=Float64(sorted[i/2-1]+sorted[i/2])/2.0
        else:staged[i]=Float64(sorted[i/2])
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count*8):return -2
    for i in range(count):mf_store(out,i*8,staged[i])
    return Int64(count*8)
