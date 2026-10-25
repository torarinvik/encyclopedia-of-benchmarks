/* NAS Parallel Benchmarks 3.3 DC source notice:
 * Permission to use, copy, distribute and modify this software for any purpose
 * with or without fee is hereby granted. We request, however, that all derived
 * work reference the NAS Parallel Benchmarks 3.3. This software is provided
 * "as is" without express or implied warranty.
 *
 * Clean-room bounded adaptation: packed input and ordered scalar checksum
 * replace generated files and the original memory management harness.
 */
const MAX_DIMS: usize = 5;
const MAX_ROWS: usize = 16;

#[no_mangle]
pub unsafe extern "C" fn npb_serial_dc(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > 98 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_DIMS as i64 || values[1] < 1 || values[1] > MAX_ROWS as i64 { return -1; }
    let dimensions = values[0] as usize;
    let rows = values[1] as usize;
    if length != 2 + rows * (dimensions + 1) { return -1; }

    let mut attributes = [[0i64; MAX_DIMS]; MAX_ROWS];
    let mut measures = [0i64; MAX_ROWS];
    let mut offset = 2;
    for row in 0..rows {
        for dimension in 0..dimensions {
            let value = values[offset];
            offset += 1;
            if !(0..=7).contains(&value) { return -1; }
            attributes[row][dimension] = value;
        }
        measures[row] = values[offset];
        offset += 1;
        if !(0..=1000).contains(&measures[row]) { return -1; }
    }

    let mut checksum = 0i64;
    for mask in 1..(1usize << dimensions) {
        let mut keys = [[0i64; MAX_DIMS]; MAX_ROWS];
        let mut sums = [0i64; MAX_ROWS];
        let mut group_count = 0usize;
        for row in 0..rows {
            let mut group = 0;
            while group < group_count {
                let mut equal = true;
                for dimension in 0..dimensions {
                    if (mask & (1 << dimension)) != 0 && keys[group][dimension] != attributes[row][dimension] { equal = false; }
                }
                if equal { break; }
                group += 1;
            }
            if group == group_count {
                for dimension in 0..dimensions {
                    if (mask & (1 << dimension)) != 0 { keys[group][dimension] = attributes[row][dimension]; }
                }
                sums[group] = measures[row];
                group_count += 1;
            } else { sums[group] += measures[row]; }
        }
        for index in 1..group_count {
            let mut position = index;
            while position > 0 {
                let mut comparison = 0;
                for dimension in 0..dimensions {
                    if (mask & (1 << dimension)) == 0 { continue; }
                    if keys[position][dimension] < keys[position - 1][dimension] { comparison = -1; break; }
                    if keys[position][dimension] > keys[position - 1][dimension] { comparison = 1; break; }
                }
                if comparison >= 0 { break; }
                keys.swap(position, position - 1);
                sums.swap(position, position - 1);
                position -= 1;
            }
        }
        let view = mask as i64;
        checksum += view * 1009 + group_count as i64 * 9176;
        for group in 0..group_count {
            checksum += (view + 1) * (group + 1) as i64 * (sums[group] + 13);
            for dimension in 0..dimensions {
                if (mask & (1 << dimension)) != 0 {
                    checksum += (dimension + 1) as i64 * (keys[group][dimension] + 1) * (group + 3) as i64 * (view + 5);
                }
            }
        }
    }
    checksum
}
