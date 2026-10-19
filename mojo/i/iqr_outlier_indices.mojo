from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn iqr_q7(sorted:InlineArray[Int64,62],n:Int,p:Float64)->Float64:
    let h=Float64(n-1)*p+1.0;let order=Int(h);let frac=h-Float64(order);let lower=order-1
    if frac==0.0 or lower+1>=n:return Float64(sorted[lower])
    return (1.0-frac)*Float64(sorted[lower])+frac*Float64(sorted[lower+1])

@export("iqr_outlier_indices")
fn iqr_outlier_indices(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length==0 or length>62:return -1
    let n=Int(length);var sorted=InlineArray[Int64,62](fill=0)
    for i in range(n):
        let x=input[i]
        if x< -1000000 or x>1000000:return -1
        var j=i
        while j>0 and sorted[j-1]>x:sorted[j]=sorted[j-1];j-=1
        sorted[j]=x
    let q1=iqr_q7(sorted,n,0.25);let q3=iqr_q7(sorted,n,0.75);let iqr=q3-q1
    let lower=q1-1.5*iqr;let upper=q3+1.5*iqr
    var mask:UInt64=0
    for i in range(n):
        if Float64(input[i])<lower or Float64(input[i])>upper:mask|=UInt64(1)<<UInt(i)
    return Int64(mask)
