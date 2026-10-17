const P8: [u8; 8] = [6, 3, 7, 4, 8, 5, 10, 9];
const P10: [u8; 10] = [3, 5, 2, 7, 4, 10, 1, 9, 8, 6];
const P4: [u8; 4] = [2, 4, 3, 1];
const IP: [u8; 8] = [2, 6, 3, 1, 4, 8, 5, 7];
const IP_INVERSE: [u8; 8] = [4, 1, 3, 5, 7, 2, 8, 6];
const EXPANSION: [u8; 8] = [4, 1, 2, 3, 2, 3, 4, 1];
const SBOXES: [[[u8; 4]; 4]; 2] = [
    [[1, 0, 3, 2], [3, 2, 1, 0], [0, 2, 1, 3], [3, 1, 3, 2]],
    [[0, 1, 2, 3], [2, 0, 1, 3], [3, 0, 1, 0], [2, 1, 0, 3]],
];

fn table_value(table: usize, index: usize) -> u32 {
    match table {
        0 => P8[index] as u32,
        1 => P10[index] as u32,
        2 => IP[index] as u32,
        3 => IP_INVERSE[index] as u32,
        4 => EXPANSION[index] as u32,
        _ => P4[index] as u32,
    }
}

fn permute(value: u32, input_bits: u32, table: usize, count: usize) -> u32 {
    let mut result = 0;
    for index in 0..count {
        let position = table_value(table, index);
        result = (result << 1) | ((value >> (input_bits - position)) & 1);
    }
    result
}

fn rotate5(value: u32, amount: u32) -> u32 {
    ((value << amount) | (value >> (5 - amount))) & 31
}

fn subkey(key: u32, round: u32) -> u32 {
    let selected = permute(key, 10, 1, 10);
    let mut left = selected >> 5;
    let mut right = selected & 31;
    left = rotate5(left, 1);
    right = rotate5(right, 1);
    if round != 0 {
        left = rotate5(left, 2);
        right = rotate5(right, 2);
    }
    permute((left << 5) | right, 10, 0, 8)
}

fn sbox_value(box_index: usize, nibble: u32) -> u32 {
    let row = (((nibble & 8) >> 2) | (nibble & 1)) as usize;
    let column = ((nibble >> 1) & 3) as usize;
    SBOXES[box_index][row][column] as u32
}

fn fk(state: u32, key: u32) -> u32 {
    let left = state >> 4;
    let right = state & 15;
    let mixed = permute(right, 4, 4, 8) ^ key;
    let substituted = (sbox_value(0, mixed >> 4) << 2) | sbox_value(1, mixed & 15);
    ((left ^ permute(substituted, 4, 5, 4)) << 4) | right
}

fn crypt(message: u32, key: u32, decrypt: bool) -> u32 {
    let first = subkey(key, 0);
    let second = subkey(key, 1);
    let mut state = permute(message, 8, 2, 8);
    state = fk(state, if decrypt { second } else { first });
    state = ((state & 15) << 4) | (state >> 4);
    state = fk(state, if decrypt { first } else { second });
    permute(state, 8, 3, 8)
}

/// Return ciphertext and the plaintext recovered with the reversed subkeys.
#[no_mangle]
pub unsafe extern "C" fn sdes(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 2 {
        return -1;
    }
    let input = std::slice::from_raw_parts(input, length);
    if !(0..=1023).contains(&input[0]) || !(0..=255).contains(&input[1]) {
        return -1;
    }
    if output.is_null() || output_capacity < 2 {
        return -2;
    }
    let key = input[0] as u32;
    let ciphertext = crypt(input[1] as u32, key, false);
    let recovered = crypt(ciphertext, key, true);
    *output = ciphertext as u8;
    *output.add(1) = recovered as u8;
    2
}
