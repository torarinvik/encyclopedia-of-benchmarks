from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 8
alias MAX_EDGES = 28
alias MAX_INPUT = 87
alias MAX_OUTPUT = 80
alias FIELD_P = 65521

fn tm_norm(value: Int64) -> Int64:
    let remainder = value % FIELD_P
    if remainder < 0: return remainder + FIELD_P
    return remainder

fn tm_power(base: Int64, exponent_value: Int) -> Int64:
    var exponent = exponent_value
    var result = Int64(1)
    var factor = tm_norm(base)
    while exponent != 0:
        if (exponent & 1) != 0: result = (result * factor) % FIELD_P
        factor = (factor * factor) % FIELD_P
        exponent >>= 1
    return result

fn tm_store(inout bytes: InlineArray[UInt8, MAX_OUTPUT], word: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        bytes[word * 8 + byte] = UInt8(bits & 255)
        bits >>= 8

fn tm_eliminate(inout inverse: InlineArray[Int64, MAX_N * MAX_N],
                inout rows: InlineArray[Bool, MAX_N],
                inout columns: InlineArray[Bool, MAX_N], n: Int,
                pivot_row: Int, pivot_column: Int) -> Bool:
    let old = inverse
    let pivot = old[pivot_row * MAX_N + pivot_column]
    if pivot == 0: return False
    let inverse_pivot = tm_power(pivot, FIELD_P - 2)
    for row in range(n):
        for column in range(n):
            let index = row * MAX_N + column
            if rows[row] and row != pivot_row and columns[column] and column != pivot_column:
                let correction = (old[row * MAX_N + pivot_column] *
                                  old[pivot_row * MAX_N + column]) % FIELD_P
                inverse[index] = tm_norm(old[index] - correction * inverse_pivot)
            else:
                inverse[index] = 0
    rows[pivot_row] = False
    columns[pivot_column] = False
    return True

@export("tutte_matrix_randomized_perfect_matching")
fn tutte_matrix_randomized_perfect_matching(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT:
        return -1
    let n64 = input[0]
    let edge_count64 = input[1]
    if n64 < 2 or n64 > MAX_N or (n64 & 1) != 0 or
       edge_count64 < 0 or edge_count64 > MAX_EDGES:
        return -1
    let n = Int(n64)
    let edge_count = Int(edge_count64)
    if edge_count > n * (n - 1) // 2 or length != c_size_t(2 + 3 * edge_count):
        return -1

    var matrix = InlineArray[Int64, MAX_N * MAX_N](fill=0)
    var previous_u = Int64(-1)
    var previous_v = Int64(-1)
    for edge in range(edge_count):
        let u64 = input[2 + 3 * edge]
        let v64 = input[3 + 3 * edge]
        let substitution = input[4 + 3 * edge]
        if u64 < 0 or v64 <= u64 or v64 >= n64 or
           u64 < previous_u or (u64 == previous_u and v64 <= previous_v) or
           substitution < 1 or substitution >= FIELD_P:
            return -1
        let u = Int(u64)
        let v = Int(v64)
        matrix[u * MAX_N + v] = substitution
        matrix[v * MAX_N + u] = FIELD_P - substitution
        previous_u = u64
        previous_v = v64

    var augmented = InlineArray[Int64, MAX_N * (2 * MAX_N)](fill=0)
    for row in range(n):
        for column in range(n):
            augmented[row * (2 * MAX_N) + column] = matrix[row * MAX_N + column]
        augmented[row * (2 * MAX_N) + n + row] = 1
    var singular = False
    for column in range(n):
        var pivot_row = column
        while pivot_row < n and augmented[pivot_row * (2 * MAX_N) + column] == 0:
            pivot_row += 1
        if pivot_row == n:
            singular = True
            break
        if pivot_row != column:
            for j in range(2 * n):
                let temp = augmented[column * (2 * MAX_N) + j]
                augmented[column * (2 * MAX_N) + j] = augmented[pivot_row * (2 * MAX_N) + j]
                augmented[pivot_row * (2 * MAX_N) + j] = temp
        let inverse_pivot = tm_power(augmented[column * (2 * MAX_N) + column], FIELD_P - 2)
        for j in range(2 * n):
            augmented[column * (2 * MAX_N) + j] =
                (augmented[column * (2 * MAX_N) + j] * inverse_pivot) % FIELD_P
        for row in range(n):
            if row == column: continue
            let factor = augmented[row * (2 * MAX_N) + column]
            if factor == 0: continue
            for j in range(2 * n):
                augmented[row * (2 * MAX_N) + j] = tm_norm(
                    augmented[row * (2 * MAX_N) + j] -
                    factor * augmented[column * (2 * MAX_N) + j])

    var result = InlineArray[Int64, 2 + MAX_N](fill=0)
    var result_size = 2
    if not singular:
        var inverse = InlineArray[Int64, MAX_N * MAX_N](fill=0)
        for row in range(n):
            for column in range(n):
                inverse[row * MAX_N + column] = augmented[row * (2 * MAX_N) + n + column]
        var rows = InlineArray[Bool, MAX_N](fill=False)
        var columns = InlineArray[Bool, MAX_N](fill=False)
        for i in range(n):
            rows[i] = True
            columns[i] = True
        var failed = False
        for vertex in range(n):
            if not columns[vertex]: continue
            var partner = -1
            for candidate in range(n):
                if rows[candidate] and candidate != vertex and
                   matrix[vertex * MAX_N + candidate] != 0 and
                   inverse[candidate * MAX_N + vertex] != 0:
                    partner = candidate
                    break
            if partner < 0 or result_size + 2 > 2 + MAX_N:
                failed = True
                break
            result[result_size] = Int64(vertex)
            result[result_size + 1] = Int64(partner)
            result_size += 2
            if not tm_eliminate(inverse, rows, columns, n, partner, vertex) or
               not tm_eliminate(inverse, rows, columns, n, vertex, partner):
                failed = True
                break
        if failed:
            result_size = 2
        else:
            result[0] = 1
            result[1] = Int64(n // 2)

    let output_bytes = result_size * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    var staged = InlineArray[UInt8, MAX_OUTPUT](fill=0)
    for word in range(result_size): tm_store(staged, word, result[word])
    for byte in range(output_bytes): output[byte] = staged[byte]
    return Int64(output_bytes)
