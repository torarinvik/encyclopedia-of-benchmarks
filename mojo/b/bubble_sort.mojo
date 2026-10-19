from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("bubble_sort")
fn bubble_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C"):
    if length < 2: return
    for end in range(Int(length), 1, -1):
        var swapped=False
        for i in range(end-1):
            if values[i]>values[i+1]:
                let temp=values[i];values[i]=values[i+1];values[i+1]=temp;swapped=True
        if not swapped: break
