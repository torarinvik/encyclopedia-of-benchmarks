from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("comb_sort")
fn comb_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C") -> None:
    if length < 2: return
    var gap = Int64(length)
    var swapped = True
    while gap > 1 or swapped:
        gap = (gap / 13) * 10 + ((gap % 13) * 10) / 13
        if gap < 1: gap = 1
        swapped = False
        for i in range(Int64(length) - gap):
            if values[i] > values[i + gap]:
                let t = values[i]
                values[i] = values[i + gap]
                values[i + gap] = t
                swapped = True
