from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn iqr_median(v:InlineArray[Int64,64],start:Int,n:Int)->Float64:
    if n%2==1:return Float64(v[start+n//2])
    return (Float64(v[start+n//2-1])+Float64(v[start+n//2]))/2.0

@export("interquartile_range")
fn interquartile_range(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>64:return -1.0e300
    var v=InlineArray[Int64,64](fill=0)
    for i in range(Int(length)):
        let x=input[i]
        if x< -1000000 or x>1000000:return -1.0e300
        var j=i
        while j>0 and v[j-1]>x:v[j]=v[j-1];j-=1
        v[j]=x
    let half=Int(length)//2;let upper=half+(Int(length)%2)
    return iqr_median(v,upper,half)-iqr_median(v,0,half)
