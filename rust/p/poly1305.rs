const MAX_MESSAGE_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 98;
const LIMB_MASK: u64 = 0x3ff_ffff;

fn load32_le(bytes: &[u8], offset: usize) -> u64 {
    u32::from_le_bytes([bytes[offset], bytes[offset + 1], bytes[offset + 2], bytes[offset + 3]]) as u64
}

fn store32_le(output: &mut [u8], offset: usize, value: u32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

fn poly1305_tag(key: &[u8; 32], message: &[u8; MAX_MESSAGE_LENGTH], message_length: usize) -> [u8; 16] {
    let r0 = load32_le(key, 0) & 0x3ff_ffff;
    let r1 = (load32_le(key, 3) >> 2) & 0x3ff_ff03;
    let r2 = (load32_le(key, 6) >> 4) & 0x3ff_c0ff;
    let r3 = (load32_le(key, 9) >> 6) & 0x3f0_3fff;
    let r4 = (load32_le(key, 12) >> 8) & 0x00f_ffff;
    let s1 = r1 * 5; let s2 = r2 * 5; let s3 = r3 * 5; let s4 = r4 * 5;
    let mut h0 = 0_u64; let mut h1 = 0_u64; let mut h2 = 0_u64; let mut h3 = 0_u64; let mut h4 = 0_u64;
    let mut offset = 0;
    while offset < message_length {
        let mut block = [0_u8; 16];
        let block_length = (message_length - offset).min(16);
        block[..block_length].copy_from_slice(&message[offset..offset + block_length]);
        let mut high_bit = 1_u64 << 24;
        if block_length < 16 { block[block_length] = 1; high_bit = 0; }
        h0 += load32_le(&block, 0) & LIMB_MASK;
        h1 += (load32_le(&block, 3) >> 2) & LIMB_MASK;
        h2 += (load32_le(&block, 6) >> 4) & LIMB_MASK;
        h3 += (load32_le(&block, 9) >> 6) & LIMB_MASK;
        h4 += (load32_le(&block, 12) >> 8) | high_bit;
        let d0 = h0 * r0 + h1 * s4 + h2 * s3 + h3 * s2 + h4 * s1;
        let d1 = h0 * r1 + h1 * r0 + h2 * s4 + h3 * s3 + h4 * s2;
        let d2 = h0 * r2 + h1 * r1 + h2 * r0 + h3 * s4 + h4 * s3;
        let d3 = h0 * r3 + h1 * r2 + h2 * r1 + h3 * r0 + h4 * s4;
        let d4 = h0 * r4 + h1 * r3 + h2 * r2 + h3 * r1 + h4 * r0;
        let mut carry = d0 >> 26; h0 = d0 & LIMB_MASK;
        let q1 = d1 + carry; carry = q1 >> 26; h1 = q1 & LIMB_MASK;
        let q2 = d2 + carry; carry = q2 >> 26; h2 = q2 & LIMB_MASK;
        let q3 = d3 + carry; carry = q3 >> 26; h3 = q3 & LIMB_MASK;
        let q4 = d4 + carry; carry = q4 >> 26; h4 = q4 & LIMB_MASK;
        h0 += carry * 5;
        carry = h0 >> 26; h0 &= LIMB_MASK; h1 += carry;
        offset += block_length;
    }
    for _ in 0..3 {
        let mut carry = h0 >> 26; h0 &= LIMB_MASK; h1 += carry;
        carry = h1 >> 26; h1 &= LIMB_MASK; h2 += carry;
        carry = h2 >> 26; h2 &= LIMB_MASK; h3 += carry;
        carry = h3 >> 26; h3 &= LIMB_MASK; h4 += carry;
        carry = h4 >> 26; h4 &= LIMB_MASK; h0 += carry * 5;
        carry = h0 >> 26; h0 &= LIMB_MASK; h1 += carry;
    }
    if h4 == LIMB_MASK && h3 == LIMB_MASK && h2 == LIMB_MASK && h1 == LIMB_MASK && h0 >= LIMB_MASK - 4 {
        h0 -= LIMB_MASK - 4; h1 = 0; h2 = 0; h3 = 0; h4 = 0;
    }
    let f0 = ((h0 | (h1 << 26)) & 0xffff_ffff) + load32_le(key, 16);
    let f1 = ((h1 >> 6 | (h2 << 20)) & 0xffff_ffff) + load32_le(key, 20) + (f0 >> 32);
    let f2 = ((h2 >> 12 | (h3 << 14)) & 0xffff_ffff) + load32_le(key, 24) + (f1 >> 32);
    let f3 = ((h3 >> 18 | (h4 << 8)) & 0xffff_ffff) + load32_le(key, 28) + (f2 >> 32);
    let mut tag = [0_u8; 16];
    store32_le(&mut tag, 0, f0 as u32);
    store32_le(&mut tag, 4, f1 as u32);
    store32_le(&mut tag, 8, f2 as u32);
    store32_le(&mut tag, 12, f3 as u32);
    tag
}

unsafe fn write_tag(output: *mut u8, tag: &[u8; 16]) {
    for index in 0..16 { *output.add(index) = tag[index]; }
}

#[no_mangle]
pub unsafe extern "C" fn poly1305(input: *const i64, length: usize, output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 33 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let raw_length = values[0];
    if !(0..=MAX_MESSAGE_LENGTH as i64).contains(&raw_length) || length != 33 + raw_length as usize { return -1; }
    if values[1..].iter().any(|&value| !(0..=255).contains(&value)) { return -1; }
    if output.is_null() || output_capacity < 16 { return -2; }
    let mut key = [0_u8; 32];
    let mut message = [0_u8; MAX_MESSAGE_LENGTH];
    for index in 0..32 { key[index] = values[1 + index] as u8; }
    for index in 0..raw_length as usize { message[index] = values[33 + index] as u8; }
    let tag = poly1305_tag(&key, &message, raw_length as usize);
    write_tag(output, &tag);
    16
}
