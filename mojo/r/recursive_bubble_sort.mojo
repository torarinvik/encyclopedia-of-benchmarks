from std.ffi import c_size_t
from std.memory import MutAnyOrigin,UnsafePointer
fn rb_range(v:UnsafePointer[Int64,MutAnyOrigin],n:Int):
    if n<2:return
    for i in range(n-1):
        if v[i]>v[i+1]:let t=v[i];v[i]=v[i+1];v[i+1]=t
    rb_range(v,n-1)
@export("recursive_bubble_sort")
fn recursive_bubble_sort(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C"):
    rb_range(v,Int(n))
