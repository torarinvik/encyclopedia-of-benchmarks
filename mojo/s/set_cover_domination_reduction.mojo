from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_ROWS = 8
comptime MAX_COLUMNS = 8
comptime MAX_INPUT = 19
comptime MAX_OUTPUT = 272

fn put_word(mut output: InlineArray[UInt8, 272], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("set_cover_domination_reduction")
fn set_cover_domination_reduction(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > c_size_t(MAX_INPUT): return -1
    let rows_value = input[0]
    let columns_value = input[1]
    if rows_value < 1 or rows_value > MAX_ROWS or columns_value < 1 or columns_value > MAX_COLUMNS: return -1
    let rows = Int(rows_value)
    let columns = Int(columns_value)
    if length != c_size_t(2 + rows + columns): return -1
    var weights = InlineArray[Int64, 8](fill=0)
    var masks = InlineArray[UInt64, 8](fill=0)
    var active_rows = InlineArray[Bool, 8](fill=False)
    var active_columns = InlineArray[Bool, 8](fill=False)
    for column in range(columns):
        let weight = input[2 + column]
        if weight < 1 or weight > 20: return -1
        weights[column] = weight
        active_columns[column] = True
    let valid_columns = (UInt64(1) << columns) - UInt64(1)
    for row in range(rows):
        let raw = input[2 + columns + row]
        if raw < 0 or (UInt64(raw) & ~valid_columns) != 0: return -1
        masks[row] = UInt64(raw)
        active_rows[row] = True

    while True:
        var changed = False
        for keep in range(rows):
            if not active_rows[keep]: continue
            for drop in range(rows):
                if not active_rows[drop] or keep == drop: continue
                if (masks[keep] & ~masks[drop]) == 0 and (masks[keep] != masks[drop] or keep < drop):
                    active_rows[drop] = False
                    changed = True
                    break
            if changed: break
        if changed: continue

        for drop in range(columns):
            if not active_columns[drop]: continue
            var drop_cover: UInt64 = 0
            for row in range(rows):
                if active_rows[row] and (masks[row] & (UInt64(1) << drop)) != 0:
                    drop_cover = drop_cover | (UInt64(1) << row)
            for keep in range(columns):
                if not active_columns[keep] or keep == drop: continue
                var keep_cover: UInt64 = 0
                for row in range(rows):
                    if active_rows[row] and (masks[row] & (UInt64(1) << keep)) != 0:
                        keep_cover = keep_cover | (UInt64(1) << row)
                if (drop_cover & ~keep_cover) == 0 and weights[drop] >= weights[keep] and
                   (drop_cover != keep_cover or weights[drop] != weights[keep] or keep < drop):
                    active_columns[drop] = False
                    for row in range(rows): masks[row] = masks[row] & ~(UInt64(1) << drop)
                    changed = True
                    break
            if changed: break
        if changed: continue

        for drop in range(columns):
            if not active_columns[drop]: continue
            var drop_cover: UInt64 = 0
            for row in range(rows):
                if active_rows[row] and (masks[row] & (UInt64(1) << drop)) != 0:
                    drop_cover = drop_cover | (UInt64(1) << row)
            for keep in range(columns):
                if not active_columns[keep] or keep == drop: continue
                var keep_cover: UInt64 = 0
                for row in range(rows):
                    if active_rows[row] and (masks[row] & (UInt64(1) << keep)) != 0:
                        keep_cover = keep_cover | (UInt64(1) << row)
                let exclusive_rows = drop_cover & ~keep_cover
                if (drop_cover & keep_cover) == 0 or exclusive_rows == 0: continue
                var replacement_columns: UInt64 = 0
                var feasible = True
                for row in range(rows):
                    if (exclusive_rows & (UInt64(1) << row)) == 0: continue
                    var minimum_column = -1
                    for candidate in range(columns):
                        if not active_columns[candidate] or (masks[row] & (UInt64(1) << candidate)) == 0: continue
                        if minimum_column < 0 or weights[candidate] < weights[minimum_column] or
                           (weights[candidate] == weights[minimum_column] and candidate < minimum_column):
                            minimum_column = candidate
                    if minimum_column < 0:
                        feasible = False
                        break
                    replacement_columns = replacement_columns | (UInt64(1) << minimum_column)
                var replacement_cost = weights[keep]
                for candidate in range(columns):
                    if (replacement_columns & (UInt64(1) << candidate)) != 0:
                        replacement_cost += weights[candidate]
                if feasible and weights[drop] >= replacement_cost:
                    active_columns[drop] = False
                    for row in range(rows): masks[row] = masks[row] & ~(UInt64(1) << drop)
                    changed = True
                    break
            if changed: break
        if not changed: break

    var row_ids = InlineArray[Int64, 8](fill=0)
    var column_ids = InlineArray[Int64, 8](fill=0)
    var reduced_masks = InlineArray[UInt64, 8](fill=0)
    var row_count = 0
    var column_count = 0
    for row in range(rows):
        if active_rows[row]:
            row_ids[row_count] = Int64(row)
            row_count += 1
    for column in range(columns):
        if active_columns[column]:
            column_ids[column_count] = Int64(column)
            column_count += 1
    for i in range(row_count):
        for j in range(column_count):
            if (masks[Int(row_ids[i])] & (UInt64(1) << j)) != 0:
                reduced_masks[i] = reduced_masks[i] | (UInt64(1) << j)
    let words = 2 + 2 * row_count + 2 * column_count
    let byte_count = 8 * words
    var staged = InlineArray[UInt8, 272](fill=0)
    var cursor = 0
    put_word(mut staged, 8 * cursor, Int64(row_count)); cursor += 1
    put_word(mut staged, 8 * cursor, Int64(column_count)); cursor += 1
    for i in range(row_count):
        put_word(mut staged, 8 * cursor, row_ids[i]); cursor += 1
    for i in range(column_count):
        put_word(mut staged, 8 * cursor, column_ids[i]); cursor += 1
    for i in range(column_count):
        put_word(mut staged, 8 * cursor, weights[Int(column_ids[i])]); cursor += 1
    for i in range(row_count):
        put_word(mut staged, 8 * cursor, Int64(reduced_masks[i])); cursor += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count): return -2
    for byte in range(byte_count): output[byte] = staged[byte]
    return Int64(byte_count)
