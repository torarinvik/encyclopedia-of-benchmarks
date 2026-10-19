from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
fn ps_partition(v:UnsafePointer[Int64,MutAnyOrigin],lo:Int,hi:Int)->Int:
    let pivot=v[lo];var l=lo;var r=hi
    while True:
        while v[l]<pivot:l+=1
        while v[r]>pivot:r-=1
        if l>=r:return r
        let x=v[l];v[l]=v[r];v[r]=x;l+=1;r-=1
fn ps_sort(v:UnsafePointer[Int64,MutAnyOrigin],lo:Int,hi:Int):
    if lo<hi:
        let p=ps_partition(v,lo,hi);ps_sort(v,lo,p);ps_sort(v,p+1,hi)
@export("partition_sort")
fn partition_sort(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C"):
    if n>1:ps_sort(v,0,Int(n)-1)
