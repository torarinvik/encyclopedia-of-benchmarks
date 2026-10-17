const MAX_LENGTH: usize = 6;

unsafe fn emit_row(values: &[i32; MAX_LENGTH], length: usize, output: *mut u8, offset: &mut usize) {
    for index in 0..length {
        let bits = values[index] as u32;
        for byte in 0..4 {
            *output.add(*offset) = (bits >> (8 * byte)) as u8;
            *offset += 1;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn steinhaus_johnson_trotter(input: *const i32, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_LENGTH { return -1; }
    let mut permutations = 1_usize;
    for factor in 2..=length { permutations *= factor; }
    let required = 4 * length * permutations;
    if output.is_null() || output_capacity < required { return -2; }

    let mut values = [0_i32; MAX_LENGTH];
    let mut inversion = [0_usize; MAX_LENGTH];
    for index in 0..length { values[index] = *input.add(index); }
    let mut offset = 0;
    emit_row(&values, length, output, &mut offset);

    let mut index = 1;
    while index < length {
        if inversion[index] < index {
            let swap_index = if index % 2 == 0 { 0 } else { inversion[index] };
            values.swap(swap_index, index);
            emit_row(&values, length, output, &mut offset);
            inversion[index] += 1;
            index = 1;
        } else {
            inversion[index] = 0;
            index += 1;
        }
    }
    required as i64
}
