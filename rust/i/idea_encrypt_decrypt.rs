fn multiply(left: u16, right: u16) -> u16 {
    let a = if left == 0 { 65536u64 } else { left as u64 };
    let b = if right == 0 { 65536u64 } else { right as u64 };
    let residue = (a * b) % 65537;
    if residue == 65536 { 0 } else { residue as u16 }
}

fn inverse(value: u16) -> u16 {
    let mut old_r: i64 = 65537;
    let mut r: i64 = if value == 0 { 65536 } else { value as i64 };
    let mut old_s: i64 = 0;
    let mut s: i64 = 1;
    while r != 0 {
        let quotient = old_r / r;
        let next_r = old_r - quotient * r;
        let next_s = old_s - quotient * s;
        old_r = r; r = next_r; old_s = s; s = next_s;
    }
    let residue = old_s.rem_euclid(65537);
    if residue == 65536 { 0 } else { residue as u16 }
}

fn expand_key(key: &[u16; 8]) -> [u16; 52] {
    let mut state = *key;
    let mut expanded = [0u16; 52];
    let mut offset = 0;
    while offset < 52 {
        let amount = core::cmp::min(8, 52 - offset);
        expanded[offset..offset + amount].copy_from_slice(&state[..amount]);
        let mut rotated = [0u16; 8];
        for index in 0..8 {
            rotated[index] = ((state[(index + 1) & 7] << 9)
                | (state[(index + 2) & 7] >> 7)) as u16;
        }
        state = rotated;
        offset += amount;
    }
    expanded
}

fn encrypt(key: &[u16; 52], block: &[u16; 4]) -> [u16; 4] {
    let (mut x1, mut x2, mut x3, mut x4) = (block[0], block[1], block[2], block[3]);
    for round in 0..8 {
        let k = round * 6;
        let a = multiply(x1, key[k]);
        let b = x2.wrapping_add(key[k + 1]);
        let c = x3.wrapping_add(key[k + 2]);
        let d = multiply(x4, key[k + 3]);
        let p = multiply(a ^ c, key[k + 4]);
        let q = multiply((b ^ d).wrapping_add(p), key[k + 5]);
        let r = p.wrapping_add(q);
        x1 = a ^ q;
        x2 = c ^ q;
        x3 = b ^ r;
        x4 = d ^ r;
    }
    [multiply(x1, key[48]), x3.wrapping_add(key[49]),
     x2.wrapping_add(key[50]), multiply(x4, key[51])]
}

fn decrypt(key: &[u16; 52], cipher: &[u16; 4]) -> [u16; 4] {
    let (mut x1, mut x2, mut x3, mut x4) = (
        multiply(cipher[0], inverse(key[48])),
        cipher[2].wrapping_sub(key[50]),
        cipher[1].wrapping_sub(key[49]),
        multiply(cipher[3], inverse(key[51])),
    );
    for round in (0..8).rev() {
        let k = round * 6;
        let p = multiply(x1 ^ x2, key[k + 4]);
        let q = multiply((x3 ^ x4).wrapping_add(p), key[k + 5]);
        let r = p.wrapping_add(q);
        let a = x1 ^ q;
        let c = x2 ^ q;
        let b = x3 ^ r;
        let d = x4 ^ r;
        x1 = multiply(a, inverse(key[k]));
        x2 = b.wrapping_sub(key[k + 1]);
        x3 = c.wrapping_sub(key[k + 2]);
        x4 = multiply(d, inverse(key[k + 3]));
    }
    [x1, x2, x3, x4]
}

#[no_mangle]
pub unsafe extern "C" fn idea_encrypt_decrypt(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 12 {
        return -1;
    }
    let values = core::slice::from_raw_parts(input, length);
    let mut key_words = [0u16; 8];
    let mut block = [0u16; 4];
    for index in 0..12 {
        if values[index] < 0 || values[index] > 65535 {
            return -1;
        }
        if index < 8 { key_words[index] = values[index] as u16; }
        else { block[index - 8] = values[index] as u16; }
    }
    if output.is_null() || capacity < 16 {
        return -2;
    }
    let subkeys = expand_key(&key_words);
    let encrypted = encrypt(&subkeys, &block);
    let recovered = decrypt(&subkeys, &encrypted);
    let result = core::slice::from_raw_parts_mut(output, 16);
    for index in 0..4 {
        result[index * 2..index * 2 + 2].copy_from_slice(&encrypted[index].to_le_bytes());
        result[8 + index * 2..10 + index * 2].copy_from_slice(&recovered[index].to_le_bytes());
    }
    16
}
