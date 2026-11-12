from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_ROWS = 16
comptime MAX_COLUMNS = 16
comptime MAX_INPUT_LENGTH = 260

fn smw_smawk(input: UnsafePointer[Int64, ImmutAnyOrigin], column_count: Int,
             inout row_work: InlineArray[Int32, 2 * MAX_ROWS],
             row_offset: Int, row_count: Int,
             inout column_work: InlineArray[Int32, 3 * MAX_COLUMNS],
             input_column_offset: Int, input_column_count: Int,
             output_column_offset: Int,
             inout minima: InlineArray[Int32, MAX_ROWS]):
    if row_count == 0: return
    if row_count == 1:
        let row = Int(row_work[row_offset])
        var best = Int(column_work[input_column_offset])
        for j in range(1, input_column_count):
            let candidate = Int(column_work[input_column_offset + j])
            if input[2 + row * column_count + candidate] < input[2 + row * column_count + best]: best = candidate
        minima[row] = Int32(best)
        return

    var reduced_count = 0
    for j in range(input_column_count):
        let candidate = column_work[input_column_offset + j]
        while reduced_count > 0:
            let comparison_row = Int(row_work[row_offset + reduced_count - 1])
            let previous = column_work[output_column_offset + reduced_count - 1]
            if input[2 + comparison_row * column_count + Int(candidate)]
                < input[2 + comparison_row * column_count + Int(previous)]: reduced_count -= 1
            else: break
        if reduced_count < row_count:
            column_work[output_column_offset + reduced_count] = candidate
            reduced_count += 1

    let odd_offset = row_offset + row_count
    var odd_count = 0
    for i in range(1, row_count, 2):
        row_work[odd_offset + odd_count] = row_work[row_offset + i]
        odd_count += 1
    let child_output_offset = output_column_offset + reduced_count
    smw_smawk(input, column_count, row_work, odd_offset, odd_count,
              column_work, output_column_offset, reduced_count, child_output_offset, minima)

    var start_cursor = 0
    var end_cursor = 0
    for i in range(0, row_count, 2):
        var start = 0
        if i > 0:
            let target = minima[Int(row_work[row_offset + i - 1])]
            while start_cursor < reduced_count and column_work[output_column_offset + start_cursor] != target:
                start_cursor += 1
            start = min(start_cursor, reduced_count - 1)
        var last = reduced_count - 1
        if i + 1 < row_count:
            let target = minima[Int(row_work[row_offset + i + 1])]
            if end_cursor < start: end_cursor = start
            while end_cursor < reduced_count and column_work[output_column_offset + end_cursor] != target:
                end_cursor += 1
            last = min(end_cursor, reduced_count - 1)
        let row = Int(row_work[row_offset + i])
        var best = Int(column_work[output_column_offset + start])
        for position in range(start + 1, last + 1):
            let candidate = Int(column_work[output_column_offset + position])
            if input[2 + row * column_count + candidate] < input[2 + row * column_count + best]: best = candidate
        minima[row] = Int32(best)

fn smw_store_i64_le(inout output: InlineArray[UInt8, 8 * MAX_ROWS], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (byte * 8)) & 255)

@export("smawk_row_minima")
fn smawk_row_minima(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_INPUT_LENGTH): return -1
    if input[0] < 1 or input[0] > MAX_ROWS or input[1] < 1 or input[1] > MAX_COLUMNS: return -1
    let row_count = Int(input[0])
    let column_count = Int(input[1])
    if length != c_size_t(2 + row_count * column_count): return -1

    var row_work = InlineArray[Int32, 2 * MAX_ROWS](fill=0)
    var column_work = InlineArray[Int32, 3 * MAX_COLUMNS](fill=0)
    var minima = InlineArray[Int32, MAX_ROWS](fill=0)
    for i in range(row_count): row_work[i] = Int32(i)
    for j in range(column_count): column_work[j] = Int32(j)
    smw_smawk(input, column_count, row_work, 0, row_count,
              column_work, 0, column_count, MAX_COLUMNS, minima)

    let output_bytes = row_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    var staged = InlineArray[UInt8, 8 * MAX_ROWS](fill=0)
    for i in range(row_count): smw_store_i64_le(staged, i * 8, Int64(minima[i]))
    for i in range(output_bytes): output[i] = staged[i]
    return Int64(output_bytes)
