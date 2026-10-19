from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
fn slow_sort_range(a:UnsafePointer[Int64,MutAnyOrigin],l:Int,r:Int):
    if l>=r:return
    let m=l+(r-l)/2
    slow_sort_range(a,l,m);slow_sort_range(a,m+1,r)
    if a[r]<a[m]:let t=a[r];a[r]=a[m];a[m]=t
    slow_sort_range(a,l,r-1)
@export("slow_sort")
fn slow_sort(a:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    if n>1:slow_sort_range(a,0,Int(n)-1)
