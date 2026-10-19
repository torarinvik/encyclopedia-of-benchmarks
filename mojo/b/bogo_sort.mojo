from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn bogo_sorted(values: UnsafePointer[Int64, MutAnyOrigin], n: Int) -> Bool:
    for i in range(1, n):
        if values[i - 1] > values[i]: return False
    return True

@export("bogo_sort")
fn bogo_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C") -> None:
    let n = Int(length)
    if n <= 1 or n > 6 or values == UnsafePointer[Int64, MutAnyOrigin](): return
    var state: UInt32 = 2_654_435_769
    while not bogo_sorted(values, n):
        var i = n - 1
        while i > 0:
            state = state * 1_664_525 + 1_013_904_223
            let j = Int((state / 65_536) % UInt32(i + 1))
            let t = values[i]; values[i] = values[j]; values[j] = t
            i -= 1
