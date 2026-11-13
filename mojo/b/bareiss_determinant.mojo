from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn bareiss_determinant(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65:
        return -9223372036854775808
    let n_value = input[0]
    if n_value < 1 or n_value > 8:
        return -9223372036854775808
    let n = Int(n_value)
    if length != c_size_t(1 + n * n):
        return -9223372036854775808

    var matrix = InlineArray[Int64, 64]()
    for index in range(n * n):
        let value = input[1 + index]
        if value < -4 or value > 4:
            return -9223372036854775808
        matrix[index] = value

    var sign: Int64 = 1
    var previous_pivot: Int64 = 1
    for k in range(n - 1):
        if matrix[k * n + k] == 0:
            var replacement = k + 1
            while replacement < n and matrix[replacement * n + k] == 0:
                replacement += 1
            if replacement == n:
                return 0
            for column in range(n):
                let temporary = matrix[k * n + column]
                matrix[k * n + column] = matrix[replacement * n + column]
                matrix[replacement * n + column] = temporary
            sign = -sign

        let pivot = matrix[k * n + k]
        for row in range(k + 1, n):
            for column in range(k + 1, n):
                let numerator = (
                    matrix[row * n + column] * pivot
                    - matrix[row * n + k] * matrix[k * n + column]
                )
                matrix[row * n + column] = numerator // previous_pivot
            matrix[row * n + k] = 0
        previous_pivot = pivot

    return sign * matrix[(n - 1) * n + n - 1]
