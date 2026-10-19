from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
fn qs_partition(v:UnsafePointer[Int64,MutAnyOrigin],lo:Int,hi:Int)->Int:
    let pivot=v[hi-1];var store=lo
    for i in range(lo,hi-1):if v[i]<=pivot:let t=v[store];v[store]=v[i];v[i]=t;store+=1
    let t=v[store];v[store]=v[hi-1];v[hi-1]=t
    return store
fn qs_rec(v:UnsafePointer[Int64,MutAnyOrigin],mut lo:Int,mut hi:Int):
    while hi-lo>1:
        let p=qs_partition(v,lo,hi)
        if p-lo<hi-(p+1):qs_rec(v,lo,p);lo=p+1
        else:qs_rec(v,p+1,hi);hi=p
@export("quick_sort")
fn quick_sort(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    if v==UnsafePointer[Int64,MutAnyOrigin]() or n<2 or n>1024:return
    qs_rec(v,0,Int(n))
