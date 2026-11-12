const MAX_ORDER: usize = 16;
const MAX_CYCLE_LENGTH: usize = 10_000;

fn fkm_generate(position: usize, period: usize, order: usize, alphabet: usize,
                work: &mut [u8; MAX_ORDER + 1], output: &mut [u8], emitted: &mut usize) {
    if position > order {
        if order % period == 0 {
            for index in 1..=period {
                output[*emitted] = b'0' + work[index];
                *emitted += 1;
            }
        }
        return;
    }
    work[position] = work[position - period];
    fkm_generate(position + 1, period, order, alphabet, work, output, emitted);
    for symbol in (work[position - period] as usize + 1)..alphabet {
        work[position] = symbol as u8;
        fkm_generate(position + 1, position, order, alphabet, work, output, emitted);
    }
}

#[no_mangle]
pub unsafe extern "C" fn de_bruijn_sequences(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let alphabet_value = *input;
    let order_value = *input.add(1);
    if !(2..=10).contains(&alphabet_value) || !(1..=MAX_ORDER as i64).contains(&order_value) { return -1; }
    let alphabet = alphabet_value as usize;
    let order = order_value as usize;
    let mut cycle_length = 1usize;
    for _ in 0..order {
        if cycle_length > MAX_CYCLE_LENGTH / alphabet { return -1; }
        cycle_length *= alphabet;
    }
    let output_length = cycle_length + order - 1;
    if output.is_null() || output_capacity < output_length { return -2; }

    let mut work = [0u8; MAX_ORDER + 1];
    let mut emitted = 0usize;
    let output_slice = std::slice::from_raw_parts_mut(output, output_length);
    fkm_generate(1, 1, order, alphabet, &mut work, output_slice, &mut emitted);
    for index in 0..(order - 1) { *output.add(cycle_length + index) = *output.add(index); }
    output_length as i64
}
