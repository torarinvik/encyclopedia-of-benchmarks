from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime NEWTON_MODULUS: Int64 = 998244353
comptime NEWTON_MAX_N = 12
comptime NEWTON_MAX_INPUT = 25

fn newton_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("conversion_from_monomial_basis_to_newton_basis")
fn conversion_from_monomial_basis_to_newton_basis(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > NEWTON_MAX_INPUT:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > NEWTON_MAX_N:
        return -1
    let n = Int(n_value)
    if Int(length) != 1 + 2 * n:
        return -1
    for i in range(2 * n):
        if input[i + 1] < 0 or input[i + 1] >= NEWTON_MODULUS:
            return -1

    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2
    var residual = InlineArray[Int64, NEWTON_MAX_N]()
    var answer = InlineArray[Int64, NEWTON_MAX_N]()
    for i in range(n):
        residual[i] = input[i + 1]

    var active = n
    for i in range(n):
        let node = input[n + 1 + i]
        var value: Int64 = 0
        for degree in range(active):
            value = (value * node + residual[active - 1 - degree]) % NEWTON_MODULUS
        answer[i] = value
        if active == 1:
            continue

        var quotient = InlineArray[Int64, NEWTON_MAX_N]()
        quotient[active - 2] = residual[active - 1]
        var degree = active - 2
        while degree > 0:
            quotient[degree - 1] = (residual[degree] + node * quotient[degree]) % NEWTON_MODULUS
            degree -= 1
        for j in range(active - 1):
            residual[j] = quotient[j]
        active -= 1

    for i in range(n):
        newton_store_le(output, 8 * i, answer[i])
    return Int64(bytes)
