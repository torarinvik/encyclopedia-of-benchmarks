fn rotate_left(value: u32, amount: u32) -> u32 {
    value.rotate_left(amount)
}

fn quarter_round(state: &mut [u32; 16], first: usize, second: usize, third: usize, fourth: usize) {
    state[second] ^= rotate_left(state[first].wrapping_add(state[fourth]), 7);
    state[third] ^= rotate_left(state[second].wrapping_add(state[first]), 9);
    state[fourth] ^= rotate_left(state[third].wrapping_add(state[second]), 13);
    state[first] ^= rotate_left(state[fourth].wrapping_add(state[third]), 18);
}

fn store_u32_le(output: *mut u8, offset: usize, value: u32) {
    for byte in 0..4 {
        unsafe { *output.add(offset + byte) = (value >> (byte * 8)) as u8; }
    }
}

/// Reproduce the pinned 16-word Salsa core variant; this is not a stream cipher.
#[no_mangle]
pub unsafe extern "C" fn salsa(
    input: *const i32,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 16 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let mut original = [0u32; 16];
    for index in 0..16 {
        original[index] = values[index] as u32;
    }
    if output.is_null() || output_capacity < 64 {
        return -2;
    }

    let mut state = original;
    for _ in 0..10 {
        quarter_round(&mut state, 0, 4, 8, 12);
        quarter_round(&mut state, 5, 9, 13, 1);
        quarter_round(&mut state, 10, 14, 2, 6);
        quarter_round(&mut state, 15, 3, 7, 11);
        quarter_round(&mut state, 0, 1, 2, 3);
        quarter_round(&mut state, 5, 6, 7, 4);
        quarter_round(&mut state, 10, 11, 8, 9);
        quarter_round(&mut state, 15, 12, 13, 14);
    }
    for index in 0..16 {
        state[index] = state[index].wrapping_add(original[index]);
        store_u32_le(output, index * 4, state[index]);
    }
    64
}
