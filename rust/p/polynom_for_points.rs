const MIN_POINTS: usize = 2;
const MAX_POINTS: usize = 8;
const MIN_X: i64 = -4;
const MAX_X: i64 = 4;
const MIN_Y: i64 = -25_000;
const MAX_Y: i64 = 25_000;
const MAX_COEFFICIENT: f64 = 1_000_000.0;
const MAX_CONTRACT_BYTES: usize = 124;
const SCRATCH_BYTES: usize = 125;

fn append_text(buffer: &mut [u8; SCRATCH_BYTES], mut position: usize, text: &[u8]) -> usize {
    for byte in text { buffer[position] = *byte; position += 1; }
    position
}

fn append_i64(buffer: &mut [u8; SCRATCH_BYTES], mut position: usize, mut value: i64) -> usize {
    let mut digits = [0u8; 24];
    let mut count = 0;
    if value < 0 { buffer[position] = b'-'; position += 1; value = -value; }
    loop {
        digits[count] = b'0' + (value % 10) as u8;
        count += 1;
        value /= 10;
        if value == 0 { break; }
    }
    while count > 0 { count -= 1; buffer[position] = digits[count]; position += 1; }
    position
}

fn append_coefficient(buffer: &mut [u8; SCRATCH_BYTES], mut position: usize, value: f64) -> usize {
    if value == 0.0 {
        if value.to_bits() >> 63 != 0 { buffer[position] = b'-'; position += 1; }
        return append_text(buffer, position, b"0.0");
    }
    position = append_i64(buffer, position, value as i64);
    append_text(buffer, position, b".0")
}

#[no_mangle]
pub unsafe extern "C" fn polynom_for_points(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > 1 + 2 * MAX_POINTS { return -1; }
    let raw_n = *values;
    if raw_n < MIN_POINTS as i64 || raw_n > MAX_POINTS as i64 || length != 1 + 2 * raw_n as usize {
        return -1;
    }
    let n = raw_n as usize;
    let mut xs = [0i64; MAX_POINTS];
    let mut matrix = [[0.0f64; MAX_POINTS]; MAX_POINTS];
    let mut vector = [0.0f64; MAX_POINTS];
    for row in 0..n {
        let x = *values.add(1 + 2 * row);
        let y = *values.add(2 + 2 * row);
        if !(MIN_X..=MAX_X).contains(&x) || !(MIN_Y..=MAX_Y).contains(&y) { return -1; }
        for previous in 0..row { if xs[previous] == x { return -1; } }
        xs[row] = x;
        for column in 0..n {
            let mut power = 1i64;
            for _ in 0..(n - column - 1) { power *= x; }
            matrix[row][column] = power as f64;
        }
        vector[row] = y as f64;
    }

    for count in 0..n {
        if matrix[count][count] == 0.0 {
            let mut pivot_row = count + 1;
            for row in count + 2..n {
                if matrix[row][count].abs() > matrix[pivot_row][count].abs() { pivot_row = row; }
            }
            if pivot_row >= n || matrix[pivot_row][count] == 0.0 { return -1; }
            for column in 0..n { let temporary = matrix[count][column]; matrix[count][column] = matrix[pivot_row][column]; matrix[pivot_row][column] = temporary; }
            let temporary = vector[count]; vector[count] = vector[pivot_row]; vector[pivot_row] = temporary;
        }
        for row in 0..n {
            if row == count { continue; }
            let fraction = matrix[row][count] / matrix[count][count];
            for column in 0..n {
                let product = matrix[count][column] * fraction;
                matrix[row][column] = matrix[row][column] - product;
            }
            let product = vector[count] * fraction;
            vector[row] = vector[row] - product;
        }
    }

    let mut coefficients = [0.0f64; MAX_POINTS];
    for index in 0..n {
        let value = vector[index] / matrix[index][index];
        if !value.is_finite() || value.abs() > MAX_COEFFICIENT || value.trunc() != value { return -1; }
        coefficients[index] = value;
    }

    let mut buffer = [0u8; SCRATCH_BYTES];
    let mut position = append_text(&mut buffer, 0, b"f(x)=");
    for index in 0..n {
        if index != 0 { buffer[position] = b'+'; position += 1; }
        position = append_text(&mut buffer, position, b"x^");
        position = append_i64(&mut buffer, position, (n - index - 1) as i64);
        buffer[position] = b'*'; position += 1;
        position = append_coefficient(&mut buffer, position, coefficients[index]);
    }
    if position > MAX_CONTRACT_BYTES { return -1; }
    if output.is_null() || output_capacity < position { return -2; }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, position);
    position as i64
}
