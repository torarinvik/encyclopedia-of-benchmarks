module max_increase_keeping_skyline

// Return the total allowable increase while preserving row and column skylines.
@[export: 'max_increase_keeping_skyline']
pub fn max_increase_keeping_skyline(values &i64, length usize) i64 {
	if length < 2 || length > 2501 { return -1 }
	n_value := unsafe { values[0] }
	if n_value < 2 || n_value > 50 { return -1 }
	n := int(n_value)
	if length != usize(1 + n * n) { return -1 }

    mut row_max := [50]u8{}
    mut column_max := [50]u8{}
    mut tallest := u64(0)
    mut height_sum := u32(0)
    for row in 0 .. n {
        mut row_tallest := u8(0)
        start := 1 + row * n
        for column in 0 .. n {
            value := u64(unsafe { values[start + column] })
            if value > tallest { tallest = value }
            height_sum += u32(value)
            height := u8(value)
            if height > row_tallest { row_tallest = height }
            if height > column_max[column] { column_max[column] = height }
        }
        row_max[row] = row_tallest
    }
    if tallest > 100 { return -1 }

    mut skyline_sum := u32(0)
    if n <= 10 {
        for row in 0 .. n {
            for column in 0 .. n {
                row_height := row_max[row]
                column_height := column_max[column]
                skyline_sum += u32(if row_height < column_height { row_height } else { column_height })
            }
        }
    } else {
        mut row_counts := [101]u8{}
        mut column_counts := [101]u8{}
        mut lowest := u8(100)
        for index in 0 .. n {
            if row_max[index] < lowest { lowest = row_max[index] }
            if column_max[index] < lowest { lowest = column_max[index] }
            row_counts[row_max[index]]++
            column_counts[column_max[index]]++
        }
        mut rows_above := u32(n)
        mut columns_above := u32(n)
        skyline_sum = rows_above * columns_above * u32(lowest)
        for height in int(lowest) .. int(tallest) {
            rows_above -= u32(row_counts[height])
            columns_above -= u32(column_counts[height])
            skyline_sum += rows_above * columns_above
        }
    }
    return i64(skyline_sum - height_sum)
}
