from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 32

fn thomas_algorithm_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Float64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("thomas_algorithm")
fn thomas_algorithm(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 1 + 4 * MAX_N:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_N:
        return -1
    let n = Int(n_value)
    if length != c_size_t(1 + 4 * n):
        return -1

    var lower = InlineArray[Int64, MAX_N]()
    var diagonal = InlineArray[Int64, MAX_N]()
    var upper = InlineArray[Int64, MAX_N]()
    var rhs = InlineArray[Int64, MAX_N]()
    for row in range(n):
        lower[row] = input[1 + row]
        diagonal[row] = input[1 + n + row]
        upper[row] = input[1 + 2 * n + row]
        rhs[row] = input[1 + 3 * n + row]
    if lower[0] != 0 or upper[n - 1] != 0:
        return -1
    for row in range(n):
        if lower[row] < -16 or lower[row] > 16 or upper[row] < -16 or upper[row] > 16:
            return -1
        if diagonal[row] < 17 or diagonal[row] > 64 or rhs[row] < -1000 or rhs[row] > 1000:
            return -1
        let lower_abs = lower[row] if lower[row] >= 0 else -lower[row]
        let upper_abs = upper[row] if upper[row] >= 0 else -upper[row]
        if diagonal[row] <= lower_abs + upper_abs:
            return -1

    let output_bytes = n * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2

    var modified_upper = InlineArray[Float64, MAX_N]()
    var modified_rhs = InlineArray[Float64, MAX_N]()
    var solution = InlineArray[Float64, MAX_N]()
    modified_upper[0] = Float64(upper[0]) / Float64(diagonal[0])
    modified_rhs[0] = Float64(rhs[0]) / Float64(diagonal[0])
    for row in range(1, n):
        let pivot = Float64(diagonal[row]) - Float64(lower[row]) * modified_upper[row - 1]
        if row + 1 < n:
            modified_upper[row] = Float64(upper[row]) / pivot
        modified_rhs[row] = (Float64(rhs[row]) - Float64(lower[row]) * modified_rhs[row - 1]) / pivot
    solution[n - 1] = modified_rhs[n - 1]
    for reverse in range(n - 1):
        let row = n - 2 - reverse
        solution[row] = modified_rhs[row] - modified_upper[row] * solution[row + 1]
    for row in range(n):
        thomas_algorithm_store(output, row * 8, solution[row])
    return Int64(output_bytes)
