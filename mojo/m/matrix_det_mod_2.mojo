from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 64
alias MAX_INPUT_VALUES = 1 + MAX_N * MAX_N

fn matrix_det_mod_2_store(output: UnsafePointer[UInt8, MutAnyOrigin], value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("matrix_det_mod_2")
fn matrix_det_mod_2(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_VALUES:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_N:
        return -1
    let n = Int(n_value)
    if length != c_size_t(1 + n * n):
        return -1

    var rows = InlineArray[UInt64, MAX_N]()
    for row in range(n):
        for column in range(n):
            let bit = input[1 + row * n + column]
            if bit != 0 and bit != 1:
                return -1
            rows[row] = rows[row] | (UInt64(bit) << UInt(column))

    var pivot_row = 0
    for column in range(n):
        var pivot = pivot_row
        while pivot < n and ((rows[pivot] >> UInt(column)) & 1) == 0:
            pivot += 1
        if pivot == n:
            continue
        let temporary = rows[pivot_row]
        rows[pivot_row] = rows[pivot]
        rows[pivot] = temporary
        for row in range(pivot_row + 1, n):
            if ((rows[row] >> UInt(column)) & 1) != 0:
                rows[row] = rows[row] ^ rows[pivot_row]
        pivot_row += 1

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8:
        return -2
    let result = Int64(1 if pivot_row == n else 0)
    matrix_det_mod_2_store(output, result)
    return 8
