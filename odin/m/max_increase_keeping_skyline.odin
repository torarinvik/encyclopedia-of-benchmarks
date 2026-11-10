package max_increase_keeping_skyline

import "core:c"

MAX_GRID_SIZE :: 50

// Return the total allowable increase while preserving row and column skylines.
@(export)
max_increase_keeping_skyline :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 1 + MAX_GRID_SIZE * MAX_GRID_SIZE do return -1
	if values[0] < 2 || values[0] > MAX_GRID_SIZE do return -1
	size := int(values[0])
	if length != c.size_t(1 + size * size) do return -1

    row_max, column_max: [MAX_GRID_SIZE]u8
    tallest: u64
    height_sum: u32
    for row := 0; row < size; row += 1 {
        row_tallest: u8
        start := 1 + row * size
        for column := 0; column < size; column += 1 {
            value := u64(values[start + column])
            tallest = max(tallest, value)
            height_sum += u32(value)
            height := u8(value)
            row_tallest = max(row_tallest, height)
            column_max[column] = max(column_max[column], height)
        }
        row_max[row] = row_tallest
    }
    if tallest > 100 do return -1

    skyline_sum: u32
    if size <= 10 {
        for row := 0; row < size; row += 1 {
            for column := 0; column < size; column += 1 {
                skyline_sum += u32(min(row_max[row], column_max[column]))
            }
        }
    } else {
        row_counts, column_counts: [101]u8
        lowest := 100
        for index := 0; index < size; index += 1 {
            lowest = min(lowest, min(int(row_max[index]), int(column_max[index])))
            row_counts[row_max[index]] += 1
            column_counts[column_max[index]] += 1
        }
        rows_above, columns_above := u32(size), u32(size)
        skyline_sum = rows_above * columns_above * u32(lowest)
        for height := lowest; height < int(tallest); height += 1 {
            rows_above -= u32(row_counts[height])
            columns_above -= u32(column_counts[height])
            skyline_sum += rows_above * columns_above
        }
    }
    return i64(skyline_sum - height_sum)
}
