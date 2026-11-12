from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 6
comptime MODULUS: Int64 = 998244353

fn adjugate_minor_determinant(matrix: InlineArray[Int64, MAX_N * MAX_N], n: Int,
    skip_row: Int, skip_column: Int) -> Int64:
    let dimension = n - 1
    if dimension == 0:
        return 1
    var minor = InlineArray[Int64, MAX_N * MAX_N]()
    var target_row = 0
    for row in range(n):
        if row == skip_row:
            continue
        var target_column = 0
        for column in range(n):
            if column == skip_column:
                continue
            minor[target_row * dimension + target_column] = matrix[row * n + column]
            target_column += 1
        target_row += 1

    var dp = InlineArray[Int64, 1 << (MAX_N - 1)]()
    dp[0] = 1
    let limit = 1 << dimension
    for mask in range(limit):
        var row = 0
        var bits = mask
        while bits != 0:
            row += bits & 1
            bits >>= 1
        if row == dimension:
            continue
        for column in range(dimension):
            if (mask & (1 << column)) != 0:
                continue
            var inversions = 0
            for prior in range(column + 1, dimension):
                inversions += (mask >> prior) & 1
            let next = mask | (1 << column)
            let term = (dp[mask] * minor[row * dimension + column]) % MODULUS
            if (inversions & 1) == 0:
                dp[next] = (dp[next] + term) % MODULUS
            else:
                dp[next] = (dp[next] - term + MODULUS) % MODULUS
    return dp[limit - 1]

fn adjugate_matrix_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("adjugate_matrix")
fn adjugate_matrix(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 1 + MAX_N * MAX_N:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_N:
        return -1
    let n = Int(n_value)
    if length != c_size_t(1 + n * n):
        return -1

    var matrix = InlineArray[Int64, MAX_N * MAX_N]()
    for index in range(n * n):
        let value = input[1 + index]
        if value < 0 or value >= MODULUS:
            return -1
        matrix[index] = value

    let output_bytes = 8 * n * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for row in range(n):
        for column in range(n):
            var value = adjugate_minor_determinant(matrix, n, column, row)
            if ((row + column) & 1) != 0 and value != 0:
                value = MODULUS - value
            adjugate_matrix_store(output, 8 * (row * n + column), value)
    return Int64(output_bytes)
