from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("binomial_calculate")
fn binomial_calculate(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let n = input[0]; let given_k = input[1]
    if n < 0 or n > 62 or given_k < 0 or given_k > n: return -1
    let k = min(given_k, n - given_k)
    var result: Int64 = 1
    for i in range(1, Int(k) + 1): result = (result * (n - k + i)) // i
    return result
