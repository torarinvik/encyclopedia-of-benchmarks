from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_INPUT = 39
comptime MODULUS = 1000000007

@export("number_of_ways_of_cutting_a_pizza")
fn number_of_ways_of_cutting_a_pizza(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT:
        return -1
    let rows_value = input[0]
    let columns_value = input[1]
    let cuts_value = input[2]
    if rows_value < 1 or rows_value > 6 or columns_value < 1 or columns_value > 6:
        return -1
    if cuts_value < 0 or cuts_value > 5:
        return -1
    let rows = Int(rows_value)
    let columns = Int(columns_value)
    let cuts = Int(cuts_value)
    if length != c_size_t(3 + rows * columns):
        return -1

    var cells = InlineArray[Int64, 36](fill=0)
    for index in range(rows * columns):
        let cell = input[3 + index]
        if cell != 0 and cell != 1:
            return -1
        cells[index] = cell

    var suffix = InlineArray[Int64, 49](fill=0)
    for row_offset in range(rows):
        let row = rows - 1 - row_offset
        for column_offset in range(columns):
            let column = columns - 1 - column_offset
            let at = row * 7 + column
            suffix[at] = cells[row * columns + column] + suffix[(row + 1) * 7 + column]
                + suffix[row * 7 + column + 1] - suffix[(row + 1) * 7 + column + 1]

    var previous = InlineArray[Int64, 49](fill=0)
    var current = InlineArray[Int64, 49](fill=0)
    for row in range(rows):
        for column in range(columns):
            if suffix[row * 7 + column] > 0:
                previous[row * 7 + column] = 1

    for _remaining in range(cuts):
        for index in range(49):
            current[index] = 0
        for row_offset in range(rows):
            let row = rows - 1 - row_offset
            for column_offset in range(columns):
                let column = columns - 1 - column_offset
                let origin = row * 7 + column
                var ways: Int64 = 0
                for cut_row in range(row + 1, rows):
                    if suffix[origin] - suffix[cut_row * 7 + column] > 0:
                        ways += previous[cut_row * 7 + column]
                for cut_column in range(column + 1, columns):
                    if suffix[origin] - suffix[row * 7 + cut_column] > 0:
                        ways += previous[row * 7 + cut_column]
                current[origin] = ways % MODULUS
        for index in range(49):
            previous[index] = current[index]
    return previous[0]
