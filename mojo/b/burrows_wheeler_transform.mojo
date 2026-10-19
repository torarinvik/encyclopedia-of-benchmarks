from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn bwt_less(values:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,left:Int,right:Int,folded:Bool)->Bool:
    for off in range(n):
        var a=values[1+(left+off)%n];var b=values[1+(right+off)%n]
        if folded:
            if a>=65 and a<=90:a+=32
            if b>=65 and b<=90:b+=32
        if a!=b:return a<b
    return left<right
fn bwt_encode(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t,folded:Bool) -> Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1:return -1
    let n64=values[0];if n64<0 or n64>(256 if folded else 256) or (not folded and n64<1):return -1
    let n=Int(n64);if length!=c_size_t(n+1):return -1
    for i in range(n):if values[i+1]<0 or values[i+1]>127:return -1
    let required=n+4
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(required):return -2
    var order=List[Int](capacity=n)
    for i in range(n):order.append(i)
    for i in range(1,n):
        let key=order[i];var pos=i
        while pos>0 and bwt_less(values,n,key,order[pos-1],folded):order[pos]=order[pos-1];pos-=1
        order[pos]=key
    var primary=0
    for row in range(n):
        if not folded:
            if order[row]==0:primary=row
        else:
            var equal=True
            for off in range(n):
                if values[1+(order[row]+off)%n]!=values[1+off]:equal=False
            if equal:primary=row
    for b in range(4):output[b]=UInt8((UInt32(primary)>>UInt(8*b))&255)
    for row in range(n):output[4+row]=UInt8(values[1+(order[row]+n-1)%n])
    return Int64(required)
@export("burrows_wheeler_transform")
fn burrows_wheeler_transform(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    return bwt_encode(values,length,output,capacity,False)
