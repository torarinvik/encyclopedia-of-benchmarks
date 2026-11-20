"""Bounded row-compression and Kadane maximum-sum submatrix profile."""
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_PARSEABLE_INPUT_LENGTH = 67
comptime OUTPUT_BYTES = 8


@export("maximum_sum_contiguous_submatrix")
fn maximum_sum_contiguous_submatrix(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin],
        output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    let rows_value = input[0]
    let columns_value = input[1]
    if rows_value < 1 or rows_value > 8 or columns_value < 1 or columns_value > 8:
        return -1
    let rows = Int(rows_value)
    let columns = Int(columns_value)
    let cells = rows * columns
    if length != c_size_t(2 + cells):
        return -1
    for index in range(cells):
        if input[index + 2] < -1000 or input[index + 2] > 1000:
            return -1

    var best: Int64 = -64001
    var column_sums = InlineArray[Int64, 8](fill=0)
    for top in range(rows):
        for column in range(columns):
            column_sums[column] = 0
        for bottom in range(top, rows):
            let row_offset = 2 + bottom * columns
            for column in range(columns):
                column_sums[column] += input[row_offset + column]
            var current = column_sums[0]
            if current > best:
                best = current
            for column in range(1, columns):
                if current < 0:
                    current = column_sums[column]
                else:
                    current += column_sums[column]
                if current > best:
                    best = current
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(OUTPUT_BYTES):
        return -2
    let bits = bitcast[UInt64](best)
    for byte in range(8):
        output[byte] = UInt8((bits >> (byte * 8)) & UInt64(255))
    return Int64(OUTPUT_BYTES)
