from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
from std.collections import List

@export("dark_sort")
fn dark_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C"):
    if length < 2:return
    var counts=List[Int](length=129,fill=0)
    for i in range(Int(length)):counts[Int(values[i])] += 1
    var position=0
    for value in range(129):
        for _ in range(counts[value]):
            values[position]=Int64(value)
            position+=1
