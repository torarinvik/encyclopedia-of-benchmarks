from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
fn qs3_rec(v:UnsafePointer[Int64,MutAnyOrigin],mut lo:Int,mut hi:Int):
    while hi-lo>1:
        let pivot=v[hi-1];var lt=lo;var i=lo;var gt=hi-1
        while i<=gt:
            if v[i]<pivot:let t=v[lt];v[lt]=v[i];v[i]=t;lt+=1;i+=1
            elif v[i]>pivot:let t=v[i];v[i]=v[gt];v[gt]=t;gt-=1
            else:i+=1
        let left=lt-lo;let right=hi-(gt+1)
        if left<right:qs3_rec(v,lo,lt);lo=gt+1
        else:qs3_rec(v,gt+1,hi);hi=lt
@export("quick_sort_3")
fn quick_sort_3(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    if v==UnsafePointer[Int64,MutAnyOrigin]() or n<2 or n>1024:return
    qs3_rec(v,0,Int(n))
