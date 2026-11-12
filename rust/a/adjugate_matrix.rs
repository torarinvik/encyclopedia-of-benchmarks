const MAX_N: usize = 6;
const MODULUS: i64 = 998_244_353;

fn minor_determinant(matrix: &[i64; MAX_N * MAX_N], n: usize,
                     skip_row: usize, skip_column: usize) -> i64 {
    let dimension = n - 1;
    if dimension == 0 {
        return 1;
    }

    let mut minor = [0i64; MAX_N * MAX_N];
    let mut target_row = 0;
    for row in 0..n {
        if row == skip_row { continue; }
        let mut target_column = 0;
        for column in 0..n {
            if column == skip_column { continue; }
            minor[target_row * dimension + target_column] = matrix[row * n + column];
            target_column += 1;
        }
        target_row += 1;
    }

    let mut dp = [0i64; 1 << (MAX_N - 1)];
    dp[0] = 1;
    let limit = 1usize << dimension;
    for mask in 0..limit {
        let row = mask.count_ones() as usize;
        if row == dimension { continue; }
        for column in 0..dimension {
            if mask & (1 << column) != 0 { continue; }
            let inversions = ((mask >> (column + 1)) as usize).count_ones();
            let next = mask | (1 << column);
            let term = dp[mask] * minor[row * dimension + column] % MODULUS;
            let signed_term = if inversions & 1 == 0 { term } else { -term };
            dp[next] = (dp[next] + signed_term + MODULUS) % MODULUS;
        }
    }
    dp[limit - 1]
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn adjugate_matrix(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 1 + MAX_N * MAX_N { return -1; }
    let n_value = *input;
    if !(1..=MAX_N as i64).contains(&n_value) { return -1; }
    let n = n_value as usize;
    if length != 1 + n * n { return -1; }

    let mut matrix = [0i64; MAX_N * MAX_N];
    for index in 0..n * n {
        let value = *input.add(1 + index);
        if !(0..MODULUS).contains(&value) { return -1; }
        matrix[index] = value;
    }

    let output_bytes = 8 * n * n;
    if output.is_null() || capacity < output_bytes { return -2; }
    for row in 0..n {
        for column in 0..n {
            let mut value = minor_determinant(&matrix, n, column, row);
            if (row + column) & 1 != 0 && value != 0 { value = MODULUS - value; }
            store_i64_le(output, 8 * (row * n + column), value);
        }
    }
    output_bytes as i64
}
