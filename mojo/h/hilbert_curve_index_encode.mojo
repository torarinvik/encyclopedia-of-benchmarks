from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_ORDER = Int64(8)

fn hilbert_index(order: Int64, x: Int64, y: Int64) -> Int64:
    var current_x = x
    var current_y = y
    var distance: Int64 = 0
    var bit_index = order - 1
    while bit_index >= 0:
        let bit = Int64(1) << bit_index
        var x_bit: Int64 = 0
        var y_bit: Int64 = 0
        if (current_x & bit) != 0: x_bit = 1
        if (current_y & bit) != 0: y_bit = 1
        distance += bit * bit * ((3 * x_bit) ^ y_bit)
        let mask = bit - 1
        var low_x = current_x & mask
        var low_y = current_y & mask
        if y_bit == 0:
            if x_bit != 0:
                low_x = mask - low_x
                low_y = mask - low_y
            current_x = low_y
            current_y = low_x
        else:
            current_x = low_x
            current_y = low_y
        bit_index -= 1
    return distance

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[byte] = UInt8((bits >> (8 * byte)) & 255)

@export("hilbert_curve_index_encode")
fn hilbert_curve_index_encode(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3:
        return -1
    let order = input[0]
    if order < 1 or order > MAX_ORDER: return -1
    let side = Int64(1) << order
    let x = input[1]
    let y = input[2]
    if x < 0 or x >= side or y < 0 or y >= side: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8:
        return -2
    store_i64_le(output, hilbert_index(order, x, y))
    return 8
