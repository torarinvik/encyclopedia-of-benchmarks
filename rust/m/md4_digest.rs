use core::slice;

const SHIFTS1: [u32; 4] = [3, 7, 11, 19];
const SHIFTS2: [u32; 4] = [3, 5, 9, 13];
const SHIFTS3: [u32; 4] = [3, 9, 11, 15];
const ORDER3: [usize; 16] = [0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15];

fn rotate_left(value: u32, shift: u32) -> u32 { value.rotate_left(shift) }
fn f(x: u32, y: u32, z: u32) -> u32 { (x & y) | (!x & z) }
fn g(x: u32, y: u32, z: u32) -> u32 { (x & y) | (x & z) | (y & z) }
fn h(x: u32, y: u32, z: u32) -> u32 { x ^ y ^ z }

fn padded_word(input: &[i64], n: usize, padded: usize, bit_length: u64,
               block: usize, word: usize) -> u32 {
    let mut value = 0u32;
    for byte_index in 0..4 {
        let pos = block + word * 4 + byte_index;
        let byte = if pos < n {
            input[pos] as u32
        } else if pos == n {
            0x80
        } else if pos >= padded - 8 {
            ((bit_length >> (8 * (pos - (padded - 8)))) & 255) as u32
        } else { 0 };
        value |= byte << (8 * byte_index);
    }
    value
}

fn digest(bytes: &[i64]) -> [u8; 16] {
    let n = bytes.len();
    let padded = ((n + 8) / 64 + 1) * 64;
    let bit_length = (n as u64) * 8;
    let mut state = [0x67452301u32, 0xefcdab89, 0x98badcfe, 0x10325476];
    let mut offset = 0;
    while offset < padded {
        let mut words = [0u32; 16];
        for i in 0..16 { words[i] = padded_word(bytes, n, padded, bit_length, offset, i); }
        let (mut a, mut b, mut c, mut d) = (state[0], state[1], state[2], state[3]);
        for step in 0..48usize {
            let round = step / 16;
            let j = step % 16;
            let (function, index, shift, additive) = match round {
                0 => (f(b, c, d), j, SHIFTS1[j & 3], 0u32),
                1 => (g(b, c, d), (j & 3) * 4 + j / 4, SHIFTS2[j & 3], 0x5a827999),
                _ => (h(b, c, d), ORDER3[j], SHIFTS3[j & 3], 0x6ed9eba1),
            };
            let rotated = rotate_left(a.wrapping_add(function).wrapping_add(words[index]).wrapping_add(additive), shift);
            let prior_d = d;
            d = c; c = b; b = b.wrapping_add(rotated); a = prior_d;
        }
        state[0] = state[0].wrapping_add(a);
        state[1] = state[1].wrapping_add(b);
        state[2] = state[2].wrapping_add(c);
        state[3] = state[3].wrapping_add(d);
        offset += 64;
    }
    let mut output = [0u8; 16];
    for i in 0..4 { output[i * 4..i * 4 + 4].copy_from_slice(&state[i].to_le_bytes()); }
    output
}

#[no_mangle]
pub unsafe extern "C" fn md4_digest(input: *const i64, input_length: usize,
                                     output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || input_length == 0 || input_length > 4098 { return -1; }
    let values = unsafe { slice::from_raw_parts(input, input_length) };
    let count = values[0];
    if !(0..=4096).contains(&count) || input_length != count as usize + 1 { return -1; }
    let n = count as usize;
    let message = &values[1..];
    if message.len() != n || message.iter().any(|&byte| !(0..=255).contains(&byte)) { return -1; }
    if output.is_null() || output_capacity < 16 { return -2; }
    let result = digest(message);
    let out = unsafe { slice::from_raw_parts_mut(output, 16) };
    out.copy_from_slice(&result);
    16
}
