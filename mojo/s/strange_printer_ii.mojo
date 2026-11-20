from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_ROWS = 6
const MAX_COLUMNS = 6
const MAX_COLORS = 6
const COLOR_SIDE = 7

@export("strange_printer_ii")
fn strange_printer_ii(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 39: return -1
    let rows_value = input[0]
    let columns_value = input[1]
    if rows_value < 1 or rows_value > MAX_ROWS or columns_value < 1 or columns_value > MAX_COLUMNS: return -1
    let rows = Int(rows_value)
    let columns = Int(columns_value)
    if Int(length) != 2 + rows * columns: return -1
    for cell in range(rows * columns):
        if input[cell + 2] < 1 or input[cell + 2] > MAX_COLORS: return -1

    var first_row = InlineArray[Int64, COLOR_SIDE](fill=rows_value)
    var last_row = InlineArray[Int64, COLOR_SIDE](fill=-1)
    var first_column = InlineArray[Int64, COLOR_SIDE](fill=columns_value)
    var last_column = InlineArray[Int64, COLOR_SIDE](fill=-1)
    var outgoing = InlineArray[Int64, COLOR_SIDE](fill=0)
    var indegree = InlineArray[Int64, COLOR_SIDE](fill=0)
    var queue = InlineArray[Int64, COLOR_SIDE](fill=0)
    for row in range(rows):
        for column in range(columns):
            let color = Int(input[2 + row * columns + column])
            if Int64(row) < first_row[color]: first_row[color] = Int64(row)
            if Int64(row) > last_row[color]: last_row[color] = Int64(row)
            if Int64(column) < first_column[color]: first_column[color] = Int64(column)
            if Int64(column) > last_column[color]: last_column[color] = Int64(column)

    var present_count: Int64 = 0
    for color in range(1, MAX_COLORS + 1):
        if last_row[color] < 0: continue
        present_count += 1
        for row in range(Int(first_row[color]), Int(last_row[color]) + 1):
            for column in range(Int(first_column[color]), Int(last_column[color]) + 1):
                let covered = Int(input[2 + row * columns + column])
                let bit = Int64(1) << covered
                if covered != color and (outgoing[color] & bit) == 0:
                    outgoing[color] |= bit
                    indegree[covered] += 1

    var head = 0
    var tail = 0
    for color in range(1, MAX_COLORS + 1):
        if last_row[color] >= 0 and indegree[color] == 0:
            queue[tail] = Int64(color)
            tail += 1
    var processed: Int64 = 0
    while head < tail:
        let color = Int(queue[head])
        head += 1
        processed += 1
        for later in range(1, MAX_COLORS + 1):
            if (outgoing[color] & (Int64(1) << later)) != 0:
                indegree[later] -= 1
                if indegree[later] == 0:
                    queue[tail] = Int64(later)
                    tail += 1
    if processed == present_count: return 1
    return 0
