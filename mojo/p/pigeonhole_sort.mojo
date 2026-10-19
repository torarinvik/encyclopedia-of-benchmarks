from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("pigeonhole_sort")
fn pigeonhole_sort(values: UnsafePointer[Int64, MutAnyOrigin], scratch: UnsafePointer[Int64, MutAnyOrigin], n: c_size_t) abi("C"):
    if n < 2: return
    for b in range(257): scratch[b] = 0
    for i in range(Int(n)): scratch[Int(values[i] + 128)] += 1
    var i = 0
    for b in range(257):
        while scratch[b] > 0:
            values[i] = Int64(b - 128); i += 1; scratch[b] -= 1
