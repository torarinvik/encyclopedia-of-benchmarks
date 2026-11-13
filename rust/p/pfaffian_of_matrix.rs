const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 8;
const MAX_DIMENSION: usize = 16;
const MAX_PARSEABLE: usize = 258;

fn normalize(value: i64) -> i64 {
    let remainder = value % MODULUS;
    if remainder < 0 { remainder + MODULUS } else { remainder }
}

fn multiply(left: i64, right: i64) -> i64 { (left * right) % MODULUS }

fn power(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1;
    while exponent > 0 {
        if exponent & 1 != 0 { result = multiply(result, base); }
        base = multiply(base, base);
        exponent >>= 1;
    }
    result
}

fn solve(input: &[i64]) -> i64 {
    if input.len() < 5 || input.len() > MAX_PARSEABLE { return -1; }
    if !(1..=MAX_N as i64).contains(&input[0]) { return -1; }
    let dimension = 2 * input[0] as usize;
    if input.len() != 1 + dimension * dimension { return -1; }

    let mut matrix = [0i64; MAX_DIMENSION * MAX_DIMENSION];
    for row in 0..dimension {
        for column in 0..dimension {
            let value = input[1 + row * dimension + column];
            if !(0..MODULUS).contains(&value) { return -1; }
            matrix[row * MAX_DIMENSION + column] = value;
        }
    }
    for row in 0..dimension {
        if matrix[row * MAX_DIMENSION + row] != 0 { return -1; }
        for column in row + 1..dimension {
            if (matrix[row * MAX_DIMENSION + column]
                    + matrix[column * MAX_DIMENSION + row]) % MODULUS != 0 {
                return -1;
            }
        }
    }

    let mut result = 1;
    for pivot_index in (0..dimension).step_by(2) {
        let mut partner = pivot_index + 1;
        while partner < dimension && matrix[pivot_index * MAX_DIMENSION + partner] == 0 {
            partner += 1;
        }
        if partner == dimension { return 0; }
        if partner != pivot_index + 1 {
            let swapped = pivot_index + 1;
            for k in 0..dimension {
                matrix.swap(swapped * MAX_DIMENSION + k, partner * MAX_DIMENSION + k);
            }
            for k in 0..dimension {
                matrix.swap(k * MAX_DIMENSION + swapped, k * MAX_DIMENSION + partner);
            }
            result = if result == 0 { 0 } else { MODULUS - result };
        }

        let first = pivot_index * MAX_DIMENSION;
        let second = (pivot_index + 1) * MAX_DIMENSION;
        let pivot = matrix[first + pivot_index + 1];
        result = multiply(result, pivot);
        let inverse = power(pivot, MODULUS - 2);
        for row in pivot_index + 2..dimension {
            for column in row + 1..dimension {
                let cross = normalize(
                    multiply(matrix[first + row], matrix[second + column])
                    - multiply(matrix[first + column], matrix[second + row]));
                let value = normalize(matrix[row * MAX_DIMENSION + column]
                    - multiply(cross, inverse));
                matrix[row * MAX_DIMENSION + column] = value;
                matrix[column * MAX_DIMENSION + row] = if value == 0 { 0 } else { MODULUS - value };
            }
        }
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn pfaffian_of_matrix(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 5 || length > MAX_PARSEABLE { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
