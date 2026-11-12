from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_DIMENSION = 64
alias MAX_INPUT_VALUES = 3 + 2 * MAX_DIMENSION * MAX_DIMENSION
alias MAX_OUTPUT_VALUES = MAX_DIMENSION * MAX_DIMENSION

fn matrix_product_mod_2_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("matrix_product_mod_2")
fn matrix_product_mod_2(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT_VALUES:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    let k_value = input[2]
    if n_value < 1 or n_value > MAX_DIMENSION or m_value < 1 or m_value > MAX_DIMENSION or (
        k_value < 1 or k_value > MAX_DIMENSION
    ):
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    let k = Int(k_value)
    let a_length = n * m
    let b_length = m * k
    if length != c_size_t(3 + a_length + b_length):
        return -1

    var packed_b = InlineArray[UInt64, MAX_DIMENSION]()
    let b_start = 3 + a_length
    for inner in range(m):
        for column in range(k):
            let bit = input[b_start + inner * k + column]
            if bit != 0 and bit != 1:
                return -1
            packed_b[inner] = packed_b[inner] | (UInt64(bit) << UInt(column))

    var staged = InlineArray[Int64, MAX_OUTPUT_VALUES]()
    for row in range(n):
        var accumulator = UInt64(0)
        for inner in range(m):
            let bit = input[3 + row * m + inner]
            if bit != 0 and bit != 1:
                return -1
            if bit == 1:
                accumulator = accumulator ^ packed_b[inner]
        for column in range(k):
            staged[row * k + column] = Int64((accumulator >> UInt(column)) & 1)

    let required = 8 * n * k
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    for index in range(n * k):
        matrix_product_mod_2_store(output, 8 * index, staged[index])
    return Int64(required)
