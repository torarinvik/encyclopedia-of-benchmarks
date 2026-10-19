from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn bwt_ci_less(values:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,left:Int,right:Int)->Bool:
    for off in range(n):
        var a=values[1+(left+off)%n];var b=values[1+(right+off)%n]
        if a>=65 and a<=90:a+=32
        if b>=65 and b<=90:b+=32
        if a!=b:return a<b
    return left<right
@export("burrows_wheeler_transform_case_insensitive")
fn burrows_wheeler_transform_case_insensitive(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1:return -1
    let nn=values[0];if nn<0 or nn>256:return -1
    let n=Int(nn);if length!=c_size_t(n+1):return -1
    for i in range(n):if values[i+1]<0 or values[i+1]>127:return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(n+4):return -2
    var order=List[Int](capacity=n);for i in range(n):order.append(i)
    for i in range(1,n):
        let key=order[i];var pos=i
        while pos>0 and bwt_ci_less(values,n,key,order[pos-1]):order[pos]=order[pos-1];pos-=1
        order[pos]=key
    var primary=0
    for row in range(n):
        var equal=True
        for off in range(n):if values[1+(order[row]+off)%n]!=values[1+off]:equal=False
        if equal:primary=row
    for b in range(4):output[b]=UInt8((UInt32(primary)>>UInt(8*b))&255)
    for row in range(n):output[4+row]=UInt8(values[1+(order[row]+n-1)%n])
    return Int64(n+4)
