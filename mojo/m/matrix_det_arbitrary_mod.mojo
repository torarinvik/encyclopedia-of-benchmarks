from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 8
alias MAX_INPUT_VALUES = 2 + MAX_N * MAX_N + 1
alias MAX_MODULUS = 1_000_000_000

fn matrix_det_arbitrary_mod_normalize(value: Int64, modulus: Int64) -> Int64:
    var residue = value % modulus
    if residue < 0:
        residue += modulus
    return residue

fn matrix_det_arbitrary_mod_store(output: UnsafePointer[UInt8, MutAnyOrigin], value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("matrix_det_arbitrary_mod")
fn matrix_det_arbitrary_mod(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_VALUES:
        return -1
    let n_value = input[0]
    let modulus = input[1]
    if n_value < 0 or n_value > MAX_N or modulus < 2 or modulus > MAX_MODULUS:
        return -1
    let n = Int(n_value)
    if length != c_size_t(2 + n * n):
        return -1

    var matrix = InlineArray[Int64, MAX_N * MAX_N]()
    for row in range(n):
        for column in range(n):
            let value = input[2 + row * n + column]
            if value < 0 or value >= modulus:
                return -1
            matrix[row * n + column] = value

    var determinant: Int64 = 1
    var sign = False
    for column in range(n):
        var pivot = column
        while pivot < n and matrix[pivot * n + column] == 0:
            pivot += 1
        if pivot == n:
            determinant = 0
            break
        if pivot != column:
            for k in range(n):
                let temporary = matrix[column * n + k]
                matrix[column * n + k] = matrix[pivot * n + k]
                matrix[pivot * n + k] = temporary
            sign = not sign
        for row in range(column + 1, n):
            var left = matrix[column * n + column]
            var right = matrix[row * n + column]
            if right == 0:
                continue
            var a0: Int64 = 1
            var a1: Int64 = 0
            var b0: Int64 = 0
            var b1: Int64 = 1
            while left != 0 and right != 0:
                if left < right:
                    let quotient = right / left
                    right -= quotient * left
                    b0 = matrix_det_arbitrary_mod_normalize(b0 - a0 * quotient, modulus)
                    b1 = matrix_det_arbitrary_mod_normalize(b1 - a1 * quotient, modulus)
                else:
                    let quotient = left / right
                    left -= quotient * right
                    a0 = matrix_det_arbitrary_mod_normalize(a0 - b0 * quotient, modulus)
                    a1 = matrix_det_arbitrary_mod_normalize(a1 - b1 * quotient, modulus)
            for k in range(column, n):
                let old_top = matrix[column * n + k]
                let old_bottom = matrix[row * n + k]
                matrix[column * n + k] = matrix_det_arbitrary_mod_normalize(old_top * a0 + old_bottom * a1, modulus)
                matrix[row * n + k] = matrix_det_arbitrary_mod_normalize(old_top * b0 + old_bottom * b1, modulus)
            if left == 0:
                for k in range(n):
                    let temporary = matrix[column * n + k]
                    matrix[column * n + k] = matrix[row * n + k]
                    matrix[row * n + k] = temporary
                sign = not sign
        determinant = (determinant * matrix[column * n + column]) % modulus
        if determinant == 0:
            break
    if sign and determinant != 0:
        determinant = modulus - determinant
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8:
        return -2
    matrix_det_arbitrary_mod_store(output, determinant)
    return 8
