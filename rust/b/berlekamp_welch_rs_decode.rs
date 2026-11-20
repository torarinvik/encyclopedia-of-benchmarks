const FIELD: i32 = 7;
const MAX_N: usize = 7;
const MAX_VARIABLES: usize = 8;
const MAX_POLYNOMIAL: usize = 8;
const MAX_INPUT_LENGTH: usize = 11;

fn normalize(value: i32) -> i32 {
    value.rem_euclid(FIELD)
}

fn trim_polynomial(polynomial: &[i32; MAX_POLYNOMIAL], length: &mut usize) {
    while *length > 1 && polynomial[*length - 1] == 0 {
        *length -= 1;
    }
}

fn solve_homogeneous(
    matrix: &mut [[i32; MAX_VARIABLES]; MAX_N],
    row_count: usize,
    variable_count: usize,
    solution: &mut [i32; MAX_VARIABLES],
) -> bool {
    const INVERSE: [i32; 7] = [0, 1, 4, 5, 2, 3, 6];
    let mut pivot_columns = [0usize; MAX_VARIABLES];
    let mut pivot_count = 0usize;
    let mut pivot_row = 0usize;

    for column in 0..variable_count {
        let mut found = None;
        for row in pivot_row..row_count {
            if matrix[row][column] != 0 {
                found = Some(row);
                break;
            }
        }
        let Some(found_row) = found else { continue };
        matrix.swap(pivot_row, found_row);

        let scale = INVERSE[matrix[pivot_row][column] as usize];
        for c in 0..variable_count {
            matrix[pivot_row][c] = normalize(matrix[pivot_row][c] * scale);
        }
        for row in 0..row_count {
            if row == pivot_row { continue; }
            let factor = matrix[row][column];
            if factor == 0 { continue; }
            for c in 0..variable_count {
                matrix[row][c] = normalize(matrix[row][c] - factor * matrix[pivot_row][c]);
            }
        }

        pivot_columns[pivot_count] = column;
        pivot_count += 1;
        pivot_row += 1;
        if pivot_row == row_count { break; }
    }

    let mut free_column = None;
    for column in 0..variable_count {
        if !pivot_columns[..pivot_count].contains(&column) {
            free_column = Some(column);
            break;
        }
    }
    let Some(free) = free_column else { return false };

    *solution = [0; MAX_VARIABLES];
    solution[free] = 1;
    for row in 0..pivot_count {
        solution[pivot_columns[row]] = normalize(-matrix[row][free]);
    }
    true
}

fn divide_polynomials(
    numerator: [i32; MAX_POLYNOMIAL],
    denominator: [i32; MAX_POLYNOMIAL],
    numerator_length: usize,
    denominator_length: usize,
    quotient: &mut [i32; MAX_POLYNOMIAL],
    quotient_length: &mut usize,
) -> bool {
    const INVERSE: [i32; 7] = [0, 1, 4, 5, 2, 3, 6];
    let mut remainder = numerator;
    let mut remainder_length = numerator_length;
    let mut divisor = denominator;
    let mut divisor_length = denominator_length;
    trim_polynomial(&remainder, &mut remainder_length);
    trim_polynomial(&divisor, &mut divisor_length);
    if divisor_length == 1 && divisor[0] == 0 { return false; }

    *quotient = [0; MAX_POLYNOMIAL];
    *quotient_length = if remainder_length >= divisor_length {
        remainder_length - divisor_length + 1
    } else {
        1
    };
    let inverse_lead = INVERSE[divisor[divisor_length - 1] as usize];
    while !(remainder_length == 1 && remainder[0] == 0)
        && remainder_length >= divisor_length
    {
        let shift = remainder_length - divisor_length;
        let factor = normalize(remainder[remainder_length - 1] * inverse_lead);
        quotient[shift] = factor;
        for index in 0..divisor_length {
            remainder[shift + index] = normalize(
                remainder[shift + index] - factor * divisor[index],
            );
        }
        trim_polynomial(&remainder, &mut remainder_length);
    }
    if remainder_length != 1 || remainder[0] != 0 { return false; }
    trim_polynomial(quotient, quotient_length);
    true
}

fn decode(n: usize, k: usize, error_limit: usize, received: &[i32; MAX_N]) -> i64 {
    let q_count = k + error_limit;
    let e_count = error_limit + 1;
    let variable_count = q_count + e_count;
    let mut matrix = [[0i32; MAX_VARIABLES]; MAX_N];
    for row in 0..n {
        let x = row as i32;
        let mut power = 1i32;
        for degree in 0..q_count {
            matrix[row][degree] = power;
            power = power * x % FIELD;
        }
        power = 1;
        for degree in 0..e_count {
            matrix[row][q_count + degree] = normalize(-received[row] * power);
            power = power * x % FIELD;
        }
    }

    let mut solution = [0i32; MAX_VARIABLES];
    if !solve_homogeneous(&mut matrix, n, variable_count, &mut solution) { return 0; }
    let mut numerator = [0i32; MAX_POLYNOMIAL];
    let mut locator = [0i32; MAX_POLYNOMIAL];
    numerator[..q_count].copy_from_slice(&solution[..q_count]);
    locator[..e_count].copy_from_slice(&solution[q_count..q_count + e_count]);
    let mut numerator_length = q_count;
    let mut locator_length = e_count;
    trim_polynomial(&numerator, &mut numerator_length);
    trim_polynomial(&locator, &mut locator_length);

    let mut coefficients = [0i32; MAX_POLYNOMIAL];
    let mut coefficient_length = 0usize;
    if !divide_polynomials(
        numerator,
        locator,
        numerator_length,
        locator_length,
        &mut coefficients,
        &mut coefficient_length,
    ) || coefficient_length > k {
        return 0;
    }

    let mut mismatches = 0usize;
    for (x, &symbol) in received[..n].iter().enumerate() {
        let mut value = 0i32;
        for degree in (0..k).rev() {
            let coefficient = if degree < coefficient_length { coefficients[degree] } else { 0 };
            value = (value * x as i32 + coefficient) % FIELD;
        }
        if value != symbol { mismatches += 1; }
    }
    if mismatches > error_limit { return 0; }

    let mut encoded = 1i64;
    let mut place = 1i64;
    for degree in 0..k {
        if degree < coefficient_length {
            encoded += i64::from(coefficients[degree]) * place;
        }
        place *= i64::from(FIELD);
    }
    encoded
}

#[no_mangle]
pub unsafe extern "C" fn berlekamp_welch_rs_decode(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let values = core::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let k_value = values[1];
    let error_value = values[2];
    if !(2..=7).contains(&n_value) || !(1..=3).contains(&k_value)
        || k_value > n_value || !(0..=2).contains(&error_value) {
        return -1;
    }
    let n = n_value as usize;
    let k = k_value as usize;
    let error_limit = error_value as usize;
    if 2 * error_limit > n - k || length != 3 + n { return -1; }

    let mut received = [0i32; MAX_N];
    for index in 0..n {
        let symbol = values[3 + index];
        if !(0..7).contains(&symbol) { return -1; }
        received[index] = symbol as i32;
    }
    decode(n, k, error_limit, &received)
}
