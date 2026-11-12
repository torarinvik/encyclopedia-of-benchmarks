from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const MAX_N = 16
const MODULUS: Int64 = 998_244_353

@export("stirling_number_of_the_second_kind")
fn stirling_number_of_the_second_kind(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != c_size_t(1):
        return -1
    let n_value = input[0]
    if n_value < 0 or n_value > MAX_N: return -1
    let n = Int(n_value)

    var row = InlineArray[Int64, MAX_N + 1](fill=0)
    row[0] = 1
    var current_n = 1
    while current_n <= n:
        var k = current_n
        while k > 0:
            row[k] = (row[k - 1] + Int64(k) * row[k]) % MODULUS
            k -= 1
        row[0] = 0
        current_n += 1

    var result: Int64 = 0
    for k in range(n + 1):
        let next = Int64(k + 1)
        let weight = next * next * next
        result = (result + weight * row[k]) % MODULUS
    return result
