/// Return the total allowable increase while preserving row and column skylines.
#[no_mangle]
pub extern "C" fn max_increase_keeping_skyline(values: *const i64, length: usize) -> i64 {
    const MAX_GRID_SIZE: usize = 50;
    if values.is_null() || length < 2 || length > 1 + MAX_GRID_SIZE * MAX_GRID_SIZE { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < 2 || values[0] > MAX_GRID_SIZE as i64 { return -1; }
    let size = values[0] as usize;
    if length != 1 + size * size { return -1; }

    let mut row_max = [0u8; MAX_GRID_SIZE];
    let mut column_max = [0u8; MAX_GRID_SIZE];
    let mut tallest = 0u64;
    let mut height_sum = 0u32;
    for (row, heights) in values[1..].chunks_exact(size).enumerate() {
        let mut row_tallest = 0u8;
        for (&value, column_tallest) in heights.iter().zip(column_max.iter_mut()) {
            let value = value as u64;
            tallest = tallest.max(value);
            height_sum = height_sum.wrapping_add(value as u32);
            let height = value as u8;
            row_tallest = row_tallest.max(height);
            *column_tallest = (*column_tallest).max(height);
        }
        row_max[row] = row_tallest;
    }
    if tallest > 100 { return -1; }

    let mut skyline_sum = 0u32;
    if size <= 10 {
        for &row_height in &row_max[..size] {
            for &column_height in &column_max[..size] {
                skyline_sum += u32::from(row_height.min(column_height));
            }
        }
    } else {
        let mut row_counts = [0u8; 101];
        let mut column_counts = [0u8; 101];
        let mut lowest = 100u8;
        for index in 0..size {
            lowest = lowest.min(row_max[index]).min(column_max[index]);
            row_counts[usize::from(row_max[index])] += 1;
            column_counts[usize::from(column_max[index])] += 1;
        }
        let mut rows_above = size as u32;
        let mut columns_above = size as u32;
        skyline_sum = rows_above * columns_above * u32::from(lowest);
        for height in usize::from(lowest)..tallest as usize {
            rows_above -= u32::from(row_counts[height]);
            columns_above -= u32::from(column_counts[height]);
            skyline_sum += rows_above * columns_above;
        }
    }
    i64::from(skyline_sum - height_sum)
}
