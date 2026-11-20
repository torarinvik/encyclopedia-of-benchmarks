from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_N = 8
alias INVALID_RESULT: Int64 = -9_223_372_036_854_775_808

@export("rsk_row_insertion")
fn rsk_row_insertion(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 10:
        return INVALID_RESULT
    let n_value = input[0]
    if n_value < 0 or n_value > Int64(MAX_N) or length != c_size_t(n_value + 1):
        return INVALID_RESULT
    let n = Int(n_value)
    var seen = InlineArray[Bool, MAX_N](fill=False)
    for index in range(n):
        let value = input[index + 1]
        if value < 0 or value >= n_value or seen[Int(value)]: return INVALID_RESULT
        seen[Int(value)] = True
    if n == 0: return 0

    var p = InlineArray[Int64, MAX_N * MAX_N]()
    var q = InlineArray[Int64, MAX_N * MAX_N]()
    var row_lengths = InlineArray[Int, MAX_N](fill=0)
    var row_count = 0
    for step in range(1, n + 1):
        var value = input[step] + 1
        var row = 0
        while True:
            if row == row_count:
                p[row * MAX_N] = value
                q[row * MAX_N] = Int64(step)
                row_lengths[row] = 1
                row_count += 1
                break
            var column = 0
            while column < row_lengths[row] and p[row * MAX_N + column] < value:
                column += 1
            if column == row_lengths[row]:
                p[row * MAX_N + column] = value
                q[row * MAX_N + column] = Int64(step)
                row_lengths[row] += 1
                break
            let bumped = p[row * MAX_N + column]
            p[row * MAX_N + column] = value
            value = bumped
            row += 1

    var p_row = InlineArray[Int, MAX_N](fill=0)
    var q_row = InlineArray[Int, MAX_N](fill=0)
    for row in range(row_count):
        for column in range(row_lengths[row]):
            p_row[Int(p[row * MAX_N + column] - 1)] = row
            q_row[Int(q[row * MAX_N + column] - 1)] = row
    var code = n_value
    for label in range(n):
        code = code * 9 + Int64(p_row[label] + 1)
        code = code * 9 + Int64(q_row[label] + 1)
    return code
