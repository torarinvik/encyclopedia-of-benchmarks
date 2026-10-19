/// Port the fixed-size integer matrix multiplication from Stanford IntMM.
const ROWSIZE: usize = 40;
const CELL_COUNT: usize = ROWSIZE * ROWSIZE;
const MAX_PASSES: i64 = 10;

fn decimal_width(value: i32) -> usize {
    let mut magnitude = i64::from(value);
    if magnitude < 0 { magnitude = -magnitude; }
    let mut width = if value < 0 { 1 } else { 0 };
    loop {
        width += 1;
        magnitude /= 10;
        if magnitude == 0 { break; }
    }
    width
}

unsafe fn write_decimal(value: i32, output: *mut u8, mut position: usize) -> usize {
    let mut magnitude = i64::from(value);
    if magnitude < 0 {
        unsafe { output.add(position).write(b'-'); }
        position += 1;
        magnitude = -magnitude;
    }
    let mut reversed = [0_u8; 10];
    let mut count = 0;
    loop {
        reversed[count] = b'0' + (magnitude % 10) as u8;
        count += 1;
        magnitude /= 10;
        if magnitude == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        unsafe { output.add(position).write(reversed[count]); }
        position += 1;
    }
    position
}

#[no_mangle]
pub extern "C" fn stanford_intmm(pass_count: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(1..=MAX_PASSES).contains(&pass_count) { return -1; }

    let mut a = [0_i32; CELL_COUNT];
    let mut b = [0_i32; CELL_COUNT];
    let mut product = [0_i32; CELL_COUNT];
    let mut diagonal = [0_i32; MAX_PASSES as usize];
    for pass in 0..pass_count as usize {
        let mut seed = 74755_i64;
        for index in 0..CELL_COUNT {
            seed = (seed * 1309 + 13849) & 65535;
            a[index] = (seed % 120 - 60) as i32;
        }
        for index in 0..CELL_COUNT {
            seed = (seed * 1309 + 13849) & 65535;
            b[index] = (seed % 120 - 60) as i32;
        }

        for row in 0..ROWSIZE {
            for column in 0..ROWSIZE {
                let mut sum = 0_i32;
                for inner in 0..ROWSIZE {
                    sum += a[row * ROWSIZE + inner] * b[inner * ROWSIZE + column];
                }
                product[row * ROWSIZE + column] = sum;
            }
        }
        diagonal[pass] = product[pass * ROWSIZE + pass];
    }

    let required: usize = diagonal[..pass_count as usize]
        .iter()
        .map(|value| decimal_width(*value) + 1)
        .sum();
    if output.is_null() || output_capacity < required { return -2; }

    let mut position = 0;
    for value in diagonal[..pass_count as usize].iter() {
        unsafe {
            position = write_decimal(*value, output, position);
            output.add(position).write(b'\n');
        }
        position += 1;
    }
    position as i64
}
