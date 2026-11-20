from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn bit_count(value: Int) -> Int:
    var remaining = value
    var count = 0
    while remaining != 0:
        count += remaining & 1
        remaining >>= 1
    return count

fn ryser_permanent(input: UnsafePointer[Int64, ImmutAnyOrigin],
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

    var row_sums = InlineArray[Int64, 8]()
    var total: Int64 = 0
    var previous_gray = 0
    let subset_count = 1 << n
    for ordinal in range(subset_count):
        let gray = ordinal ^ (ordinal >> 1)
        if ordinal != 0:
            let changed = gray ^ previous_gray
            var column = 0
            while ((changed >> column) & 1) == 0:
                column += 1
            let direction: Int64 = 1 if (gray & changed) != 0 else -1
            for row in range(n):
                row_sums[row] += direction * matrix[row * n + column]

        var product: Int64 = 1
        for row in range(n):
            product *= row_sums[row]
        if ((n + bit_count(gray)) & 1) != 0:
            product = -product
        total += product
        previous_gray = gray
    return total
