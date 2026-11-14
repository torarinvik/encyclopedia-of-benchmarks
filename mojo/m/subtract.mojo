from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("subtract")
fn subtract(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 516:
        return -2
    if input[0] < 0 or input[0] > 16 or input[1] < 0 or input[1] > 16:
        return -2
    let rows_a = Int(input[0])
    let cols_a = Int(input[1])
    if rows_a == 0 and cols_a != 0:
        return -2
    let cells_a = rows_a * cols_a
    let b_dim = 2 + cells_a
    if b_dim + 2 > Int(length):
        return -2
    if input[b_dim] < 0 or input[b_dim] > 16 or input[b_dim + 1] < 0 or input[b_dim + 1] > 16:
        return -2
    let rows_b = Int(input[b_dim])
    let cols_b = Int(input[b_dim + 1])
    if rows_b == 0 and cols_b != 0:
        return -2
    if Int(length) != b_dim + 2 + rows_b * cols_b:
        return -2
    if rows_a != rows_b or cols_a != cols_b:
        return -1
    for i in range(cells_a):
        let a = input[2 + i]
        let b = input[b_dim + 2 + i]
        if a < -2147483648 or a > 2147483647 or b < -2147483648 or b > 2147483647:
            return -2
    if cells_a == 0:
        return 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(4 * cells_a):
        return -3
    for i in range(cells_a):
        let difference = input[2 + i] - input[b_dim + 2 + i]
        for byte in range(4):
            output[4 * i + byte] = UInt8((difference >> (8 * byte)) & 255)
    return Int64(cells_a)
