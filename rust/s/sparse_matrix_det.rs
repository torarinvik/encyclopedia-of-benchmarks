const MOD: i64 = 998_244_353;
const MAX_N: usize = 8;
const MAX_K: usize = 64;
const MAX_PARSEABLE_INPUT: usize = 2 + 3 * MAX_K + 1;
const ATTEMPTS: usize = 4;

fn add_mod(a: i64, b: i64) -> i64 {
    let value = a + b;
    if value >= MOD { value - MOD } else { value }
}
fn sub_mod(a: i64, b: i64) -> i64 {
    let value = a - b;
    if value < 0 { value + MOD } else { value }
}
fn mul_mod(a: i64, b: i64) -> i64 { (a * b) % MOD }
fn pow_mod(mut value: i64, mut exponent: i64) -> i64 {
    let mut result = 1;
    while exponent > 0 {
        if exponent & 1 != 0 { result = mul_mod(result, value); }
        value = mul_mod(value, value);
        exponent >>= 1;
    }
    result
}
fn next_residue(state: &mut i64) -> i64 {
    *state = (*state * 48_271 + 1) % MOD;
    *state
}

fn berlekamp_massey(sequence: &[i64], connection: &mut [i64; MAX_N + 1]) -> usize {
    let mut previous = [0i64; MAX_N + 1];
    let mut temporary = [0i64; MAX_N + 1];
    connection.fill(0);
    connection[0] = 1;
    previous[0] = 1;
    let (mut degree, mut shift, mut previous_degree) = (0usize, 1usize, 0usize);
    let mut last_discrepancy = 1i64;
    for index in 0..sequence.len() {
        let mut discrepancy = sequence[index];
        for i in 1..=degree {
            discrepancy = add_mod(discrepancy, mul_mod(connection[i], sequence[index - i]));
        }
        if discrepancy == 0 {
            shift += 1;
            continue;
        }
        temporary = *connection;
        let scale = mul_mod(discrepancy, pow_mod(last_discrepancy, MOD - 2));
        for i in 0..=previous_degree {
            let target = i + shift;
            if target <= MAX_N {
                connection[target] = sub_mod(connection[target], mul_mod(scale, previous[i]));
            }
        }
        if 2 * degree <= index {
            let old_degree = degree;
            degree = index + 1 - degree;
            previous = temporary;
            previous_degree = old_degree;
            last_discrepancy = discrepancy;
            shift = 1;
        } else {
            shift += 1;
        }
    }
    degree
}

fn dense_determinant(row: &[usize; MAX_K], column: &[usize; MAX_K],
                     entry: &[i64; MAX_K], n: usize, k: usize) -> i64 {
    let mut matrix = [[0i64; MAX_N]; MAX_N];
    for e in 0..k { matrix[row[e]][column[e]] = entry[e]; }
    let mut determinant = 1i64;
    for c in 0..n {
        let mut pivot = c;
        while pivot < n && matrix[pivot][c] == 0 { pivot += 1; }
        if pivot == n { return 0; }
        if pivot != c {
            matrix.swap(pivot, c);
            determinant = MOD - determinant;
        }
        let pivot_value = matrix[c][c];
        determinant = mul_mod(determinant, pivot_value);
        let inverse = pow_mod(pivot_value, MOD - 2);
        for i in c + 1..n {
            if matrix[i][c] == 0 { continue; }
            let factor = mul_mod(matrix[i][c], inverse);
            for j in c + 1..n {
                matrix[i][j] = sub_mod(matrix[i][j], mul_mod(factor, matrix[c][j]));
            }
            matrix[i][c] = 0;
        }
    }
    determinant
}

fn sparse_wiedemann(row: &[usize; MAX_K], column: &[usize; MAX_K],
        entry: &[i64; MAX_K], n: usize, k: usize, seed: i64) -> Option<i64> {
    let mut state = seed;
    let mut diagonal = [0i64; MAX_N];
    let mut left = [0i64; MAX_N];
    let mut vector = [0i64; MAX_N];
    let mut next = [0i64; MAX_N];
    let mut weighted = [0i64; MAX_N];
    let mut diagonal_product = 1i64;
    for i in 0..n {
        diagonal[i] = next_residue(&mut state);
        if diagonal[i] == 0 { diagonal[i] = 1; }
        left[i] = next_residue(&mut state);
        vector[i] = next_residue(&mut state);
        diagonal_product = mul_mod(diagonal_product, diagonal[i]);
    }
    let mut sequence = [0i64; 2 * MAX_N];
    for step in 0..2 * n {
        let mut dot = 0i64;
        for i in 0..n { dot = add_mod(dot, mul_mod(left[i], vector[i])); }
        sequence[step] = dot;
        for i in 0..n { weighted[i] = mul_mod(diagonal[i], vector[i]); }
        next.fill(0);
        for e in 0..k {
            next[row[e]] = add_mod(next[row[e]], mul_mod(entry[e], weighted[column[e]]));
        }
        vector = next;
    }
    let mut connection = [0i64; MAX_N + 1];
    if berlekamp_massey(&sequence[..2 * n], &mut connection) != n { return None; }
    let mut constant = connection[n];
    if n & 1 != 0 && constant != 0 { constant = MOD - constant; }
    Some(mul_mod(constant, pow_mod(diagonal_product, MOD - 2)))
}

unsafe fn store_i64_le(output: *mut u8, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn sparse_matrix_det(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT { return -1; }
    let n_value = *input;
    let k_value = *input.add(1);
    if n_value < 1 || n_value > MAX_N as i64 || k_value < 1 || k_value > MAX_K as i64 { return -1; }
    let n = n_value as usize;
    let k = k_value as usize;
    if length != 2 + 3 * k { return -1; }
    let mut seen = [[false; MAX_N]; MAX_N];
    let mut row = [0usize; MAX_K];
    let mut column = [0usize; MAX_K];
    let mut entry = [0i64; MAX_K];
    for e in 0..k {
        let r = *input.add(2 + 3 * e);
        let c = *input.add(3 + 3 * e);
        let value = *input.add(4 + 3 * e);
        if r < 0 || r >= n as i64 || c < 0 || c >= n as i64 || value < 1 || value >= MOD { return -1; }
        let (r, c) = (r as usize, c as usize);
        if seen[r][c] { return -1; }
        seen[r][c] = true;
        row[e] = r; column[e] = c; entry[e] = value;
    }
    let mut determinant = None;
    for attempt in 0..ATTEMPTS {
        let seed = 104_729 + attempt as i64 * 1_000_003;
        determinant = sparse_wiedemann(&row, &column, &entry, n, k, seed);
        if determinant.is_some() { break; }
    }
    let value = determinant.unwrap_or_else(|| dense_determinant(&row, &column, &entry, n, k));
    if output.is_null() || capacity < 8 { return -2; }
    store_i64_le(output, value);
    8
}
