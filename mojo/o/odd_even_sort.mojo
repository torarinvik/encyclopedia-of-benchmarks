from std.ffi import c_size_t
from std.memory import MutAnyOrigin,UnsafePointer
@export("odd_even_sort")
fn odd_even_sort(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C"):
    if n<2 or v==UnsafePointer[Int64,MutAnyOrigin]():return
    var swapped=True
    while swapped:
        swapped=False
        for i in range(0,Int(n)-1,2):
            if v[i]>v[i+1]:let t=v[i];v[i]=v[i+1];v[i+1]=t;swapped=True
        for i in range(1,Int(n)-1,2):
            if v[i]>v[i+1]:let t=v[i];v[i]=v[i+1];v[i+1]=t;swapped=True
