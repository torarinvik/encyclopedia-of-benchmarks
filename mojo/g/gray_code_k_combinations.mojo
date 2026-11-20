from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("gray_code_k_combinations")
fn gray_code_k_combinations(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2:
        return -1
    let n_value = input[0]
    let k_value = input[1]
    if n_value < 0 or n_value > 12 or k_value < 0 or k_value > n_value:
        return -1
    let n = Int(n_value)
    let k = Int(k_value)
    let smaller = k if k < n - k else n - k
    var count = 1
    for factor in range(1, smaller + 1):
        count = (count * (n - smaller + factor)) // factor
    let required = 2 + 2 * count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    output[0] = UInt8(count & 255)
    output[1] = UInt8((count >> 8) & 255)

    let limit = 1 << n
    var emitted = 0
    for index in range(limit):
        let mask = index ^ (index >> 1)
        var remaining = mask
        var population = 0
        while remaining > 0:
            remaining = remaining & (remaining - 1)
            population += 1
        if population == k:
            output[2 + 2 * emitted] = UInt8(mask & 255)
            output[3 + 2 * emitted] = UInt8((mask >> 8) & 255)
            emitted += 1
    return Int64(count)
