from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_N = 128
alias MAX_K = 512
alias MODULUS = 1_000_000_007

@export("k_inverse_pairs_array")
fn k_inverse_pairs_array(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 3 or length != 2:
        return -1
    let n_value = input[0]
    let k_value = input[1]
    if n_value < 0 or n_value > MAX_N or k_value < 0 or k_value > MAX_K:
        return -1
    let n = Int(n_value)
    let k = Int(k_value)
    let maximum_inversions = n * (if n > 0: n - 1 else: 0) // 2
    if k > maximum_inversions:
        return 0

    var previous = InlineArray[Int64, MAX_K + 1](fill=0)
    var current = InlineArray[Int64, MAX_K + 1](fill=0)
    previous[0] = 1
    for size in range(1, n + 1):
        var window: Int64 = 0
        for inversions in range(k + 1):
            window += previous[inversions]
            if inversions >= size:
                window -= previous[inversions - size]
            window %= MODULUS
            if window < 0:
                window += MODULUS
            current[inversions] = window
        previous = current
        current = InlineArray[Int64, MAX_K + 1](fill=0)
    return previous[k]
