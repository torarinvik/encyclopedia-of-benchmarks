from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_ROWS = 8
alias MAX_COLUMNS = 8
alias NO_FEASIBLE = -1025
alias INVALID_INPUT = -1026

fn best_subarray_at_most(values: InlineArray[Int64, 8], count: Int, limit: Int64) -> Int64:
    var prefixes = InlineArray[Int64, 9](fill=0)
    var prefix_count = 1
    var running: Int64 = 0
    var best: Int64 = NO_FEASIBLE
    for i in range(count):
        running += values[i]
        let threshold = running - limit
        var low = 0
        var high = prefix_count
        while low < high:
            let middle = low + (high - low) // 2
            if prefixes[middle] < threshold:
                low = middle + 1
            else:
                high = middle
        if low < prefix_count:
            let candidate = running - prefixes[low]
            if best == NO_FEASIBLE or candidate > best:
                best = candidate
        var insert = prefix_count
        while insert > 0 and prefixes[insert - 1] > running:
            prefixes[insert] = prefixes[insert - 1]
            insert -= 1
        prefixes[insert] = running
        prefix_count += 1
    return best

@export("max_sum_rectangle_no_larger_than_k")
fn max_sum_rectangle_no_larger_than_k(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 68:
        return INVALID_INPUT
    let rows_value = input[0]
    let columns_value = input[1]
    let limit = input[2]
    if rows_value < 1 or rows_value > MAX_ROWS or columns_value < 1 or columns_value > MAX_COLUMNS:
        return INVALID_INPUT
    if limit < -1024 or limit > 1024:
        return INVALID_INPUT
    let rows = Int(rows_value)
    let columns = Int(columns_value)
    if length != 3 + rows * columns:
        return INVALID_INPUT
    var matrix = InlineArray[Int64, 64](fill=0)
    for row in range(rows):
        for column in range(columns):
            let value = input[3 + row * columns + column]
            if value < -16 or value > 16:
                return INVALID_INPUT
            matrix[row * MAX_COLUMNS + column] = value
    let short_dimension = min(rows, columns)
    let long_dimension = max(rows, columns)
    var best: Int64 = NO_FEASIBLE
    for first in range(short_dimension):
        var compressed = InlineArray[Int64, 8](fill=0)
        for last in range(first, short_dimension):
            for offset in range(long_dimension):
                let index = if rows <= columns:
                    last * MAX_COLUMNS + offset
                else:
                    offset * MAX_COLUMNS + last
                compressed[offset] += matrix[index]
            let candidate = best_subarray_at_most(compressed, long_dimension, limit)
            if candidate != NO_FEASIBLE and (best == NO_FEASIBLE or candidate > best):
                best = candidate
                if best == limit:
                    return best
    return best
