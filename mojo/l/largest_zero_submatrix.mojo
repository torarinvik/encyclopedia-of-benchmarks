from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_ROWS = 16
alias MAX_COLUMNS = 16

fn solve(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Int64:
    if length < 2 or length > 259:
        return -1
    let rows_value = input[0]
    let columns_value = input[1]
    if rows_value < 1 or rows_value > MAX_ROWS or columns_value < 1 or columns_value > MAX_COLUMNS:
        return -1
    let rows = Int(rows_value)
    let columns = Int(columns_value)
    if length != 2 + rows * columns:
        return -1
    for index in range(2, length):
        if input[index] != 0 and input[index] != 1:
            return -1

    var last_one = InlineArray[Int64, MAX_COLUMNS]()
    var left = InlineArray[Int64, MAX_COLUMNS]()
    var right = InlineArray[Int64, MAX_COLUMNS]()
    var stack = InlineArray[Int, MAX_COLUMNS]()
    for column in range(columns):
        last_one[column] = -1
    var best: Int64 = 0
    for row in range(rows):
        for column in range(columns):
            if input[2 + row * columns + column] == 1:
                last_one[column] = Int64(row)

        var top = 0
        for column in range(columns):
            while top > 0 and last_one[stack[top - 1]] <= last_one[column]:
                top -= 1
            left[column] = if top == 0: -1 else: Int64(stack[top - 1])
            stack[top] = column
            top += 1

        top = 0
        var cursor = columns
        while cursor > 0:
            let column = cursor - 1
            while top > 0 and last_one[stack[top - 1]] <= last_one[column]:
                top -= 1
            right[column] = if top == 0: Int64(columns) else: Int64(stack[top - 1])
            stack[top] = column
            top += 1
            cursor -= 1

        for column in range(columns):
            let height = Int64(row) - last_one[column]
            let width = right[column] - left[column] - 1
            let area = height * width
            if area > best:
                best = area
    return best

@export("largest_zero_submatrix")
fn largest_zero_submatrix(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 259:
        return -1
    return solve(input, Int(length))
