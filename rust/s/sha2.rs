const MAX_MESSAGE_BYTES: usize = 4096;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 4099;
const MAX_PADDED_BYTES: usize = 4224;
const MAX_OUTPUT_BYTES: usize = 64;
const K32: [u32; 64] = [
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
];
const K64: [u64; 80] = [
    0x428a2f98d728ae22,0x7137449123ef65cd,0xb5c0fbcfec4d3b2f,0xe9b5dba58189dbbc,
    0x3956c25bf348b538,0x59f111f1b605d019,0x923f82a4af194f9b,0xab1c5ed5da6d8118,
    0xd807aa98a3030242,0x12835b0145706fbe,0x243185be4ee4b28c,0x550c7dc3d5ffb4e2,
    0x72be5d74f27b896f,0x80deb1fe3b1696b1,0x9bdc06a725c71235,0xc19bf174cf692694,
    0xe49b69c19ef14ad2,0xefbe4786384f25e3,0x0fc19dc68b8cd5b5,0x240ca1cc77ac9c65,
    0x2de92c6f592b0275,0x4a7484aa6ea6e483,0x5cb0a9dcbd41fbd4,0x76f988da831153b5,
    0x983e5152ee66dfab,0xa831c66d2db43210,0xb00327c898fb213f,0xbf597fc7beef0ee4,
    0xc6e00bf33da88fc2,0xd5a79147930aa725,0x06ca6351e003826f,0x142929670a0e6e70,
    0x27b70a8546d22ffc,0x2e1b21385c26c926,0x4d2c6dfc5ac42aed,0x53380d139d95b3df,
    0x650a73548baf63de,0x766a0abb3c77b2a8,0x81c2c92e47edaee6,0x92722c851482353b,
    0xa2bfe8a14cf10364,0xa81a664bbc423001,0xc24b8b70d0f89791,0xc76c51a30654be30,
    0xd192e819d6ef5218,0xd69906245565a910,0xf40e35855771202a,0x106aa07032bbd1b8,
    0x19a4c116b8d2d0c8,0x1e376c085141ab53,0x2748774cdf8eeb99,0x34b0bcb5e19b48a8,
    0x391c0cb3c5c95a63,0x4ed8aa4ae3418acb,0x5b9cca4f7763e373,0x682e6ff3d6b2b8a3,
    0x748f82ee5defb2fc,0x78a5636f43172f60,0x84c87814a1f0ab72,0x8cc702081a6439ec,
    0x90befffa23631e28,0xa4506cebde82bde9,0xbef9a3f7b2c67915,0xc67178f2e372532b,
    0xca273eceea26619c,0xd186b8c721c0c207,0xeada7dd6cde0eb1e,0xf57d4f7fee6ed178,
    0x06f067aa72176fba,0x0a637dc5a2c898a6,0x113f9804bef90dae,0x1b710b35131c471b,
    0x28db77f523047d84,0x32caab7b40c72493,0x3c9ebe0a15c9bebc,0x431d67c49c100d4c,
    0x4cc5d4becb3e42b6,0x597f299cfc657e2a,0x5fcb6fab3ad6faec,0x6c44198c4a475817,
];
const H224: [u32; 8] = [0xc1059ed8,0x367cd507,0x3070dd17,0xf70e5939,0xffc00b31,0x68581511,0x64f98fa7,0xbefa4fa4];
const H256: [u32; 8] = [0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19];
const H384: [u64; 8] = [0xcbbb9d5dc1059ed8,0x629a292a367cd507,0x9159015a3070dd17,0x152fecd8f70e5939,0x67332667ffc00b31,0x8eb44a8768581511,0xdb0c2e0d64f98fa7,0x47b5481dbefa4fa4];
const H512: [u64; 8] = [0x6a09e667f3bcc908,0xbb67ae8584caa73b,0x3c6ef372fe94f82b,0xa54ff53a5f1d36f1,0x510e527fade682d1,0x9b05688c2b3e6c1f,0x1f83d9abfb41bd6b,0x5be0cd19137e2179];
const H512_224: [u64; 8] = [0x8c3d37c819544da2,0x73e1996689dcd4d6,0x1dfab7ae32ff9c82,0x679dd514582f9fcf,0x0f6d2b697bd44da8,0x77e36f7304c48942,0x3f9d85a86a1d36c8,0x1112e6ad91d692a1];
const H512_256: [u64; 8] = [0x22312194fc2bf72c,0x9f555fa3c84c64c2,0x2393b86b6f53b151,0x963877195940eabd,0x96283ee2a88effe3,0xbe5e1e2553863992,0x2b0199fc2c85b8aa,0x0eb72ddc81c52ca2];

fn compress32(state: &mut [u32; 8], block: &[u8]) {
    let mut words = [0u32; 64];
    for index in 0..16 {
        let offset = index * 4;
        words[index] = u32::from_be_bytes([block[offset], block[offset + 1], block[offset + 2], block[offset + 3]]);
    }
    for index in 16..64 {
        let x = words[index - 15];
        let y = words[index - 2];
        let s0 = x.rotate_right(7) ^ x.rotate_right(18) ^ (x >> 3);
        let s1 = y.rotate_right(17) ^ y.rotate_right(19) ^ (y >> 10);
        words[index] = words[index - 16].wrapping_add(s0).wrapping_add(words[index - 7]).wrapping_add(s1);
    }
    let [mut a, mut b, mut c, mut d, mut e, mut f, mut g, mut h] = *state;
    for index in 0..64 {
        let sigma1 = e.rotate_right(6) ^ e.rotate_right(11) ^ e.rotate_right(25);
        let choose = (e & f) ^ ((!e) & g);
        let temp1 = h.wrapping_add(sigma1).wrapping_add(choose).wrapping_add(K32[index]).wrapping_add(words[index]);
        let sigma0 = a.rotate_right(2) ^ a.rotate_right(13) ^ a.rotate_right(22);
        let majority = (a & b) ^ (a & c) ^ (b & c);
        let temp2 = sigma0.wrapping_add(majority);
        h = g; g = f; f = e; e = d.wrapping_add(temp1); d = c; c = b; b = a; a = temp1.wrapping_add(temp2);
    }
    state[0]=state[0].wrapping_add(a);state[1]=state[1].wrapping_add(b);state[2]=state[2].wrapping_add(c);state[3]=state[3].wrapping_add(d);
    state[4]=state[4].wrapping_add(e);state[5]=state[5].wrapping_add(f);state[6]=state[6].wrapping_add(g);state[7]=state[7].wrapping_add(h);
}

fn compress64(state: &mut [u64; 8], block: &[u8]) {
    let mut words = [0u64; 80];
    for index in 0..16 {
        let offset = index * 8;
        words[index] = u64::from_be_bytes([
            block[offset],block[offset + 1],block[offset + 2],block[offset + 3],
            block[offset + 4],block[offset + 5],block[offset + 6],block[offset + 7],
        ]);
    }
    for index in 16..80 {
        let x = words[index - 15];
        let y = words[index - 2];
        let s0 = x.rotate_right(1) ^ x.rotate_right(8) ^ (x >> 7);
        let s1 = y.rotate_right(19) ^ y.rotate_right(61) ^ (y >> 6);
        words[index] = words[index - 16].wrapping_add(s0).wrapping_add(words[index - 7]).wrapping_add(s1);
    }
    let [mut a, mut b, mut c, mut d, mut e, mut f, mut g, mut h] = *state;
    for index in 0..80 {
        let sigma1 = e.rotate_right(14) ^ e.rotate_right(18) ^ e.rotate_right(41);
        let choose = (e & f) ^ ((!e) & g);
        let temp1 = h.wrapping_add(sigma1).wrapping_add(choose).wrapping_add(K64[index]).wrapping_add(words[index]);
        let sigma0 = a.rotate_right(28) ^ a.rotate_right(34) ^ a.rotate_right(39);
        let majority = (a & b) ^ (a & c) ^ (b & c);
        let temp2 = sigma0.wrapping_add(majority);
        h = g; g = f; f = e; e = d.wrapping_add(temp1); d = c; c = b; b = a; a = temp1.wrapping_add(temp2);
    }
    state[0]=state[0].wrapping_add(a);state[1]=state[1].wrapping_add(b);state[2]=state[2].wrapping_add(c);state[3]=state[3].wrapping_add(d);
    state[4]=state[4].wrapping_add(e);state[5]=state[5].wrapping_add(f);state[6]=state[6].wrapping_add(g);state[7]=state[7].wrapping_add(h);
}

fn sha2_digest(variant: usize, values: &[i64], message_length: usize) -> ([u8; 64], usize) {
    let digest_lengths = [28usize, 32, 48, 64, 28, 32];
    let mut padded = [0u8; MAX_PADDED_BYTES];
    for index in 0..message_length { padded[index] = values[2 + index] as u8; }
    padded[message_length] = 0x80;
    let mut digest = [0u8; 64];

    if variant < 2 {
        let mut padded_length = message_length + 1;
        while padded_length % 64 != 56 { padded_length += 1; }
        padded_length += 8;
        let bit_length = (message_length as u64) * 8;
        padded[padded_length - 8..padded_length].copy_from_slice(&bit_length.to_be_bytes());
        let mut state = if variant == 0 { H224 } else { H256 };
        for offset in (0..padded_length).step_by(64) { compress32(&mut state, &padded[offset..offset + 64]); }
        for (index, word) in state.iter().enumerate() {
            let bytes = word.to_be_bytes();
            for byte in 0..4 { let out = index * 4 + byte; if out < digest_lengths[variant] { digest[out] = bytes[byte]; } }
        }
    } else {
        let mut padded_length = message_length + 1;
        while padded_length % 128 != 112 { padded_length += 1; }
        padded_length += 16;
        let bit_length = (message_length as u64) * 8;
        padded[padded_length - 8..padded_length].copy_from_slice(&bit_length.to_be_bytes());
        let mut state = match variant { 2 => H384, 3 => H512, 4 => H512_224, _ => H512_256 };
        for offset in (0..padded_length).step_by(128) { compress64(&mut state, &padded[offset..offset + 128]); }
        for (index, word) in state.iter().enumerate() {
            let bytes = word.to_be_bytes();
            for byte in 0..8 { let out = index * 8 + byte; if out < digest_lengths[variant] { digest[out] = bytes[byte]; } }
        }
    }
    (digest, digest_lengths[variant])
}

#[no_mangle]
pub unsafe extern "C" fn sha2(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if values[0] < 0 || values[0] > 5 || values[1] < 0 || values[1] > MAX_MESSAGE_BYTES as i64 { return -1; }
    let variant = values[0] as usize;
    let message_length = values[1] as usize;
    if input_length != 2 + message_length || values[2..].iter().any(|value| *value < 0 || *value > 255) { return -1; }
    let digest_length = [28usize, 32, 48, 64, 28, 32][variant];
    if digest_length > MAX_OUTPUT_BYTES { return -1; }
    if output.is_null() || output_capacity < digest_length { return -2; }
    let (digest, length) = sha2_digest(variant, values, message_length);
    std::slice::from_raw_parts_mut(output, length).copy_from_slice(&digest[..length]);
    length as i64
}
