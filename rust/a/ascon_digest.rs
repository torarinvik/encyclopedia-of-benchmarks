/* Portable scalar port of TheAlgorithms/C-Sharp AsconDigest. */
const MAX_MESSAGE_BYTES: usize = 4096;
const INITIAL_STATES: [[u64; 5]; 2] = [
    [0xee9398aadb67f03d, 0x8bb21831c60f1002, 0xb48a92db98d5da62,
     0x43189921b8f8e3e8, 0x348fa5c9d525e140],
    [0x01470194fc6528a6, 0x738ec38ac0adffa7, 0x2ec8e3296c76384c,
     0xd6f6a54d7f52377d, 0xa13c42a223be8d87],
];

fn rotate_right(value: u64, count: u32) -> u64 {
    (value >> count) | (value << (64 - count))
}

fn permute(state: &mut [u64; 5], rounds: u32) {
    const CONSTANTS: [u64; 12] = [0xf0, 0xe1, 0xd2, 0xc3, 0xb4, 0xa5,
        0x96, 0x87, 0x78, 0x69, 0x5a, 0x4b];
    let first = if rounds == 12 { 0 } else { 4 };
    for &constant in &CONSTANTS[first..] {
        let [x0, x1, x2, x3, x4] = *state;
        let t0 = x0 ^ x1 ^ x2 ^ x3 ^ constant ^ (x1 & (x0 ^ x2 ^ x4 ^ constant));
        let t1 = x0 ^ x2 ^ x3 ^ x4 ^ constant ^ ((x1 ^ x2 ^ constant) & (x1 ^ x3));
        let t2 = x1 ^ x2 ^ x4 ^ constant ^ (x3 & x4);
        let t3 = x0 ^ x1 ^ x2 ^ constant ^ (!x0 & (x3 ^ x4));
        let t4 = x1 ^ x3 ^ x4 ^ ((x0 ^ x4) & x1);
        *state = [
            t0 ^ rotate_right(t0, 19) ^ rotate_right(t0, 28),
            t1 ^ rotate_right(t1, 39) ^ rotate_right(t1, 61),
            !(t2 ^ rotate_right(t2, 1) ^ rotate_right(t2, 6)),
            t3 ^ rotate_right(t3, 10) ^ rotate_right(t3, 17),
            t4 ^ rotate_right(t4, 7) ^ rotate_right(t4, 41),
        ];
    }
}

#[no_mangle]
pub unsafe extern "C" fn ascon_digest(input: *const i64, length: usize,
                                      output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let variant = values[0];
    let message_length_value = values[1];
    if (variant != 0 && variant != 1) || message_length_value < 0 ||
        message_length_value > MAX_MESSAGE_BYTES as i64 ||
        length != message_length_value as usize + 2 { return -1; }
    let message_length = message_length_value as usize;
    if values[2..].iter().any(|&byte| !(0..=255).contains(&byte)) { return -1; }

    let mut state = INITIAL_STATES[variant as usize];
    let rounds = if variant == 0 { 12 } else { 8 };
    let complete_length = message_length - message_length % 8;
    for offset in (0..complete_length).step_by(8) {
        let mut word = 0u64;
        for byte in 0..8 { word = (word << 8) | values[offset + byte + 2] as u64; }
        state[0] ^= word;
        permute(&mut state, rounds);
    }
    let tail_length = message_length - complete_length;
    let mut final_word = 0x80u64 << (56 - tail_length as u32 * 8);
    for byte in 0..tail_length {
        final_word |= (values[complete_length + byte + 2] as u64) << (56 - byte as u32 * 8);
    }
    state[0] ^= final_word;
    permute(&mut state, 12);

    if output.is_null() || capacity < 32 { return -2; }
    let output = std::slice::from_raw_parts_mut(output, 32);
    for block in 0..4 {
        output[block * 8..block * 8 + 8].copy_from_slice(&state[0].to_be_bytes());
        if block != 3 { permute(&mut state, rounds); }
    }
    32
}
