from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("cocktail_sort")
fn cocktail_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C") -> None:
    var start: Int64 = 0
    var end = Int64(length)
    while start < end:
        var swapped = False
        for i in range(start, end - 1):
            if values[i] > values[i + 1]:
                let t = values[i]
                values[i] = values[i + 1]
                values[i + 1] = t
                swapped = True
        if not swapped: break
        end -= 1
        swapped = False
        var i = end
        while i > start:
            if values[i - 1] > values[i]:
                let t = values[i - 1]
                values[i - 1] = values[i]
                values[i] = t
                swapped = True
            i -= 1
        start += 1
        if not swapped: break
