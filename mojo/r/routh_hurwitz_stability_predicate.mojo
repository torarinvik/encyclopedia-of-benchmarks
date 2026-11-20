from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_PARSEABLE_LENGTH = 7

@export("routh_hurwitz_stability_predicate")
fn routh_hurwitz_stability_predicate(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    let degree = input[0]
    if degree < 1 or degree > 4 or length != c_size_t(degree + 2): return -1

    var coefficients = InlineArray[Int64, 5](fill=0)
    for index in range(Int(degree + 1)):
        let value = input[index + 1]
        if value < -3 or value > 3 or (index == 0 and value <= 0): return -1
        coefficients[index] = value

    let width = Int((degree + 2) // 2)
    var table = InlineArray[Int64, 15](fill=0)
    for column in range(width):
        let even_index = 2 * column
        let odd_index = even_index + 1
        if even_index <= Int(degree): table[column] = coefficients[even_index]
        if odd_index <= Int(degree): table[3 + column] = coefficients[odd_index]

    var row_one_zero = True
    for column in range(width):
        if table[3 + column] != 0: row_one_zero = False
    if row_one_zero or table[3] <= 0: return 0

    for row in range(2, Int(degree) + 1):
        if table[3 * (row - 1)] <= 0: return 0
        var all_zero = True
        for column in range(width):
            var upper_next: Int64 = 0
            var lower_next: Int64 = 0
            if column + 1 < width:
                upper_next = table[3 * (row - 2) + column + 1]
                lower_next = table[3 * (row - 1) + column + 1]
            table[3 * row + column] = table[3 * (row - 1)] * upper_next - table[3 * (row - 2)] * lower_next
            if table[3 * row + column] != 0: all_zero = False
        if all_zero or table[3 * row] <= 0: return 0
    return 1
