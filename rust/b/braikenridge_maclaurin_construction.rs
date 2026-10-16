/// Compute the six exact 5x5 determinant coefficients of a conic.
fn determinant(features: &[[i64; 6]; 5], columns: &[usize; 5]) -> i64 {
    let mut paths = [0_i64; 32];
    paths[0] = 1;
    for row in 0..5 {
        let mut next = [0_i64; 32];
        for mask in 0_usize..32 {
            if mask.count_ones() as usize != row || paths[mask] == 0 { continue; }
            for column in 0..5 {
                let bit = 1_usize << column;
                if mask & bit != 0 { continue; }
                let inversions = ((column + 1)..5)
                    .filter(|previous| mask & (1_usize << *previous) != 0)
                    .count();
                let term = paths[mask] * features[row][columns[column]];
                next[mask | bit] += if inversions % 2 == 0 { term } else { -term };
            }
        }
        paths = next;
    }
    paths[31]
}

#[no_mangle]
pub extern "C" fn braikenridge_maclaurin_construction(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length != 10 { return -2; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut features = [[0_i64; 6]; 5];
    for point in 0..5 {
        let x = values[2 * point];
        let y = values[2 * point + 1];
        if !(-10..=10).contains(&x) || !(-10..=10).contains(&y) { return -2; }
        features[point] = [x * x, x * y, y * y, x, y, 1];
    }
    const COLUMNS: [[usize; 5]; 6] = [
        [1, 2, 3, 4, 5], [0, 2, 3, 4, 5], [0, 1, 3, 4, 5],
        [0, 1, 2, 4, 5], [0, 1, 2, 3, 5], [0, 1, 2, 3, 4],
    ];
    const SIGNS: [i64; 6] = [1, -1, 1, -1, 1, -1];
    let mut coefficients = [0_i64; 6];
    for index in 0..6 {
        coefficients[index] = SIGNS[index] * determinant(&features, &COLUMNS[index]);
    }
    if output_capacity < 48 || output.is_null() { return -2; }
    for index in 0..6 {
        let bytes = coefficients[index].to_le_bytes();
        unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(index * 8), 8); }
    }
    6
}
