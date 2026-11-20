from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_ROWS = 8
comptime MAX_COLUMNS = 10
comptime MAX_INPUT = 21
comptime INF = 1_000_000_000

fn sc1p_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

fn sc1p_solve(
    rows: Int,
    columns: Int,
    weights: InlineArray[Int64, MAX_COLUMNS],
    row_left: InlineArray[Int, MAX_ROWS],
    row_right: InlineArray[Int, MAX_ROWS],
) -> Int64:
    var order = InlineArray[Int, MAX_ROWS](fill=0)
    for row in range(rows): order[row] = row
    for i in range(1, rows):
        let value = order[i]
        var j = i
        while j > 0 and row_left[order[j - 1]] > row_left[value]:
            order[j] = order[j - 1]
            j -= 1
        order[j] = value

    var grouped_left = InlineArray[Int, MAX_ROWS](fill=0)
    var grouped_right = InlineArray[Int, MAX_ROWS](fill=0)
    var groups = 0
    for i in range(rows):
        let row = order[i]
        if groups == 0 or grouped_left[groups - 1] != row_left[row]:
            grouped_left[groups] = row_left[row]
            grouped_right[groups] = row_right[row]
            groups += 1
        elif row_right[row] < grouped_right[groups - 1]:
            grouped_right[groups - 1] = row_right[row]

    var retained_left = InlineArray[Int, MAX_ROWS](fill=0)
    var retained_right = InlineArray[Int, MAX_ROWS](fill=0)
    var retained = 0
    var suffix_minimum = columns
    for offset in range(groups):
        let i = groups - 1 - offset
        if grouped_right[i] < suffix_minimum:
            retained_left[retained] = grouped_left[i]
            retained_right[retained] = grouped_right[i]
            retained += 1
            suffix_minimum = grouped_right[i]

    var column_start = InlineArray[Int, MAX_COLUMNS](fill=-1)
    var column_end = InlineArray[Int, MAX_COLUMNS](fill=-1)
    for reduced_row in range(retained):
        let source = retained - 1 - reduced_row
        for column in range(retained_left[source], retained_right[source] + 1):
            if column_start[column] < 0: column_start[column] = reduced_row
            column_end[column] = reduced_row

    var distance = InlineArray[Int64, MAX_COLUMNS](fill=INF)
    for column in range(columns):
        if column_start[column] == 0: distance[column] = 0
    var best: Int64 = INF
    for from in range(columns):
        if distance[from] == INF: continue
        if column_end[from] == retained - 1:
            best = min(best, distance[from] + weights[from])
        for to in range(from + 1, columns):
            if column_start[to] >= 0 and column_start[to] <= column_end[from] + 1:
                distance[to] = min(distance[to], distance[from] + weights[from])
    if best == INF: return -1
    return best

@export("strong_c1p_set_cover_shortest_path")
fn strong_c1p_set_cover_shortest_path(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > c_size_t(MAX_INPUT): return -1
    let rows_raw = input[0]
    let columns_raw = input[1]
    if rows_raw < 1 or rows_raw > MAX_ROWS or columns_raw < 1 or columns_raw > MAX_COLUMNS: return -1
    let rows = Int(rows_raw)
    let columns = Int(columns_raw)
    if length != c_size_t(2 + rows + columns): return -1
    var weights = InlineArray[Int64, MAX_COLUMNS](fill=0)
    for column in range(columns):
        let weight = input[2 + column]
        if weight < 1 or weight > 20: return -1
        weights[column] = weight
    let allowed = (UInt64(1) << columns) - UInt64(1)
    var masks = InlineArray[UInt64, MAX_ROWS](fill=0)
    var row_left = InlineArray[Int, MAX_ROWS](fill=0)
    var row_right = InlineArray[Int, MAX_ROWS](fill=0)
    var infeasible = False
    for row in range(rows):
        let raw = input[2 + columns + row]
        if raw < 0 or (UInt64(raw) & ~allowed) != 0: return -1
        masks[row] = UInt64(raw)
        row_left[row] = columns
        row_right[row] = -1
        var seen_one = False
        var seen_zero_after = False
        for column in range(columns):
            if (masks[row] & (UInt64(1) << column)) != 0:
                if seen_zero_after: return -1
                seen_one = True
                if row_left[row] == columns: row_left[row] = column
                row_right[row] = column
            elif seen_one:
                seen_zero_after = True
        if masks[row] == 0: infeasible = True
    let result = if infeasible: Int64(-1) else: sc1p_solve(rows, columns, weights, row_left, row_right)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    sc1p_store_i64_le(output, result)
    return 8
