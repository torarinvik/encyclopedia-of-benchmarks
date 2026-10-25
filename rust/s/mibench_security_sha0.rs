const INVALID_RESULT: i64 = -1;
const OUTPUT_ERROR: i64 = -2;
const MAX_MESSAGE_BYTES: usize = 55;

fn rol32(value: u32, shift: u32) -> u32 { value.rotate_left(shift) }

fn transform_sha0(block: &[u8; 64], state: &mut [u32; 5]) {
    let mut words = [0u32; 80];
    for i in 0..16 {
        let p = i * 4;
        words[i] = u32::from_be_bytes([block[p], block[p + 1], block[p + 2], block[p + 3]]);
    }
    for i in 16..80 { words[i] = words[i - 3] ^ words[i - 8] ^ words[i - 14] ^ words[i - 16]; }
    let (mut a, mut b, mut c, mut d, mut e) = (state[0], state[1], state[2], state[3], state[4]);
    for i in 0..80 {
        let (f, k) = if i < 20 { ((b & c) | (!b & d), 0x5A827999) }
            else if i < 40 { (b ^ c ^ d, 0x6ED9EBA1) }
            else if i < 60 { ((b & c) | (b & d) | (c & d), 0x8F1BBCDC) }
            else { (b ^ c ^ d, 0xCA62C1D6) };
        let temporary = rol32(a, 5).wrapping_add(f).wrapping_add(e).wrapping_add(words[i]).wrapping_add(k);
        e = d; d = c; c = rol32(b, 30); b = a; a = temporary;
    }
    state[0] = state[0].wrapping_add(a); state[1] = state[1].wrapping_add(b);
    state[2] = state[2].wrapping_add(c); state[3] = state[3].wrapping_add(d);
    state[4] = state[4].wrapping_add(e);
}

#[no_mangle]
pub unsafe extern "C" fn mibench_security_sha0(input: *const i64, input_length: usize,
        output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_MESSAGE_BYTES + 2 { return INVALID_RESULT; }
    let message_length = *input;
    if message_length < 0 || message_length > MAX_MESSAGE_BYTES as i64 ||
        input_length != message_length as usize + 1 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input.add(1), message_length as usize);
    if values.iter().any(|&value| !(0..=255).contains(&value)) { return INVALID_RESULT; }
    let mut block = [0u8; 64];
    for (i, &value) in values.iter().enumerate() { block[i] = value as u8; }
    block[message_length as usize] = 0x80;
    let bit_length = (message_length as u64) * 8;
    block[56..64].copy_from_slice(&bit_length.to_be_bytes());
    let mut state = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0];
    transform_sha0(&block, &mut state);
    if output.is_null() || output_capacity < 20 { return OUTPUT_ERROR; }
    for (index, word) in state.iter().enumerate() {
        std::ptr::copy_nonoverlapping(word.to_be_bytes().as_ptr(), output.add(index * 4), 4);
    }
    20
}
