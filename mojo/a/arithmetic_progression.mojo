from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("arithmetic_progression")
fn arithmetic_progression(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    let start = values[0]
    let end = values[1]
    let step = values[2]
    if start < -1000000 or start > 1000000 or end < -1000000 or end > 1000000 or step < -1000000 or step > 1000000 or step == 0: return -1
    if (start < end and step < 0) or (start > end and step > 0): return -1
    let count = (end - start) / step
    let last = start + count * step
    return ((count + 1) * (start + last)) / 2
