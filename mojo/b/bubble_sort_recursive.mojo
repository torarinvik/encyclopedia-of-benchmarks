from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn bubble_sort_recursive_step(values: UnsafePointer[Int64, MutAnyOrigin], length: Int):
    if length<=1:return
    var swapped=False
    for i in range(length-1):
        if values[i]>values[i+1]:
            let temp=values[i];values[i]=values[i+1];values[i+1]=temp;swapped=True
    if swapped:bubble_sort_recursive_step(values,length-1)

@export("bubble_sort_recursive")
fn bubble_sort_recursive(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C"):
    if length<=256:bubble_sort_recursive_step(values,Int(length))
