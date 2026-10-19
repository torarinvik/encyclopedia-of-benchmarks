from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("exchange_sort")
fn exchange_sort(values:UnsafePointer[Int64,MutAnyOrigin],length:c_size_t) abi("C"):
    for first in range(Int(length)):
        for other in range(first+1,Int(length)):
            if values[other]<values[first]:let t=values[first];values[first]=values[other];values[other]=t
