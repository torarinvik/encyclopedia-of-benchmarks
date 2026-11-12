from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MP_MODULUS: Int64 = 998244353
comptime MP_MAX_N = 8
comptime MP_MAX_M = 8
comptime MP_LEAF_BASE = 8
comptime MP_NODE_CAPACITY = 16
comptime MP_COEFFICIENT_CAPACITY = 9
comptime MP_MAX_INPUT = 18

fn mp_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

fn mp_trim(polynomial: InlineArray[Int64, MP_COEFFICIENT_CAPACITY], length_value: Int) -> Int:
    var length = length_value
    while length > 1 and polynomial[length - 1] == 0: length -= 1
    return length

fn mp_multiply(left: InlineArray[Int64, MP_COEFFICIENT_CAPACITY], left_length: Int,
               right: InlineArray[Int64, MP_COEFFICIENT_CAPACITY], right_length: Int,
               inout product: InlineArray[Int64, MP_COEFFICIENT_CAPACITY]) -> Int:
    let length = left_length + right_length - 1
    for i in range(length): product[i] = 0
    for i in range(left_length):
        for j in range(right_length):
            product[i + j] = (product[i + j] + left[i] * right[j]) % MP_MODULUS
    return length

fn mp_remainder(dividend: InlineArray[Int64, MP_COEFFICIENT_CAPACITY], dividend_length: Int,
                divisor: InlineArray[Int64, MP_COEFFICIENT_CAPACITY], divisor_length: Int,
                inout result: InlineArray[Int64, MP_COEFFICIENT_CAPACITY]) -> Int:
    for i in range(MP_COEFFICIENT_CAPACITY): result[i] = 0
    if divisor_length == 1 and divisor[0] == 1: return 1
    for i in range(dividend_length): result[i] = dividend[i]
    var length = mp_trim(result, dividend_length)
    while length >= divisor_length:
        let shift = length - divisor_length
        let factor = result[length - 1]
        for degree in range(divisor_length):
            result[shift + degree] = (result[shift + degree] - factor * divisor[degree]) % MP_MODULUS
            if result[shift + degree] < 0: result[shift + degree] += MP_MODULUS
        length = mp_trim(result, length)
    return length

@export("multipoint_evaluation")
fn multipoint_evaluation(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > MP_MAX_INPUT: return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MP_MAX_N or m_value < 1 or m_value > MP_MAX_M: return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if Int(length) != 2 + n + m: return -1
    for i in range(n + m):
        if input[2 + i] < 0 or input[2 + i] >= MP_MODULUS: return -1
    if input[1 + n] == 0: return -1
    let bytes = 8 * m
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes: return -2

    var products = InlineArray[InlineArray[Int64, MP_COEFFICIENT_CAPACITY], MP_NODE_CAPACITY]()
    var remainders = InlineArray[InlineArray[Int64, MP_COEFFICIENT_CAPACITY], MP_NODE_CAPACITY]()
    var product_lengths = InlineArray[Int, MP_NODE_CAPACITY]()
    var remainder_lengths = InlineArray[Int, MP_NODE_CAPACITY]()
    var starts = InlineArray[Int, MP_NODE_CAPACITY]()
    var spans = InlineArray[Int, MP_NODE_CAPACITY]()
    for node in range(1, MP_NODE_CAPACITY):
        products[node][0] = 1
        product_lengths[node] = 1
    for i in range(m):
        let leaf = MP_LEAF_BASE + i
        let point = input[2 + n + i]
        products[leaf][0] = if point == 0: 0 else: MP_MODULUS - point
        products[leaf][1] = 1
        product_lengths[leaf] = 2
    for node in range(MP_LEAF_BASE - 1, 0, -1):
        product_lengths[node] = mp_multiply(products[2 * node], product_lengths[2 * node],
            products[2 * node + 1], product_lengths[2 * node + 1], products[node])

    starts[1] = 0
    spans[1] = MP_LEAF_BASE
    for node in range(1, MP_LEAF_BASE):
        spans[2 * node] = spans[node] // 2
        spans[2 * node + 1] = spans[node] // 2
        starts[2 * node] = starts[node]
        starts[2 * node + 1] = starts[node] + spans[node] // 2
    var input_poly = InlineArray[Int64, MP_COEFFICIENT_CAPACITY]()
    for i in range(n): input_poly[i] = input[2 + i]
    remainder_lengths[1] = mp_remainder(input_poly, n, products[1], product_lengths[1], remainders[1])
    for node in range(1, MP_LEAF_BASE):
        for side in range(2):
            let child = 2 * node + side
            if starts[child] < m:
                remainder_lengths[child] = mp_remainder(remainders[node], remainder_lengths[node],
                    products[child], product_lengths[child], remainders[child])
    for i in range(m): mp_store_le(output, 8 * i, remainders[MP_LEAF_BASE + i][0])
    return Int64(bytes)
