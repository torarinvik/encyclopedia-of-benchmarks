const MATRIX_SIZE: usize = 10;
const CELL_COUNT: usize = MATRIX_SIZE * MATRIX_SIZE;
const MAX_ITERATIONS: i64 = 4096;
const MAX_OUTPUT_BYTES: usize = 23;

fn append_integer(mut value: i32, buffer: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize) {
    let mut reversed = [0_u8; 10];
    let mut count = 0;
    loop {
        reversed[count] = b'0' + (value % 10) as u8;
        count += 1;
        value /= 10;
        if value == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        buffer[*used] = reversed[count];
        *used += 1;
    }
}

#[no_mangle]
pub unsafe extern "C" fn shootout_matrix(
    iteration_count: i64,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if !(0..=MAX_ITERATIONS).contains(&iteration_count) { return -1; }

    let mut left = [0_i32; CELL_COUNT];
    let mut right = [0_i32; CELL_COUNT];
    let mut product = [0_i32; CELL_COUNT];
    for index in 0..CELL_COUNT {
        left[index] = index as i32 + 1;
        right[index] = index as i32 + 1;
        product[index] = index as i32 + 1;
    }

    for _ in 0..iteration_count {
        for row in 0..MATRIX_SIZE {
            for column in 0..MATRIX_SIZE {
                let mut value = 0_i32;
                for inner in 0..MATRIX_SIZE {
                    value += left[row * MATRIX_SIZE + inner] * right[inner * MATRIX_SIZE + column];
                }
                product[row * MATRIX_SIZE + column] = value;
            }
        }
    }

    let selected = [product[0], product[23], product[32], product[44]];
    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    let mut used = 0;
    for (index, value) in selected.into_iter().enumerate() {
        if index != 0 { staged[used] = b' '; used += 1; }
        append_integer(value, &mut staged, &mut used);
    }
    staged[used] = b'\n';
    used += 1;

    if output.is_null() || output_capacity < used { return -2; }
    for index in 0..used { unsafe { *output.add(index) = staged[index]; } }
    used as i64
}
