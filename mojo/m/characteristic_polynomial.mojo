from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MODULUS = 998244353
alias MAX_N = 8
alias MAX_INPUT_VALUES = 1 + MAX_N * MAX_N + 1

fn characteristic_polynomial_normalize(value: Int64) -> Int64:
    let remainder = value % MODULUS
    return remainder + MODULUS if remainder < 0 else remainder

fn characteristic_polynomial_multiply(left: Int64, right: Int64) -> Int64:
    return (left * right) % MODULUS

fn characteristic_polynomial_power(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0:
            result = characteristic_polynomial_multiply(result, base)
        base = characteristic_polynomial_multiply(base, base)
        exponent >>= 1
    return result

fn characteristic_polynomial_store(output: UnsafePointer[UInt8, MutAnyOrigin],
    offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("characteristic_polynomial")
fn characteristic_polynomial(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_VALUES:
        return -1
    let n_value = input[0]
    if n_value < 0 or n_value > MAX_N:
        return -1
    let n = Int(n_value)
    if length != c_size_t(1 + n * n):
        return -1

    var matrix = InlineArray[Int64, MAX_N * MAX_N]()
    for row in range(n):
        for column in range(n):
            let value = input[1 + row * n + column]
            if value < 0 or value >= MODULUS:
                return -1
            matrix[row * MAX_N + column] = value

    for column in range(n):
        if column + 2 >= n:
            break
        var pivot = column + 1
        while pivot < n and matrix[pivot * MAX_N + column] == 0:
            pivot += 1
        if pivot == n:
            continue
        if pivot != column + 1:
            for k in range(n):
                let temporary = matrix[(column + 1) * MAX_N + k]
                matrix[(column + 1) * MAX_N + k] = matrix[pivot * MAX_N + k]
                matrix[pivot * MAX_N + k] = temporary
            for k in range(n):
                let temporary = matrix[k * MAX_N + column + 1]
                matrix[k * MAX_N + column + 1] = matrix[k * MAX_N + pivot]
                matrix[k * MAX_N + pivot] = temporary
        let inverse = characteristic_polynomial_power(
            matrix[(column + 1) * MAX_N + column], MODULUS - 2)
        for row in range(column + 2, n):
            if matrix[row * MAX_N + column] == 0:
                continue
            let factor = characteristic_polynomial_multiply(
                matrix[row * MAX_N + column], inverse)
            for k in range(n):
                matrix[row * MAX_N + k] = characteristic_polynomial_normalize(
                    matrix[row * MAX_N + k] - characteristic_polynomial_multiply(
                        factor, matrix[(column + 1) * MAX_N + k]))
            for k in range(n):
                matrix[k * MAX_N + column + 1] = characteristic_polynomial_normalize(
                    matrix[k * MAX_N + column + 1] + characteristic_polynomial_multiply(
                        factor, matrix[k * MAX_N + row]))

    var coefficients = InlineArray[Int64, (MAX_N + 1) * (MAX_N + 1)]()
    coefficients[0] = 1
    for size in range(1, n + 1):
        for degree in range(size + 1):
            var value: Int64 = 0
            if degree > 0:
                value = coefficients[(size - 1) * (MAX_N + 1) + degree - 1]
            if degree < size:
                value -= characteristic_polynomial_multiply(
                    matrix[(size - 1) * MAX_N + size - 1],
                    coefficients[(size - 1) * (MAX_N + 1) + degree])
            coefficients[size * (MAX_N + 1) + degree] = characteristic_polynomial_normalize(value)
        var subdiagonal_product: Int64 = 1
        for step in range(size - 1):
            let start = size - 2 - step
            subdiagonal_product = characteristic_polynomial_multiply(
                subdiagonal_product, matrix[(start + 1) * MAX_N + start])
            let term = characteristic_polynomial_multiply(
                subdiagonal_product, matrix[start * MAX_N + size - 1])
            for degree in range(start + 1):
                coefficients[size * (MAX_N + 1) + degree] = characteristic_polynomial_normalize(
                    coefficients[size * (MAX_N + 1) + degree] -
                    characteristic_polynomial_multiply(
                        term, coefficients[start * (MAX_N + 1) + degree]))

    let output_bytes = 8 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for degree in range(n + 1):
        characteristic_polynomial_store(output, 8 * degree,
            coefficients[n * (MAX_N + 1) + degree])
    return Int64(output_bytes)
