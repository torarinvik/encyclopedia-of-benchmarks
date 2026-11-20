const MAX_WORDS: usize = 35;
const MAX_PAYLOAD: usize = 32;
const MAX_BASE58: usize = 51;
const ALPHABET: &[u8; 58] = b"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
const SHA_K: [u32; 64] = [
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
];

fn sha256_digest(input: &[u8], digest: &mut [u8; 32]) {
    let mut block = [0_u8; 64];
    block[..input.len()].copy_from_slice(input);
    block[input.len()] = 0x80;
    let bit_length = (input.len() as u64) * 8;
    block[56..64].copy_from_slice(&bit_length.to_be_bytes());
    let mut words = [0_u32; 64];
    for index in 0..16 {
        words[index] = u32::from_be_bytes([
            block[index * 4], block[index * 4 + 1], block[index * 4 + 2], block[index * 4 + 3],
        ]);
    }
    for index in 16..64 {
        let x = words[index - 15];
        let y = words[index - 2];
        let small0 = x.rotate_right(7) ^ x.rotate_right(18) ^ (x >> 3);
        let small1 = y.rotate_right(17) ^ y.rotate_right(19) ^ (y >> 10);
        words[index] = small1.wrapping_add(words[index - 7])
            .wrapping_add(small0).wrapping_add(words[index - 16]);
    }
    let mut state = [
        0x6a09e667_u32,0xbb67ae85,0x3c6ef372,0xa54ff53a,
        0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19,
    ];
    let (mut a,mut b,mut c,mut d)=(state[0],state[1],state[2],state[3]);
    let (mut e,mut f,mut g,mut h)=(state[4],state[5],state[6],state[7]);
    for index in 0..64 {
        let big1=e.rotate_right(6)^e.rotate_right(11)^e.rotate_right(25);
        let choose=(e&f)^(!e&g);
        let first=h.wrapping_add(big1).wrapping_add(choose)
            .wrapping_add(SHA_K[index]).wrapping_add(words[index]);
        let big0=a.rotate_right(2)^a.rotate_right(13)^a.rotate_right(22);
        let majority=(a&b)^(a&c)^(b&c);
        let second=big0.wrapping_add(majority);
        h=g;g=f;f=e;e=d.wrapping_add(first);d=c;c=b;b=a;a=first.wrapping_add(second);
    }
    state[0]=state[0].wrapping_add(a);state[1]=state[1].wrapping_add(b);
    state[2]=state[2].wrapping_add(c);state[3]=state[3].wrapping_add(d);
    state[4]=state[4].wrapping_add(e);state[5]=state[5].wrapping_add(f);
    state[6]=state[6].wrapping_add(g);state[7]=state[7].wrapping_add(h);
    for index in 0..8 { digest[index*4..index*4+4].copy_from_slice(&state[index].to_be_bytes()); }
}

#[no_mangle]
pub unsafe extern "C" fn base58check_encode(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_WORDS {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    let version = values[0];
    let payload_length_value = values[1];
    if !(0..=255).contains(&version)
        || payload_length_value < 0
        || payload_length_value > MAX_PAYLOAD as i64
    {
        return -1;
    }
    let payload_length = payload_length_value as usize;
    if length != payload_length + 2 {
        return -1;
    }

    let mut message = [0_u8; MAX_PAYLOAD + 1];
    let mut raw = [0_u8; MAX_PAYLOAD + 5];
    message[0] = version as u8;
    raw[0] = version as u8;
    for index in 0..payload_length {
        let byte = values[index + 2];
        if !(0..=255).contains(&byte) {
            return -1;
        }
        message[index + 1] = byte as u8;
        raw[index + 1] = byte as u8;
    }
    let message_length = payload_length + 1;
    let mut first_digest = [0_u8; 32];
    sha256_digest(&message[..message_length], &mut first_digest);
    let mut second_digest = [0_u8; 32];
    sha256_digest(&first_digest, &mut second_digest);

    let raw_length = message_length + 4;
    raw[message_length..raw_length].copy_from_slice(&second_digest[..4]);
    let leading_zeroes = raw[..raw_length]
        .iter()
        .take_while(|&&byte| byte == 0)
        .count();
    let mut digits = [0_u8; MAX_BASE58];
    let mut digit_count = 0;
    for &byte in &raw[leading_zeroes..raw_length] {
        let mut carry = byte as u32;
        for digit in digits.iter_mut().take(digit_count) {
            carry += (*digit as u32) * 256;
            *digit = (carry % 58) as u8;
            carry /= 58;
        }
        while carry != 0 {
            digits[digit_count] = (carry % 58) as u8;
            digit_count += 1;
            carry /= 58;
        }
    }
    let encoded_length = leading_zeroes + digit_count;
    if output.is_null() || output_capacity < encoded_length {
        return -2;
    }
    let mut written = 0;
    for _ in 0..leading_zeroes {
        *output.add(written) = b'1';
        written += 1;
    }
    for index in (0..digit_count).rev() {
        *output.add(written) = ALPHABET[digits[index] as usize];
        written += 1;
    }
    encoded_length as i64
}
