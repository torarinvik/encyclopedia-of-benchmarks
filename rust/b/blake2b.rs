const MAX_INPUT: usize = 4096;
const BLOCK_BYTES: usize = 128;
const IV: [u64; 8] = [
    0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
    0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179,
];
const SIGMA: [[usize; 16]; 10] = [
    [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15],
    [14,10,4,8,9,15,13,6,1,12,0,2,11,7,5,3],
    [11,8,12,0,5,2,15,13,10,14,3,6,7,1,9,4],
    [7,9,3,1,13,12,11,14,2,6,5,10,4,0,15,8],
    [9,0,5,7,2,4,10,15,14,1,11,12,6,8,3,13],
    [2,12,6,10,0,11,8,3,4,13,7,5,15,14,1,9],
    [12,5,1,15,14,13,4,10,0,7,6,3,9,2,8,11],
    [13,11,7,14,12,1,3,9,5,0,15,4,8,6,2,10],
    [6,15,14,9,11,3,0,8,12,2,13,7,1,4,10,5],
    [10,2,8,4,7,6,1,5,15,11,9,14,3,12,13,0],
];

#[inline]
fn mix(v: &mut [u64; 16], a: usize, b: usize, c: usize, d: usize, x: u64, y: u64) {
    v[a] = v[a].wrapping_add(v[b]).wrapping_add(x);
    v[d] = (v[d] ^ v[a]).rotate_right(32);
    v[c] = v[c].wrapping_add(v[d]);
    v[b] = (v[b] ^ v[c]).rotate_right(24);
    v[a] = v[a].wrapping_add(v[b]).wrapping_add(y);
    v[d] = (v[d] ^ v[a]).rotate_right(16);
    v[c] = v[c].wrapping_add(v[d]);
    v[b] = (v[b] ^ v[c]).rotate_right(63);
}

fn compress(h: &mut [u64; 8], block: &[u8; BLOCK_BYTES], counter: u64, is_last: bool) {
    let mut m = [0u64; 16];
    for i in 0..16 {
        let mut bytes = [0u8; 8];
        bytes.copy_from_slice(&block[i * 8..i * 8 + 8]);
        m[i] = u64::from_le_bytes(bytes);
    }
    let mut v = [0u64; 16];
    v[..8].copy_from_slice(h);
    v[8..].copy_from_slice(&IV);
    v[12] ^= counter;
    if is_last { v[14] = !v[14]; }
    for round in 0..12 {
        let s = &SIGMA[round % 10];
        mix(&mut v,0,4,8,12,m[s[0]],m[s[1]]); mix(&mut v,1,5,9,13,m[s[2]],m[s[3]]);
        mix(&mut v,2,6,10,14,m[s[4]],m[s[5]]); mix(&mut v,3,7,11,15,m[s[6]],m[s[7]]);
        mix(&mut v,0,5,10,15,m[s[8]],m[s[9]]); mix(&mut v,1,6,11,12,m[s[10]],m[s[11]]);
        mix(&mut v,2,7,8,13,m[s[12]],m[s[13]]); mix(&mut v,3,4,9,14,m[s[14]],m[s[15]]);
    }
    for i in 0..8 { h[i] ^= v[i] ^ v[i + 8]; }
}

#[no_mangle]
pub unsafe extern "C" fn blake2b(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if length > MAX_INPUT || (length > 0 && input.is_null()) { return -1; }
    for i in 0..length {
        let value = input.add(i).read();
        if !(0..=255).contains(&value) { return -1; }
    }
    if output.is_null() || capacity < 64 { return -2; }

    let mut h = IV;
    h[0] ^= 0x01010040;
    let mut block = [0u8; BLOCK_BYTES];
    let mut consumed = 0usize;
    let mut counter = 0u64;
    while length - consumed > BLOCK_BYTES {
        for i in 0..BLOCK_BYTES { block[i] = input.add(consumed + i).read() as u8; }
        counter += BLOCK_BYTES as u64;
        compress(&mut h, &block, counter, false);
        consumed += BLOCK_BYTES;
        block = [0u8; BLOCK_BYTES];
    }
    let remaining = length - consumed;
    for i in 0..remaining { block[i] = input.add(consumed + i).read() as u8; }
    counter += remaining as u64;
    compress(&mut h, &block, counter, true);
    for word in 0..8 {
        let bytes = h[word].to_le_bytes();
        for byte in 0..8 { output.add(word * 8 + byte).write(bytes[byte]); }
    }
    64
}
