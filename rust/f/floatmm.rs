const SIDE: usize = 40;
const MAX_PASSES: i64 = 40;
const MAX_OUTPUT_BYTES: usize = 14 * SIDE;

#[inline(never)]
fn rounded_add(left: f32, right: f32) -> f32 { left + right }

#[inline(never)]
fn rounded_mul(left: f32, right: f32) -> f32 { left * right }

#[inline(never)]
fn rounded_div(left: f32, right: f32) -> f32 { left / right }

fn next_random(seed: &mut u32) -> u32 {
    *seed = (*seed * 1309 + 13849) & 65535;
    *seed
}

fn compute_diagonal_cell(selected: usize) -> f32 {
    let mut left = [[0.0_f32; SIDE]; SIDE];
    let mut right = [[0.0_f32; SIDE]; SIDE];
    let mut result = [[0.0_f32; SIDE]; SIDE];
    let mut seed = 74755_u32;
    for row in 0..SIDE {
        for column in 0..SIDE {
            let temp = next_random(&mut seed);
            let remainder = (temp - (temp / 120) * 120) as i32;
            left[row][column] = rounded_div((remainder - 60) as f32, 3.0);
        }
    }
    for row in 0..SIDE {
        for column in 0..SIDE {
            let temp = next_random(&mut seed);
            let remainder = (temp - (temp / 120) * 120) as i32;
            right[row][column] = rounded_div((remainder - 60) as f32, 3.0);
        }
    }
    for row in 0..SIDE {
        for column in 0..SIDE {
            let mut total = 0.0_f32;
            for inner in 0..SIDE {
                let product = rounded_mul(left[row][inner], right[inner][column]);
                total = rounded_add(total, product);
            }
            result[row][column] = total;
        }
    }
    result[selected][selected]
}

fn write_unsigned(mut value: u64, output: &mut [u8], offset: usize) -> usize {
    let mut reversed = [0_u8; 24];
    let mut count = 0;
    loop {
        reversed[count] = b'0' + (value % 10) as u8;
        count += 1;
        value /= 10;
        if value == 0 { break; }
    }
    for index in 0..count {
        output[offset + index] = reversed[count - index - 1];
    }
    count
}

fn write_fixed_six(value: f32, output: &mut [u8], offset: usize) -> usize {
    let bits = value.to_bits();
    let exponent_bits = (bits >> 23) & 255;
    let fraction_bits = bits & 0x7f_ffff;
    let significand = if exponent_bits == 0 {
        fraction_bits as u64
    } else {
        ((1_u32 << 23) | fraction_bits) as u64
    };
    let shift = if exponent_bits == 0 { -149 } else { exponent_bits as i32 - 150 };
    let numerator = significand * 1_000_000;
    let micros = if shift >= 0 {
        numerator << shift as u32
    } else {
        let denominator_shift = (-shift) as u32;
        if denominator_shift >= 64 {
            0
        } else {
            let floor = numerator >> denominator_shift;
            let mask = (1_u64 << denominator_shift) - 1;
            let remainder = numerator & mask;
            let halfway = 1_u64 << (denominator_shift - 1);
            if remainder > halfway || (remainder == halfway && (floor & 1) != 0) {
                floor + 1
            } else {
                floor
            }
        }
    };

    let mut position = offset;
    if (bits >> 31) != 0 {
        output[position] = b'-';
        position += 1;
    }
    position += write_unsigned(micros / 1_000_000, output, position);
    output[position] = b'.';
    position += 1;
    let fractional = (micros % 1_000_000) as u32;
    let mut place = 100_000_u32;
    while place > 0 {
        output[position] = b'0' + ((fractional / place) % 10) as u8;
        position += 1;
        place /= 10;
    }
    output[position] = b'\n';
    position + 1 - offset
}

#[no_mangle]
pub unsafe extern "C" fn floatmm(passes: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(0..=MAX_PASSES).contains(&passes) { return -1; }
    if passes == 0 { return 0; }
    if output.is_null() { return -2; }

    let mut formatted = [0_u8; MAX_OUTPUT_BYTES];
    let mut required = 0;
    for run in 0..passes as usize {
        let diagonal = compute_diagonal_cell(run);
        required += write_fixed_six(diagonal, &mut formatted, required);
    }
    if output_capacity < required { return -2; }
    unsafe { std::ptr::copy_nonoverlapping(formatted.as_ptr(), output, required); }
    required as i64
}
