from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn is_prime(v: Int) -> Bool:
    if v < 2: return False
    var d = 2
    while d <= v // d:
        if v % d == 0: return False
        d += 1
    return True

@export("binary_prime_constant_sequence")
fn binary_prime_constant_sequence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let n = input[0]
    if n < 0 or n > 4096: return -1
    if capacity < c_size_t(n) or (n > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    for i in range(Int(n)): output[i] = UInt8(1 if is_prime(i + 1) else 0)
    return n
