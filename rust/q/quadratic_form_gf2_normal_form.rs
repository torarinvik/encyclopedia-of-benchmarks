//! Uncompiled GF(2) quadratic-form normal-form draft.

fn value(rows: &[u128; 100], n: usize, x: u128) -> u8 {
    let mut result = 0;
    for (i, row) in rows.iter().enumerate().take(n) {
        if (x >> i) & 1 != 0 { result ^= ((*row & x).count_ones() & 1) as u8; }
    }
    result
}

fn polar(rows: &[u128; 100], n: usize, x: u128, y: u128) -> u8 {
    let mut result = 0;
    for (i, row) in rows.iter().enumerate().take(n) {
        if (x >> i) & 1 != 0 { result ^= ((*row & y).count_ones() & 1) as u8; }
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn quadratic_form_gf2_normal_form(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length == 0 || length > 202 { return -1; }
    let frame = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=100).contains(&frame[0]) { return -1; }
    let n = frame[0] as usize;
    let words = (n + 62) / 63;
    if length != 1 + n * words { return -1; }
    let mut upper = [0u128; 100];
    let mut bilinear = [0u128; 100];
    for i in 0..n {
        for chunk in 0..words {
            let raw = frame[1 + i * words + chunk];
            if raw < 0 { return -1; }
            for bit in 0..63 {
                if ((raw as u64 >> bit) & 1) == 0 { continue; }
                let j = 63 * chunk + bit;
                if j >= n || j < i { return -1; }
                upper[i] |= 1u128 << j;
                if i != j { bilinear[i] |= 1u128 << j; bilinear[j] |= 1u128 << i; }
            }
        }
    }
    let row_bytes = (n + 7) / 8;
    let needed = 3 + n * row_bytes;
    if output.is_null() || capacity < needed { return -2; }

    let mut remaining = [0u128; 100];
    let mut hyper = [0u128; 100];
    let mut anis = [0u128; 100];
    for (i, item) in remaining.iter_mut().enumerate().take(n) { *item = 1u128 << i; }
    let (mut count, mut hc, mut ac) = (n, 0usize, 0usize);
    loop {
        let mut pair = None;
        'find: for i in 0..count {
            for j in i + 1..count {
                if polar(&bilinear, n, remaining[i], remaining[j]) != 0 {
                    pair = Some((i, j));
                    break 'find;
                }
            }
        }
        let Some((i, j)) = pair else { break };
        let (mut u, mut v) = (remaining[i], remaining[j]);
        let mut rest = [0u128; 100];
        let mut next = 0;
        for (index, &w) in remaining[..count].iter().enumerate() {
            if index == i || index == j { continue; }
            let add_u = if polar(&bilinear, n, w, v) != 0 { u } else { 0 };
            let add_v = if polar(&bilinear, n, w, u) != 0 { v } else { 0 };
            rest[next] = w ^ add_u ^ add_v;
            next += 1;
        }
        remaining = rest;
        count = next;
        let (qu, qv) = (value(&upper, n, u), value(&upper, n, v));
        if qu != 0 && qv != 0 {
            anis[ac] = u; anis[ac + 1] = v; ac += 2;
        } else {
            if qu != 0 { u ^= v; } else if qv != 0 { v ^= u; }
            hyper[hc] = u; hyper[hc + 1] = v; hc += 2;
        }
    }
    while ac >= 4 {
        let (a, b, c, d) = (anis[ac - 2], anis[ac - 1], anis[ac - 4], anis[ac - 3]);
        ac -= 4;
        let f = d ^ a ^ b;
        hyper[hc] = a ^ c; hyper[hc + 1] = b ^ c;
        hyper[hc + 2] = f; hyper[hc + 3] = f ^ c; hc += 4;
    }
    let pivot = (0..count).find(|&i| value(&upper, n, remaining[i]) != 0);
    let mut linear = 0;
    if let Some(index) = pivot {
        linear = remaining[index];
        for i in index + 1..count { remaining[i - 1] = remaining[i]; }
        count -= 1;
        for w in &mut remaining[..count] {
            if value(&upper, n, *w) != 0 { *w ^= linear; }
        }
        if ac != 0 {
            hyper[hc] = anis[0] ^ linear; hyper[hc + 1] = anis[1] ^ linear;
            hc += 2; ac = 0;
        }
    }
    let mut columns = [0u128; 100];
    let mut used = 0;
    for &v in &hyper[..hc] { columns[used] = v; used += 1; }
    for &v in &anis[..ac] { columns[used] = v; used += 1; }
    if pivot.is_some() { columns[used] = linear; used += 1; }
    for &v in &remaining[..count] { columns[used] = v; used += 1; }
    if used != n || hc % 2 != 0 || (ac != 0 && ac != 2) { return -4; }

    let mut matrix = [0u128; 100];
    let mut inverse = [0u128; 100];
    for i in 0..n {
        inverse[i] = 1u128 << i;
        for (j, column) in columns[..n].iter().enumerate() {
            if (*column >> i) & 1 != 0 { matrix[i] |= 1u128 << j; }
        }
    }
    for col in 0..n {
        let Some(p) = (col..n).find(|&row| (matrix[row] >> col) & 1 != 0) else { return -4 };
        matrix.swap(col, p); inverse.swap(col, p);
        let pivot_matrix = matrix[col];
        let pivot_inverse = inverse[col];
        for row in 0..n {
            if row != col && (matrix[row] >> col) & 1 != 0 {
                matrix[row] ^= pivot_matrix; inverse[row] ^= pivot_inverse;
            }
        }
    }
    let mut staged = [0u8; 1303];
    staged[0] = (hc / 2) as u8; staged[1] = (ac / 2) as u8; staged[2] = u8::from(pivot.is_some());
    for i in 0..n {
        for j in 0..n {
            if (inverse[i] >> j) & 1 != 0 { staged[3 + i * row_bytes + j / 8] |= 1 << (j % 8); }
        }
    }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, needed); }
    needed as i64
}
