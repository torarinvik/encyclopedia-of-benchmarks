from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("majority_element_sort")
fn majority_element_sort(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 128: return -1
    var a = InlineArray[Int64, 128](fill=0)
    for i in range(Int(n)):
        if v[i] < -2147483648 or v[i] > 2147483647: return -1
        a[i] = v[i]
    for i in range(1, Int(n)):
        let x = a[i]; var j = i
        while j > 0 and a[j-1] > x:
            a[j] = a[j-1]; j -= 1
        a[j] = x
    var run = 1
    for i in range(1, Int(n)):
        run = run + 1 if a[i] == a[i-1] else 1
        if run > Int(n) / 2: return a[i]
    return -1
