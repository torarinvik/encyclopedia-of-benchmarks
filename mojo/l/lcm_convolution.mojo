from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 128
alias MAX_INPUT_LENGTH = 1 + 2 * MAX_N + 1
alias MODULUS = Int64(998244353)

def lcm_convolution_store_i64(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: usize, value: Int64
) -> None:
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("lcm_convolution")
fn lcm_convolution(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_N:
        return -1
    let n = Int(n_value)
    if length != c_size_t(1 + 2 * n):
        return -1
    for index in range(2 * n):
        let value = input[1 + index]
        if value < 0 or value >= MODULUS:
            return -1
    let output_bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2

    var a = InlineArray[Int64, MAX_N + 1]()
    var b = InlineArray[Int64, MAX_N + 1]()
    var c = InlineArray[Int64, MAX_N + 1]()
    for index in range(1, n + 1):
        a[index] = input[index]
        b[index] = input[n + index]
    for divisor in range(n, 0, -1):
        var multiple = 2 * divisor
        while multiple <= n:
            a[multiple] = (a[multiple] + a[divisor]) % MODULUS
            b[multiple] = (b[multiple] + b[divisor]) % MODULUS
            multiple += divisor
    for index in range(1, n + 1):
        c[index] = (a[index] * b[index]) % MODULUS
    for divisor in range(1, n + 1):
        var multiple = 2 * divisor
        while multiple <= n:
            c[multiple] -= c[divisor]
            if c[multiple] < 0:
                c[multiple] += MODULUS
            multiple += divisor
    for index in range(1, n + 1):
        lcm_convolution_store_i64(output, 8 * (index - 1), c[index])
    return Int64(output_bytes)
