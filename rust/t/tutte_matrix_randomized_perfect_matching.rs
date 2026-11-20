const MAX_N: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_INPUT: usize = 87;
const MAX_OUTPUT: usize = 80;
const PRIME: i64 = 65_521;

fn norm(value: i64) -> i64 {
    value.rem_euclid(PRIME)
}

fn power(base: i64, mut exponent: u64) -> i64 {
    let mut result = 1i64;
    let mut factor = norm(base);
    while exponent != 0 {
        if exponent & 1 != 0 { result = result * factor % PRIME; }
        factor = factor * factor % PRIME;
        exponent >>= 1;
    }
    result
}

fn store_word(bytes: &mut [u8; MAX_OUTPUT], word: usize, value: i64) {
    bytes[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

fn eliminate(inverse: &mut [i64; MAX_N * MAX_N], rows: &mut [bool; MAX_N],
             columns: &mut [bool; MAX_N], n: usize, pivot_row: usize,
             pivot_column: usize) -> bool {
    let old = *inverse;
    let pivot = old[pivot_row * MAX_N + pivot_column];
    if pivot == 0 { return false; }
    let inverse_pivot = power(pivot, (PRIME - 2) as u64);
    for row in 0..n {
        for column in 0..n {
            let index = row * MAX_N + column;
            if rows[row] && row != pivot_row && columns[column] && column != pivot_column {
                let correction = old[row * MAX_N + pivot_column] *
                                 old[pivot_row * MAX_N + column] % PRIME;
                inverse[index] = norm(old[index] - correction * inverse_pivot);
            } else {
                inverse[index] = 0;
            }
        }
    }
    rows[pivot_row] = false;
    columns[pivot_column] = false;
    true
}

#[no_mangle]
pub unsafe extern "C" fn tutte_matrix_randomized_perfect_matching(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let edge_count_value = values[1];
    if n_value < 2 || n_value > MAX_N as i64 || n_value & 1 != 0 ||
        edge_count_value < 0 || edge_count_value > MAX_EDGES as i64 { return -1; }
    let n = n_value as usize;
    let edge_count = edge_count_value as usize;
    if edge_count > n * (n - 1) / 2 || length != 2 + 3 * edge_count { return -1; }

    let mut matrix = [0i64; MAX_N * MAX_N];
    let mut previous = (-1i64, -1i64);
    for edge in 0..edge_count {
        let u_value = values[2 + 3 * edge];
        let v_value = values[3 + 3 * edge];
        let substitution = values[4 + 3 * edge];
        if u_value < 0 || v_value <= u_value || v_value >= n as i64 ||
            (u_value, v_value) <= previous || substitution < 1 || substitution >= PRIME {
            return -1;
        }
        let u = u_value as usize;
        let v = v_value as usize;
        matrix[u * MAX_N + v] = substitution;
        matrix[v * MAX_N + u] = PRIME - substitution;
        previous = (u_value, v_value);
    }

    let mut augmented = [[0i64; 2 * MAX_N]; MAX_N];
    for row in 0..n {
        for column in 0..n { augmented[row][column] = matrix[row * MAX_N + column]; }
        augmented[row][n + row] = 1;
    }
    let mut singular = false;
    for column in 0..n {
        let mut pivot_row = column;
        while pivot_row < n && augmented[pivot_row][column] == 0 { pivot_row += 1; }
        if pivot_row == n { singular = true; break; }
        augmented.swap(column, pivot_row);
        let inverse_pivot = power(augmented[column][column], (PRIME - 2) as u64);
        for j in 0..2 * n { augmented[column][j] = augmented[column][j] * inverse_pivot % PRIME; }
        for row in 0..n {
            if row == column { continue; }
            let factor = augmented[row][column];
            if factor == 0 { continue; }
            for j in 0..2 * n {
                augmented[row][j] = norm(augmented[row][j] - factor * augmented[column][j]);
            }
        }
    }

    let mut result = [0i64; 2 + MAX_N];
    let mut result_size = 2usize;
    if !singular {
        let mut inverse = [0i64; MAX_N * MAX_N];
        for row in 0..n {
            for column in 0..n { inverse[row * MAX_N + column] = augmented[row][n + column]; }
        }
        let mut rows = [false; MAX_N];
        let mut columns = [false; MAX_N];
        for i in 0..n { rows[i] = true; columns[i] = true; }
        let mut failed = false;
        for vertex in 0..n {
            if !columns[vertex] { continue; }
            let mut partner = None;
            for candidate in 0..n {
                if rows[candidate] && candidate != vertex &&
                    matrix[vertex * MAX_N + candidate] != 0 &&
                    inverse[candidate * MAX_N + vertex] != 0 {
                    partner = Some(candidate);
                    break;
                }
            }
            let Some(other) = partner else { failed = true; break; };
            if result_size + 2 > result.len() { failed = true; break; }
            result[result_size] = vertex as i64;
            result[result_size + 1] = other as i64;
            result_size += 2;
            if !eliminate(&mut inverse, &mut rows, &mut columns, n, other, vertex) ||
                !eliminate(&mut inverse, &mut rows, &mut columns, n, vertex, other) {
                failed = true;
                break;
            }
        }
        if failed { result_size = 2; }
        else { result[0] = 1; result[1] = (n / 2) as i64; }
    }

    let output_bytes = result_size * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    for word in 0..result_size { store_word(&mut staged, word, result[word]); }
    for byte in 0..output_bytes { *output.add(byte) = staged[byte]; }
    output_bytes as i64
}
