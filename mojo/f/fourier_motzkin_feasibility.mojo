from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_VARIABLES = 3
comptime MAX_INEQUALITIES = 6
comptime MAX_ROWS = 128
comptime MAX_PARSEABLE = 27
comptime ROW_WIDTH = 4
comptime ROW_CELLS = 512

@export("fourier_motzkin_feasibility")
fn fourier_motzkin_feasibility(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(2) or length > c_size_t(MAX_PARSEABLE):
        return -1
    let dimension_value = input[0]
    let count_value = input[1]
    if dimension_value < 1 or dimension_value > MAX_VARIABLES or count_value < 1 or count_value > MAX_INEQUALITIES:
        return -1
    let dimension = Int(dimension_value)
    let count = Int(count_value)
    if length != c_size_t(2 + count * (dimension + 1)):
        return -1

    var current = InlineArray[Int64, ROW_CELLS](fill=0)
    var next_rows = InlineArray[Int64, ROW_CELLS](fill=0)
    var offset = 2
    for row in range(count):
        for coordinate in range(dimension):
            let value = input[offset]
            offset += 1
            if value < -3 or value > 3:
                return -1
            current[row * ROW_WIDTH + coordinate] = value
        let bound = input[offset]
        offset += 1
        if bound < -6 or bound > 6:
            return -1
        current[row * ROW_WIDTH + 3] = bound

    var row_count = count
    for variable in range(dimension):
        var next_count = 0
        for row in range(row_count):
            if current[row * ROW_WIDTH + variable] == 0:
                for column in range(ROW_WIDTH):
                    next_rows[next_count * ROW_WIDTH + column] = current[row * ROW_WIDTH + column]
                next_count += 1
        for upper in range(row_count):
            let positive = current[upper * ROW_WIDTH + variable]
            if positive <= 0:
                continue
            for lower in range(row_count):
                let negative = current[lower * ROW_WIDTH + variable]
                if negative >= 0:
                    continue
                if next_count >= MAX_ROWS:
                    return -1
                let upper_scale = positive
                let lower_scale = -negative
                for coordinate in range(dimension):
                    if coordinate == variable:
                        next_rows[next_count * ROW_WIDTH + coordinate] = 0
                    else:
                        next_rows[next_count * ROW_WIDTH + coordinate] = (
                            lower_scale * current[upper * ROW_WIDTH + coordinate]
                            + upper_scale * current[lower * ROW_WIDTH + coordinate]
                        )
                next_rows[next_count * ROW_WIDTH + 3] = (
                    lower_scale * current[upper * ROW_WIDTH + 3]
                    + upper_scale * current[lower * ROW_WIDTH + 3]
                )
                next_count += 1
        for row in range(next_count):
            for column in range(ROW_WIDTH):
                current[row * ROW_WIDTH + column] = next_rows[row * ROW_WIDTH + column]
                next_rows[row * ROW_WIDTH + column] = 0
        row_count = next_count

    for row in range(row_count):
        if current[row * ROW_WIDTH + 3] < 0:
            return 0
    return 1
