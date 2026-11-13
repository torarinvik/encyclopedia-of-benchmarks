from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 8
comptime MAX_DIMENSION = 16
comptime MAX_PARSEABLE = 258
comptime MODULUS: Int64 = 998244353

fn normalize(value: Int64) -> Int64:
    let remainder = value % MODULUS
    if remainder < 0:
        return remainder + MODULUS
    return remainder

fn multiply(left: Int64, right: Int64) -> Int64:
    return (left * right) % MODULUS

fn power(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0:
            result = multiply(result, base)
        base = multiply(base, base)
        exponent >>= 1
    return result

@export("pfaffian_of_matrix")
fn pfaffian_of_matrix(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > c_size_t(MAX_PARSEABLE):
        return -1
    if input[0] < 1 or input[0] > MAX_N:
        return -1
    let dimension = 2 * Int(input[0])
    if length != c_size_t(1 + dimension * dimension):
        return -1

    var matrix = InlineArray[Int64, MAX_DIMENSION * MAX_DIMENSION](fill=0)
    for row in range(dimension):
        for column in range(dimension):
            let value = input[1 + row * dimension + column]
            if value < 0 or value >= MODULUS:
                return -1
            matrix[row * MAX_DIMENSION + column] = value
    for row in range(dimension):
        if matrix[row * MAX_DIMENSION + row] != 0:
            return -1
        for column in range(row + 1, dimension):
            if (matrix[row * MAX_DIMENSION + column]
                    + matrix[column * MAX_DIMENSION + row]) % MODULUS != 0:
                return -1

    var result: Int64 = 1
    for pivot_index in range(0, dimension, 2):
        var partner = pivot_index + 1
        while partner < dimension and matrix[pivot_index * MAX_DIMENSION + partner] == 0:
            partner += 1
        if partner == dimension:
            return 0
        if partner != pivot_index + 1:
            let swapped = pivot_index + 1
            for k in range(dimension):
                let temporary = matrix[swapped * MAX_DIMENSION + k]
                matrix[swapped * MAX_DIMENSION + k] = matrix[partner * MAX_DIMENSION + k]
                matrix[partner * MAX_DIMENSION + k] = temporary
            for k in range(dimension):
                let temporary = matrix[k * MAX_DIMENSION + swapped]
                matrix[k * MAX_DIMENSION + swapped] = matrix[k * MAX_DIMENSION + partner]
                matrix[k * MAX_DIMENSION + partner] = temporary
            if result != 0:
                result = MODULUS - result

        let first = pivot_index * MAX_DIMENSION
        let second = (pivot_index + 1) * MAX_DIMENSION
        let pivot = matrix[first + pivot_index + 1]
        result = multiply(result, pivot)
        let inverse = power(pivot, MODULUS - 2)
        for row in range(pivot_index + 2, dimension):
            for column in range(row + 1, dimension):
                let cross = normalize(
                    multiply(matrix[first + row], matrix[second + column])
                    - multiply(matrix[first + column], matrix[second + row]))
                let value = normalize(matrix[row * MAX_DIMENSION + column]
                    - multiply(cross, inverse))
                matrix[row * MAX_DIMENSION + column] = value
                matrix[column * MAX_DIMENSION + row] = if value == 0: 0 else: MODULUS - value
    return result
