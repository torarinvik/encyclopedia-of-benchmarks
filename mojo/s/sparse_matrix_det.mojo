from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MOD = 998244353
alias MAX_N = 8
alias MAX_K = 64
alias MAX_PARSEABLE = 195

fn smd_add(a: Int64, b: Int64) -> Int64:
    let value = a + b
    return value - MOD if value >= MOD else value

fn smd_sub(a: Int64, b: Int64) -> Int64:
    let value = a - b
    return value + MOD if value < 0 else value

fn smd_mul(a: Int64, b: Int64) -> Int64:
    return (a * b) % MOD

fn smd_pow(value_value: Int64, exponent_value: Int64) -> Int64:
    var value = value_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0:
            result = smd_mul(result, value)
        value = smd_mul(value, value)
        exponent >>= 1
    return result

fn smd_next(inout state: Int64) -> Int64:
    state = (state * 48271 + 1) % MOD
    return state

fn smd_berlekamp_massey(sequence: InlineArray[Int64, 2 * MAX_N], length: Int,
        inout connection: InlineArray[Int64, MAX_N + 1]) -> Int:
    var previous = InlineArray[Int64, MAX_N + 1]()
    var temporary = InlineArray[Int64, MAX_N + 1]()
    for i in range(MAX_N + 1):
        connection[i] = 0
    connection[0] = 1
    previous[0] = 1
    var degree = 0
    var shift = 1
    var previous_degree = 0
    var last_discrepancy: Int64 = 1
    for index in range(length):
        var discrepancy = sequence[index]
        for i in range(1, degree + 1):
            discrepancy = smd_add(discrepancy, smd_mul(connection[i], sequence[index - i]))
        if discrepancy == 0:
            shift += 1
            continue
        for i in range(MAX_N + 1):
            temporary[i] = connection[i]
        let scale = smd_mul(discrepancy, smd_pow(last_discrepancy, MOD - 2))
        for i in range(previous_degree + 1):
            let target = i + shift
            if target <= MAX_N:
                connection[target] = smd_sub(connection[target], smd_mul(scale, previous[i]))
        if 2 * degree <= index:
            let old_degree = degree
            degree = index + 1 - degree
            for i in range(MAX_N + 1):
                previous[i] = temporary[i]
            previous_degree = old_degree
            last_discrepancy = discrepancy
            shift = 1
        else:
            shift += 1
    return degree

fn smd_dense_determinant(row: InlineArray[Int, MAX_K], column: InlineArray[Int, MAX_K],
        entry: InlineArray[Int64, MAX_K], n: Int, k: Int) -> Int64:
    var matrix = InlineArray[Int64, MAX_N * MAX_N]()
    for e in range(k):
        matrix[row[e] * MAX_N + column[e]] = entry[e]
    var determinant: Int64 = 1
    for c in range(n):
        var pivot = c
        while pivot < n and matrix[pivot * MAX_N + c] == 0:
            pivot += 1
        if pivot == n:
            return 0
        if pivot != c:
            for j in range(n):
                let temporary = matrix[c * MAX_N + j]
                matrix[c * MAX_N + j] = matrix[pivot * MAX_N + j]
                matrix[pivot * MAX_N + j] = temporary
            determinant = MOD - determinant
        let pivot_value = matrix[c * MAX_N + c]
        determinant = smd_mul(determinant, pivot_value)
        let inverse = smd_pow(pivot_value, MOD - 2)
        for i in range(c + 1, n):
            if matrix[i * MAX_N + c] == 0:
                continue
            let factor = smd_mul(matrix[i * MAX_N + c], inverse)
            for j in range(c + 1, n):
                matrix[i * MAX_N + j] = smd_sub(matrix[i * MAX_N + j], smd_mul(factor, matrix[c * MAX_N + j]))
            matrix[i * MAX_N + c] = 0
    return determinant

fn smd_wiedemann(row: InlineArray[Int, MAX_K], column: InlineArray[Int, MAX_K],
        entry: InlineArray[Int64, MAX_K], n: Int, k: Int, seed_value: Int64,
        inout success: Bool) -> Int64:
    var state = seed_value
    var diagonal = InlineArray[Int64, MAX_N]()
    var left = InlineArray[Int64, MAX_N]()
    var vector = InlineArray[Int64, MAX_N]()
    var next = InlineArray[Int64, MAX_N]()
    var weighted = InlineArray[Int64, MAX_N]()
    var sequence = InlineArray[Int64, 2 * MAX_N]()
    var diagonal_product: Int64 = 1
    for i in range(n):
        diagonal[i] = smd_next(state)
        if diagonal[i] == 0:
            diagonal[i] = 1
        left[i] = smd_next(state)
        vector[i] = smd_next(state)
        diagonal_product = smd_mul(diagonal_product, diagonal[i])
    for step in range(2 * n):
        var dot: Int64 = 0
        for i in range(n):
            dot = smd_add(dot, smd_mul(left[i], vector[i]))
        sequence[step] = dot
        for i in range(n):
            weighted[i] = smd_mul(diagonal[i], vector[i])
            next[i] = 0
        for e in range(k):
            let r = row[e]
            let c = column[e]
            next[r] = smd_add(next[r], smd_mul(entry[e], weighted[c]))
        for i in range(n):
            vector[i] = next[i]
    var connection = InlineArray[Int64, MAX_N + 1]()
    if smd_berlekamp_massey(sequence, 2 * n, connection) != n:
        success = False
        return 0
    var constant = connection[n]
    if (n & 1) != 0 and constant != 0:
        constant = MOD - constant
    success = True
    return smd_mul(constant, smd_pow(diagonal_product, MOD - 2))

fn smd_store(output: UnsafePointer[UInt8, MutAnyOrigin], value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("sparse_matrix_det")
fn sparse_matrix_det(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_PARSEABLE:
        return -1
    let n_value = input[0]
    let k_value = input[1]
    if n_value < 1 or n_value > MAX_N or k_value < 1 or k_value > MAX_K:
        return -1
    let n = Int(n_value)
    let k = Int(k_value)
    if length != c_size_t(2 + 3 * k):
        return -1
    var seen = InlineArray[Bool, MAX_N * MAX_N]()
    var row = InlineArray[Int, MAX_K]()
    var column = InlineArray[Int, MAX_K]()
    var entry = InlineArray[Int64, MAX_K]()
    for e in range(k):
        let r_value = input[2 + 3 * e]
        let c_value = input[3 + 3 * e]
        let value = input[4 + 3 * e]
        if r_value < 0 or r_value >= n_value or c_value < 0 or c_value >= n_value or value < 1 or value >= MOD:
            return -1
        let index = Int(r_value) * MAX_N + Int(c_value)
        if seen[index]:
            return -1
        seen[index] = True
        row[e] = Int(r_value)
        column[e] = Int(c_value)
        entry[e] = value
    var determinant: Int64 = 0
    var found = False
    for attempt in range(4):
        var seed = Int64(104729 + attempt * 1000003)
        if seed >= MOD:
            seed %= MOD
        var success = False
        determinant = smd_wiedemann(row, column, entry, n, k, seed, success)
        if success:
            found = True
            break
    if not found:
        determinant = smd_dense_determinant(row, column, entry, n, k)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8:
        return -2
    smd_store(output, determinant)
    return 8
