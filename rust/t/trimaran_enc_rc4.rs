// ARC4 port from Trimaran/enc-rc4, Copyright (C) 2001-2003 Christophe Devine.
// Distributed under GPL-2.0-or-later; see the package license notice.
const OUTPUT_BYTES: usize = 82;
const MAX_PASSES: i64 = 2000;
const KEY_LENGTHS: [usize; 6] = [8, 8, 8, 4, 8, 4];
const DATA_LENGTHS: [usize; 6] = [8, 8, 8, 20, 28, 10];
const OUTPUT_OFFSETS: [usize; 6] = [0, 8, 16, 24, 44, 72];

fn crypt_one(keys: &[u8; 48], key_base: usize, key_length: usize,
             staged: &mut [u8; OUTPUT_BYTES], data_base: usize, data_length: usize) {
    let mut state = [0i32; 256];
    for index in 0..256 { state[index] = index as i32; }
    let mut j = 0usize;
    for index in 0..256 {
        j = (j + state[index] as usize + keys[key_base + index % key_length] as usize) & 255;
        state.swap(index, j);
    }
    let (mut x, mut y) = (0usize, 0usize);
    for offset in 0..data_length {
        x = (x + 1) & 255;
        let a = state[x] as usize;
        y = (y + a) & 255;
        let b = state[y] as usize;
        state[x] = b as i32;
        state[y] = a as i32;
        staged[data_base + offset] ^= state[(a + b) & 255] as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn trimaran_enc_rc4(input: *const i64, length: usize,
                                             output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let passes_value = *input;
    if !(1..=MAX_PASSES).contains(&passes_value) { return -1; }
    if output.is_null() || output_capacity < OUTPUT_BYTES { return -2; }

    let mut keys = [0u8; 48];
    keys[0..8].copy_from_slice(&[0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef]);
    keys[8..16].copy_from_slice(&[0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef]);
    keys[24..28].copy_from_slice(&[0xef,0x01,0x23,0x45]);
    keys[32..40].copy_from_slice(&[0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef]);
    keys[40..44].copy_from_slice(&[0xef,0x01,0x23,0x45]);
    let mut plaintexts = [0u8; 168];
    plaintexts[0..8].copy_from_slice(&[0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef]);
    plaintexts[112..140].copy_from_slice(&[
        0x12,0x34,0x56,0x78,0x9a,0xbc,0xde,0xf0,
        0x12,0x34,0x56,0x78,0x9a,0xbc,0xde,0xf0,
        0x12,0x34,0x56,0x78,0x9a,0xbc,0xde,0xf0,
        0x12,0x34,0x56,0x78]);
    let mut staged = [0u8; OUTPUT_BYTES];
    for vector in 0..6 {
        let output_base = OUTPUT_OFFSETS[vector];
        let input_base = vector * 28;
        for _ in 0..passes_value as usize {
            staged[output_base..output_base + DATA_LENGTHS[vector]]
                .copy_from_slice(&plaintexts[input_base..input_base + DATA_LENGTHS[vector]]);
            crypt_one(&keys, vector * 8, KEY_LENGTHS[vector], &mut staged,
                      output_base, DATA_LENGTHS[vector]);
        }
    }
    for index in 0..OUTPUT_BYTES { *output.add(index) = staged[index]; }
    OUTPUT_BYTES as i64
}
