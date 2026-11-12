from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn power_at_most(base: Int64, exponent_input: Int64, limit: Int64) -> Bool:
    if base == 0: return True
    var product: Int64 = 1
    var exponent = exponent_input
    while exponent > 0:
        if product > limit // base: return False
        product *= base
        exponent -= 1
    return True

@export("kth_root_integer")
fn kth_root_integer(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let number = input[0]
    let degree = input[1]
    if number < 0 or degree < 1 or degree > 64: return -1

    var low: Int64 = 0
    var high = number
    while low < high:
        let difference = high - low
        let candidate = low + difference // 2 + difference % 2
        if power_at_most(candidate, degree, number): low = candidate
        else: high = candidate - 1
    return low
