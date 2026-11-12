from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 16
alias MAX_INPUT_VALUES = 1 + MAX_N * MAX_N
alias STATES = 1 << MAX_N
alias MODULUS = 998_244_353

fn hafnian_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("hafnian_of_matrix")
fn hafnian_of_matrix(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_VALUES:
        return -1
    let n_value = input[0]
    if n_value < 2 or n_value > MAX_N or n_value % 2 != 0:
        return -1
    let n = Int(n_value)
    if length != c_size_t(1 + n * n):
        return -1

    var matrix = InlineArray[Int64, MAX_N * MAX_N]()
    for row in range(n):
        for column in range(n):
            let value = input[1 + row * n + column]
            if value < 0 or value >= MODULUS or (row == column and value != 0):
                return -1
            matrix[row * MAX_N + column] = value
    for row in range(n):
        for column in range(row):
            if matrix[row * MAX_N + column] != matrix[column * MAX_N + row]:
                return -1

    var dp = InlineArray[Int64, STATES]()
    dp[0] = 1
    let full = (1 << n) - 1
    for mask in range(1, full + 1):
        var bits = mask
        var parity = 0
        while bits > 0:
            parity = (parity + bits % 2) % 2
            bits = bits // 2
        if parity != 0:
            continue
        var first = 0
        while (mask // (1 << first)) % 2 == 0:
            first += 1
        let without_first = mask - (1 << first)
        for second in range(first + 1, n):
            if (without_first // (1 << second)) % 2 == 0:
                continue
            let rest = without_first - (1 << second)
            dp[mask] = (dp[mask] + matrix[first * MAX_N + second] * dp[rest]) % MODULUS

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8:
        return -2
    hafnian_store_i64_le(output, dp[full])
    return 8
