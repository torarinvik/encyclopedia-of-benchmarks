from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn residue(value: Int64, modulus: Int64) -> Int64:
    let remainder = value % modulus
    if remainder < 0:
        return remainder + modulus
    return remainder

fn negative_residue(value: Int64, modulus: Int64) -> Int64:
    if value == 0:
        return 0
    return modulus - value

@export("berkowitz_characteristic_polynomial")
fn berkowitz_characteristic_polynomial(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 52:
        return -1
    let n64 = input[0]
    let modulus = input[1]
    if n64 < 1 or n64 > 7 or modulus < 2 or modulus > 1_000_000_000:
        return -1
    let n = Int(n64)
    if length != c_size_t(2 + n * n):
        return -1

    var matrix = InlineArray[Int64, 49](fill=0)
    for i in range(n * n):
        let entry = input[i + 2]
        if entry < -1_000_000 or entry > 1_000_000:
            return -1
        matrix[i] = residue(entry, modulus)
    let output_bytes = (n + 1) * 8
    if (output == UnsafePointer[UInt8, MutAnyOrigin]()
        or output_capacity < c_size_t(output_bytes)):
        return -2

    var coefficients = InlineArray[Int64, 8](fill=0)
    var current = InlineArray[Int64, 8](fill=0)
    var toeplitz = InlineArray[Int64, 8](fill=0)
    var vector = InlineArray[Int64, 7](fill=0)
    var next_vector = InlineArray[Int64, 7](fill=0)
    coefficients[0] = 1
    for size in range(1, n + 1):
        let start = n - size
        let block = size - 1
        for i in range(size + 1):
            toeplitz[i] = 0
        toeplitz[0] = 1
        toeplitz[1] = negative_residue(matrix[start * n + start], modulus)
        for row in range(block):
            vector[row] = matrix[(start + 1 + row) * n + start]
        for power in range(block):
            var dot: Int64 = 0
            for col in range(block):
                dot = (dot + matrix[start * n + start + 1 + col] * vector[col]) % modulus
            toeplitz[power + 2] = negative_residue(dot, modulus)
            for row in range(block):
                var value: Int64 = 0
                for col in range(block):
                    value = (value + matrix[(start + 1 + row) * n + start + 1 + col]
                        * vector[col]) % modulus
                next_vector[row] = value
            for row in range(block):
                vector[row] = next_vector[row]
        for i in range(size + 1):
            var value: Int64 = 0
            let last_child = min(i, size - 1)
            for j in range(last_child + 1):
                value = (value + toeplitz[i - j] * coefficients[j]) % modulus
            current[i] = value
        for i in range(size + 1):
            coefficients[i] = current[i]

    for i in range(n + 1):
        let bits = UInt64(coefficients[i])
        for byte in range(8):
            output[i * 8 + byte] = UInt8((bits >> (byte * 8)) & 255)
    return Int64(output_bytes)
