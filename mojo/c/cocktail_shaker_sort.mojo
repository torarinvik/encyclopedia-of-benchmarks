from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("cocktail_shaker_sort")
fn cocktail_shaker_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C") -> None:
    if length < 2: return
    var swapped = True
    while swapped:
        swapped = False
        for i in range(length - 1):
            if values[i] > values[i + 1]:
                let t = values[i]
                values[i] = values[i + 1]
                values[i + 1] = t
                swapped = True
        if not swapped: break
        swapped = False
        var i = Int64(length) - 1
        while i > 0:
            if values[i - 1] > values[i]:
                let t = values[i - 1]
                values[i - 1] = values[i]
                values[i] = t
                swapped = True
            i -= 1
