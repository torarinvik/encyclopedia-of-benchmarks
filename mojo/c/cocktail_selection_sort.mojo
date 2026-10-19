from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("cocktail_selection_sort")
fn cocktail_selection_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C") -> None:
    if length > 1024 or (length > 0 and values == UnsafePointer[Int64, MutAnyOrigin]()): return
    var low: Int64 = 0
    var high = Int64(length)
    while high - low > 1:
        var min_i = low
        var max_i = low
        for i in range(low + 1, high):
            if values[i] < values[min_i]: min_i = i
            if values[i] > values[max_i]: max_i = i
        let minimum = values[min_i]
        values[min_i] = values[low]
        values[low] = minimum
        if max_i == low: max_i = min_i
        let maximum = values[max_i]
        values[max_i] = values[high - 1]
        values[high - 1] = maximum
        low += 1
        high -= 1
