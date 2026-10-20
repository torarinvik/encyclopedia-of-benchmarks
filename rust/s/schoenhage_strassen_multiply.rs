// Fresh bounded port based on NyaanNyaan's CC0 radix-2 Schönhage-Strassen method.
const LIMBS: usize = 513;
const PADDED: usize = 2048;
const SCRATCH: usize = 4096;

fn ss_rot(dst: &mut [i64], src: &[i64], size: usize, shift: usize) {
    let wrapped = shift >= size;
    let d = if wrapped { shift - size } else { shift };
    for i in 0..size {
        let target = (i + d) % size;
        let sign = if (i + d >= size) ^ wrapped { -1 } else { 1 };
        dst[target] = sign * src[i];
    }
}

fn ss_add(dst: &mut [i64], src: &[i64], n: usize) {
    for i in 0..n { dst[i] += src[i]; }
}

fn ss_sub(dst: &mut [i64], src: &[i64], n: usize) {
    for i in 0..n { dst[i] -= src[i]; }
}

fn ss_fft(a: &mut [i64], l: usize, m: usize, buf: &mut [i64]) {
    if l == 0 { return; }
    let len = 1usize << l;
    let block = 1usize << m;
    let mut dw = [0i32; 16];
    for i in 0..l - 1 {
        let mut value = (1i32 << (l - 2 - i)) + (1i32 << (l - 1 - i)) - (1i32 << (l - 1));
        if value < 0 { value += len as i32; }
        if len == block { value *= 2; }
        if 2 * len == block { value *= 4; }
        dw[i] = value;
    }
    let mut d = len / 2;
    while d > 0 {
        let mut w = 0i32;
        let mut s = 0usize;
        let mut k = 0u32;
        loop {
            for i in s..s + d {
                let j = i + d;
                let (left, right) = a.split_at_mut(j * block);
                let ai = &mut left[i * block..(i + 1) * block];
                let aj = &mut right[..block];
                ss_rot(&mut buf[..block], aj, block, w as usize);
                let old_left = ai.to_vec();
                aj.copy_from_slice(&old_left);
                ss_add(ai, &buf[..block], block);
                ss_sub(aj, &buf[..block], block);
            }
            s += 2 * d;
            if s >= len { break; }
            k += 1;
            w += dw[k.trailing_zeros() as usize];
            if w >= 2 * block as i32 { w -= 2 * block as i32; }
        }
        d /= 2;
    }
}

fn ss_ifft(a: &mut [i64], l: usize, m: usize, buf: &mut [i64]) {
    if l == 0 { return; }
    let len = 1usize << l;
    let block = 1usize << m;
    let mut dw = [0i32; 16];
    for i in 0..l - 1 {
        let mut value = (1i32 << (l - 2 - i)) + (1i32 << (l - 1 - i)) - (1i32 << (l - 1));
        if value < 0 { value += len as i32; }
        if len == block { value *= 2; }
        if 2 * len == block { value *= 4; }
        dw[i] = value;
    }
    let mut d = 1usize;
    while d < len {
        let mut w = 0i32;
        let mut s = 0usize;
        let mut k = 0u32;
        loop {
            for i in s..s + d {
                let j = i + d;
                let (left, right) = a.split_at_mut(j * block);
                let ai = &mut left[i * block..(i + 1) * block];
                let aj = &mut right[..block];
                buf[..block].copy_from_slice(ai);
                ss_add(ai, aj, block);
                ss_sub(&mut buf[..block], aj, block);
                ss_rot(aj, &buf[..block], block, w as usize);
            }
            s += 2 * d;
            if s >= len { break; }
            k += 1;
            w -= dw[k.trailing_zeros() as usize];
            if w < 0 { w += 2 * block as i32; }
        }
        d *= 2;
    }
}

fn ss_naive(a: &mut [i64], b: &[i64], n: usize, buf: &mut [i64]) {
    let size = 1usize << n;
    buf[..size].fill(0);
    for i in 0..size {
        let mut j = 0;
        while j < size - i { buf[i + j] += a[i] * b[j]; j += 1; }
        while j < size { buf[i + j - size] -= a[i] * b[j]; j += 1; }
    }
    a[..size].copy_from_slice(&buf[..size]);
}

fn ss_mul(a: &mut [i64], b: &[i64], n: usize, buf: &mut [i64]) {
    if n <= 5 { ss_naive(a, b, n, buf); return; }
    let l = (n + 1) / 2;
    let m = n / 2;
    let len = 1usize << l;
    let block = 1usize << m;
    let mut aa = [0i64; SCRATCH];
    let mut bb = [0i64; SCRATCH];
    buf[block..2 * block].fill(0);
    for i in 0..len {
        buf[..block].copy_from_slice(&a[i * block..(i + 1) * block]);
        ss_rot(&mut aa[i * block * 2..(i + 1) * block * 2], &buf[..2 * block], 2 * block, i * (2 * block / len));
        buf[..block].copy_from_slice(&b[i * block..(i + 1) * block]);
        ss_rot(&mut bb[i * block * 2..(i + 1) * block * 2], &buf[..2 * block], 2 * block, i * (2 * block / len));
    }
    ss_fft(&mut aa, l, m + 1, buf);
    ss_fft(&mut bb, l, m + 1, buf);
    for i in 0..len {
        let start = i * block * 2;
        ss_mul(&mut aa[start..start + 2 * block], &bb[start..start + 2 * block], m + 1, buf);
    }
    ss_ifft(&mut aa, l, m + 1, buf);
    for i in 0..len {
        let start = i * block * 2;
        buf[..2 * block].copy_from_slice(&aa[start..start + 2 * block]);
        ss_rot(&mut aa[start..start + 2 * block], &buf[..2 * block], 2 * block, (i * (2 * block / len)) % (4 * block));
    }
    for i in 0..len { for j in 0..block {
        let at = i * block + j;
        a[at] = aa[i * block * 2 + j];
        if i == 0 { a[at] -= aa[(len - 1) * block * 2 + block + j]; }
        else { a[at] += aa[(i - 1) * block * 2 + block + j]; }
    }}
}

fn ss_mul_cyclic(a: &mut [i64], b: &[i64], n: usize, buf: &mut [i64]) {
    if n <= 5 { ss_naive(a, b, n, buf); return; }
    let l = (n + 1) / 2;
    let m = n / 2;
    let len = 1usize << l;
    let block = 1usize << m;
    let mut aa = [0i64; SCRATCH];
    let mut bb = [0i64; SCRATCH];
    for i in 0..len {
        aa[i * block * 2..i * block * 2 + block].copy_from_slice(&a[i * block..(i + 1) * block]);
        bb[i * block * 2..i * block * 2 + block].copy_from_slice(&b[i * block..(i + 1) * block]);
    }
    ss_fft(&mut aa, l, m + 1, buf);
    ss_fft(&mut bb, l, m + 1, buf);
    for i in 0..len {
        let start = i * block * 2;
        ss_mul(&mut aa[start..start + 2 * block], &bb[start..start + 2 * block], m + 1, buf);
    }
    ss_ifft(&mut aa, l, m + 1, buf);
    for i in 0..len { for j in 0..block {
        a[i * block + j] = aa[i * block * 2 + j]
            + aa[(if i == 0 { len - 1 } else { i - 1 }) * block * 2 + block + j];
    }}
}

#[no_mangle]
pub unsafe extern "C" fn schoenhage_strassen_multiply(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 + 2 * LIMBS || *input != LIMBS as i64 { return -1; }
    let mut a = [0i64; PADDED];
    let mut b = [0i64; PADDED];
    for i in 0..LIMBS {
        let x = *input.add(1 + i);
        let y = *input.add(1 + LIMBS + i);
        if !(0..=1).contains(&x) || !(0..=1).contains(&y) { return -1; }
        a[i] = x; b[i] = y;
    }
    if a[LIMBS - 1] != 1 || b[LIMBS - 1] != 1 { return -1; }
    if output.is_null() || capacity < 129 { return -2; }
    let mut scratch = [0i64; PADDED];
    ss_mul_cyclic(&mut a, &b, 11, &mut scratch);
    let mut result = [0u8; 129];
    let mut carry = 0i64;
    for i in 0..1025 {
        let value = a[i] + carry;
        let bit = (value % 2) as u8;
        carry = value / 2;
        if bit != 0 { result[128 - i / 8] |= bit << (i % 8); }
    }
    let mut bit_index = 1025usize;
    while carry > 0 {
        if carry % 2 != 0 { result[128 - bit_index / 8] |= 1 << (bit_index % 8); }
        carry /= 2;
        bit_index += 1;
    }
    std::slice::from_raw_parts_mut(output, 129).copy_from_slice(&result);
    129
}
