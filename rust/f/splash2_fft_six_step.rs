const MAX_POINTS: usize = 64;
const MAX_OUTPUT: usize = 128;
const TAU: f64 = 6.283185307179586476925286766559;

fn transpose(source: &[f64; MAX_OUTPUT], destination: &mut [f64; MAX_OUTPUT], side: usize) {
    for row in 0..side {
        for column in 0..side {
            let from = 2 * (row * side + column);
            let to = 2 * (column * side + row);
            destination[to] = source[from];
            destination[to + 1] = source[from + 1];
        }
    }
}

fn fft_row(data: &mut [f64; MAX_OUTPUT], base: usize, side: usize) {
    let mut reverse = 0usize;
    for position in 1..side {
        let mut bit = side >> 1;
        while reverse & bit != 0 {
            reverse ^= bit;
            bit >>= 1;
        }
        reverse ^= bit;
        if position < reverse {
            let left = 2 * (base + position);
            let right = 2 * (base + reverse);
            data.swap(left, right);
            data.swap(left + 1, right + 1);
        }
    }
    let mut block = 2usize;
    while block <= side {
        let half = block / 2;
        let angle_step = TAU / block as f64;
        for start in (0..side).step_by(block) {
            for offset in 0..half {
                let angle = angle_step * offset as f64;
                let weight_real = angle.cos();
                let weight_imag = -angle.sin();
                let first = 2 * (base + start + offset);
                let second = 2 * (base + start + offset + half);
                let product_real = weight_real * data[second] - weight_imag * data[second + 1];
                let product_imag = weight_real * data[second + 1] + weight_imag * data[second];
                let first_real = data[first];
                let first_imag = data[first + 1];
                data[first] = first_real + product_real;
                data[first + 1] = first_imag + product_imag;
                data[second] = first_real - product_real;
                data[second + 1] = first_imag - product_imag;
            }
        }
        block *= 2;
    }
}

#[no_mangle]
pub unsafe extern "C" fn splash2_fft_six_step(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(9..=130).contains(&input_length) {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }
    let side = match values[0] {
        2.0 => 2,
        4.0 => 4,
        8.0 => 8,
        _ => return -1,
    };
    let points = side * side;
    if input_length != 1 + 2 * points
        || values[1..].iter().any(|value| !(-8.0..=8.0).contains(value))
    {
        return -1;
    }

    let mut first_matrix = [0.0; MAX_OUTPUT];
    let mut second_matrix = [0.0; MAX_OUTPUT];
    first_matrix[..2 * points].copy_from_slice(&values[1..]);
    transpose(&first_matrix, &mut second_matrix, side);
    for row in 0..side {
        fft_row(&mut second_matrix, row * side, side);
    }
    for row in 0..side {
        for column in 0..side {
            let index = 2 * (row * side + column);
            let angle = TAU * (row * column) as f64 / points as f64;
            let cosine = angle.cos();
            let sine = angle.sin();
            let real = second_matrix[index];
            let imag = second_matrix[index + 1];
            second_matrix[index] = cosine * real + sine * imag;
            second_matrix[index + 1] = cosine * imag - sine * real;
        }
    }
    transpose(&second_matrix, &mut first_matrix, side);
    for row in 0..side {
        fft_row(&mut first_matrix, row * side, side);
    }
    transpose(&first_matrix, &mut second_matrix, side);

    let needed = 2 * points;
    if output.is_null() || output_capacity < needed {
        return -2;
    }
    for index in 0..needed {
        unsafe { *output.add(index) = second_matrix[index] };
    }
    needed as i64
}
