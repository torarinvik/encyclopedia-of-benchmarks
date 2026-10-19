from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("binary_insertion_sort")
fn binary_insertion_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C"):
    if length < 2 or values == UnsafePointer[Int64, MutAnyOrigin](): return
    for i in range(1, Int(length)):
        let key = values[i]
        var low = 0; var high = i
        while low < high:
            let mid = low + (high - low) // 2
            if values[mid] <= key: low = mid + 1
            else: high = mid
        var pos = i
        while pos > low: values[pos] = values[pos - 1]; pos -= 1
        values[low] = key
