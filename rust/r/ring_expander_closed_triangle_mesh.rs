use std::slice;

const N: usize = 12;
const T: usize = 20;
const C: usize = 60;
const MAX_INPUT: usize = 64;

fn put_word(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

fn vertex(faces: &[i64], corner: usize) -> usize {
    faces[3 * (corner / 3) + corner % 3] as usize
}
fn next(corner: usize) -> usize { 3 * (corner / 3) + (corner % 3 + 1) % 3 }
fn previous(corner: usize) -> usize { 3 * (corner / 3) + (corner % 3 + 2) % 3 }

fn run(n: usize, t: usize, seed: usize, faces: &[i64]) -> Option<(Vec<i64>, u64, u64)> {
    let mut opposite = [-1i32; C];
    let mut link = [[[false; N]; N]; N];
    let mut used = [false; N];
    let mut edge_count = [[0u8; N]; N];
    let mut edge_first = [[-1i32; N]; N];
    let mut edge_second = [[-1i32; N]; N];
    for ti in 0..t {
        let a = faces[3 * ti] as usize;
        let b = faces[3 * ti + 1] as usize;
        let c = faces[3 * ti + 2] as usize;
        used[a] = true; used[b] = true; used[c] = true;
        link[a][b][c] = true; link[a][c][b] = true;
        link[b][c][a] = true; link[b][a][c] = true;
        link[c][a][b] = true; link[c][b][a] = true;
        for j in 0..3 {
            let first = faces[3 * ti + (j + 1) % 3] as usize;
            let second = faces[3 * ti + (j + 2) % 3] as usize;
            let low = first.min(second);
            let high = first.max(second);
            match edge_count[low][high] {
                0 => edge_first[low][high] = (3 * ti + j) as i32,
                1 => edge_second[low][high] = (3 * ti + j) as i32,
                _ => return None,
            }
            edge_count[low][high] += 1;
        }
    }
    if used[..n].iter().any(|&value| !value) { return None; }

    for low in 0..n {
        for high in low + 1..n {
            if edge_count[low][high] == 0 { continue; }
            if edge_count[low][high] != 2 { return None; }
            let a = edge_first[low][high] as usize;
            let b = edge_second[low][high] as usize;
            let (at, aj) = (a / 3, a % 3);
            let (bt, bj) = (b / 3, b % 3);
            let a0 = faces[3 * at + (aj + 1) % 3];
            let a1 = faces[3 * at + (aj + 2) % 3];
            let b0 = faces[3 * bt + (bj + 1) % 3];
            let b1 = faces[3 * bt + (bj + 2) % 3];
            if a0 != b1 || a1 != b0 { return None; }
            opposite[a] = b as i32;
            opposite[b] = a as i32;
        }
    }

    for v in 0..n {
        let mut start = None;
        for w in 0..n {
            let degree = link[v][w][..n].iter().filter(|&&edge| edge).count();
            if degree > 0 && start.is_none() { start = Some(w); }
            if degree > 0 && degree != 2 { return None; }
        }
        let start = start?;
        let mut seen = [false; N];
        let mut queue = [0usize; N];
        let mut head = 0; let mut tail = 0;
        seen[start] = true; queue[tail] = start; tail += 1;
        while head < tail {
            let w = queue[head]; head += 1;
            for x in 0..n {
                if link[v][w][x] && !seen[x] { seen[x] = true; queue[tail] = x; tail += 1; }
            }
        }
        for w in 0..n {
            if link[v][w][..n].iter().any(|&edge| edge) && !seen[w] { return None; }
        }
    }

    let mut reached = [false; T];
    let mut queue = [0usize; T];
    let mut head = 0; let mut tail = 0;
    reached[0] = true; queue[tail] = 0; tail += 1;
    while head < tail {
        let ti = queue[head]; head += 1;
        for j in 0..3 {
            let other = opposite[3 * ti + j] as usize / 3;
            if !reached[other] { reached[other] = true; queue[tail] = other; tail += 1; }
        }
    }
    if reached[..t].iter().any(|&value| !value) { return None; }

    let mut seen_corner = [false; C];
    let mut vertex_mask = 0u64;
    let mut triangle_mask = 0u64;
    let mut trace = Vec::with_capacity(3 * t);
    vertex_mask |= 1u64 << vertex(faces, next(seed));
    vertex_mask |= 1u64 << vertex(faces, previous(seed));
    let stop = opposite[seed] as usize;
    let mut corner = seed;
    while corner != stop {
        if corner >= 3 * t || seen_corner[corner] || trace.len() >= 3 * t { return None; }
        seen_corner[corner] = true;
        trace.push(corner as i64);
        let ti = corner / 3;
        let v = vertex(faces, corner);
        if (vertex_mask >> v) & 1 == 0 {
            vertex_mask |= 1u64 << v;
            triangle_mask |= 1u64 << ti;
        } else if (triangle_mask >> ti) & 1 == 0 {
            corner = opposite[corner] as usize;
        }
        corner = opposite[previous(corner)] as usize;
    }
    Some((trace, vertex_mask, triangle_mask))
}

#[no_mangle]
pub unsafe extern "C" fn ring_expander_closed_triangle_mesh(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 15 || length > MAX_INPUT { return -1; }
    let values = slice::from_raw_parts(input, length);
    let n64 = values[0]; let t64 = values[1]; let seed64 = values[2];
    if !(4..=N as i64).contains(&n64) || !(4..=T as i64).contains(&t64) { return -1; }
    let n = n64 as usize; let t = t64 as usize;
    if length != 3 + 3 * t || seed64 < 0 || seed64 >= (3 * t) as i64 { return -1; }
    let faces = &values[3..];
    if faces.iter().any(|&v| v < 0 || v >= n64) { return -1; }
    for ti in 0..t {
        let a = faces[3 * ti]; let b = faces[3 * ti + 1]; let c = faces[3 * ti + 2];
        if a == b || b == c || c == a { return -1; }
    }
    let Some((trace, vertices, triangles)) = run(n, t, seed64 as usize, faces) else { return -1; };
    let words = 1 + trace.len() + 2;
    let bytes = 8 * words;
    if output.is_null() || capacity < bytes { return -2; }
    let out = slice::from_raw_parts_mut(output, bytes);
    put_word(out, 0, trace.len() as i64);
    for (i, &corner) in trace.iter().enumerate() { put_word(out, 8 * (i + 1), corner); }
    put_word(out, 8 * (trace.len() + 1), vertices as i64);
    put_word(out, 8 * (trace.len() + 2), triangles as i64);
    bytes as i64
}
