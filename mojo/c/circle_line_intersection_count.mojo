from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn cl_write_i64(inout staged: InlineArray[UInt8, 256], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        staged[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("circle_line_intersection_count")
fn circle_line_intersection_count(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 101:
        return -1
    let center_x = input[0]
    let center_y = input[1]
    let radius = input[2]
    let query_value = input[3]
    if center_x < -1000 or center_x > 1000 or center_y < -1000 or center_y > 1000 or radius < 0 or radius > 1000 or query_value < 0 or query_value > 32:
        return -1
    let query_count = Int(query_value)
    if Int(length) != 4 + 3 * query_count:
        return -1

    var a_values = InlineArray[Int64, 32]()
    var b_values = InlineArray[Int64, 32]()
    var c_values = InlineArray[Int64, 32]()
    for query in range(query_count):
        let a = input[4 + 3 * query]
        let b = input[5 + 3 * query]
        let c = input[6 + 3 * query]
        if a < -100 or a > 100 or b < -100 or b > 100 or (a == 0 and b == 0) or c < -200000 or c > 200000:
            return -1
        a_values[query] = a
        b_values[query] = b
        c_values[query] = c
    let needed = 8 * query_count
    if needed > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < needed):
        return -2

    var staged = InlineArray[UInt8, 256]()
    for query in range(query_count):
        let a = a_values[query]
        let b = b_values[query]
        let c = c_values[query]
        let offset = a * center_x + b * center_y + c
        let normal_squared = a * a + b * b
        let discriminant = radius * radius * normal_squared - offset * offset
        let count = if discriminant > 0: 2 elif discriminant == 0: 1 else: 0
        cl_write_i64(inout staged, 8 * query, count)
    for byte in range(needed):
        output[byte] = staged[byte]
    return Int64(needed)
