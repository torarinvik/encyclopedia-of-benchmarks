const MAX_N: usize = 16;
const MOD: i64 = 998_244_353;
const MAX_INPUT_VALUES: usize = 1 + MAX_N * MAX_N;
const STATES: usize = 1 << MAX_N;

unsafe fn store_i64_le(output: *mut u8, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn hafnian_of_matrix(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let n_value = *input;
    if n_value < 2 || n_value > MAX_N as i64 || n_value % 2 != 0 {
        return -1;
    }
    let n = n_value as usize;
    if length != 1 + n * n {
        return -1;
    }

    let mut matrix = [[0i64; MAX_N]; MAX_N];
    for row in 0..n {
        for column in 0..n {
            let value = *input.add(1 + row * n + column);
            if value < 0 || value >= MOD || (row == column && value != 0) {
                return -1;
            }
            matrix[row][column] = value;
        }
    }
    for row in 0..n {
        for column in 0..row {
            if matrix[row][column] != matrix[column][row] {
                return -1;
            }
        }
    }

    let mut dp = [0i64; STATES];
    dp[0] = 1;
    let full = (1usize << n) - 1;
    for mask in 1..=full {
        if mask.count_ones() % 2 != 0 {
            continue;
        }
        let first = mask.trailing_zeros() as usize;
        let without_first = mask ^ (1usize << first);
        for second in first + 1..n {
            let bit = 1usize << second;
            if without_first & bit == 0 {
                continue;
            }
            let rest = without_first ^ bit;
            dp[mask] = (dp[mask] + matrix[first][second] * dp[rest]) % MOD;
        }
    }

    if output.is_null() || capacity < 8 {
        return -2;
    }
    store_i64_le(output, dp[full]);
    8
}
