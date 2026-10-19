from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
fn stooge_range(a:UnsafePointer[Int64,MutAnyOrigin],lo:Int,hi:Int):
    let length=hi-lo
    if length<2:return
    if a[lo]>a[hi-1]:let x=a[lo];a[lo]=a[hi-1];a[hi-1]=x
    if length>2:
        let third=length/3;stooge_range(a,lo,hi-third);stooge_range(a,lo+third,hi);stooge_range(a,lo,hi-third)
@export("stooge_sort")
fn stooge_sort(a:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C"):
    if n<2:return
    stooge_range(a,0,Int(n))
