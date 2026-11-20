use std::slice;

const N: usize = 8;
const K: usize = 4;
const SCALE: i64 = 86_093_442;
const INF: i64 = 1_i64 << 60;
const MAX_INPUT: usize = 93;

fn even_index(x: usize, threshold: i64, sample: &[[usize; N]; K], d: &[[i64; N]; N]) -> usize {
    if d[x][sample[2][x]] <= threshold { 2 } else { 0 }
}

fn more(u: usize, v: usize, iu: usize, sample: &[[usize; N]; K],
        bunch: &[[bool; N]; N], d: &[[i64; N]; N]) -> bool {
    if iu < 2 { return false; }
    let j = 0;
    bunch[v][sample[j][u]] || bunch[u][sample[j + 1][v]] ||
        bunch[v][sample[iu][u]] || bunch[u][sample[iu + 1][v]]
}

#[no_mangle]
pub unsafe extern "C" fn wulff_nilsen_distance_refinement(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(8..=MAX_INPUT).contains(&length) { return -1; }
    let a = unsafe { slice::from_raw_parts(input, length) };
    let n = a[0]; let m = a[1];
    if !(2..=8).contains(&n) || !(0..=28).contains(&m) || length != 8 + 3 * m as usize { return -1; }
    let mut masks = [0_i64; 3];
    let full = (1_i64 << n) - 1;
    masks.copy_from_slice(&a[2..5]);
    if masks.iter().any(|&x| x <= 0 || x & !full != 0) ||
        masks[1] & !masks[0] != 0 || masks[2] & !masks[1] != 0 { return -1; }

    let mut d = [[INF; N]; N];
    for x in 0..n as usize { d[x][x] = 0; }
    let mut prev = None;
    for e in 0..m as usize {
        let at = 5 + 3 * e;
        let (u, v, w) = (a[at], a[at + 1], a[at + 2]);
        if u < 0 || v <= u || v >= n || w < SCALE || w > 100 * SCALE || w % SCALE != 0 { return -1; }
        if let Some(p) = prev { if (u, v) <= p { return -1; } }
        prev = Some((u, v));
        d[u as usize][v as usize] = w;
        d[v as usize][u as usize] = w;
    }
    let q = 5 + 3 * m as usize;
    let (u0, v0, estimate) = (a[q], a[q + 1], a[q + 2]);
    if u0 < 0 || v0 < 0 || u0 >= n || v0 >= n || u0 == v0 || estimate <= 0 || estimate % SCALE != 0 { return -1; }
    let (u, v) = (u0 as usize, v0 as usize);
    for z in 0..n as usize { for x in 0..n as usize { if d[x][z] != INF {
        for y in 0..n as usize { let candidate = d[x][z] + d[z][y]; if candidate < d[x][y] { d[x][y] = candidate; } }
    } } }
    for x in 0..n as usize { for y in 0..n as usize { if d[x][y] == INF { return -1; } } }
    if estimate < d[u][v] || estimate > 768 * d[u][v] { return -1; }

    let mut sample = [[0_usize; N]; K];
    for x in 0..n as usize {
        sample[0][x] = x;
        for level in 1..K {
            let mut best = usize::MAX;
            for y in 0..n as usize { if masks[level - 1] >> y & 1 != 0 &&
                (best == usize::MAX || (d[x][y], y) < (d[x][best], best)) { best = y; } }
            sample[level][x] = best;
        }
    }
    let layers = [full, masks[0], masks[1], masks[2], 0];
    let mut bunch = [[false; N]; N];
    for center in 0..n as usize { for level in 0..K {
        let mut boundary = INF;
        for y in 0..n as usize { if layers[level + 1] >> y & 1 != 0 { boundary = boundary.min(d[center][y]); } }
        for y in 0..n as usize { if layers[level] >> y & 1 != 0 && layers[level + 1] >> y & 1 == 0 && d[center][y] < boundary { bunch[center][y] = true; } }
    } }

    let mut value = estimate;
    let mut iu = even_index(u, value, &sample, &d);
    if !more(u, v, iu, &sample, &bunch, &d) { return value; }
    let mut iteration = 0;
    while more(u, v, iu, &sample, &bunch, &d) && iteration <= 15 {
        value = 2 * value / 3;
        iu = even_index(u, value, &sample, &d);
        iteration += 1;
    }
    let upper = even_index(u, 3 * value / 2, &sample, &d);
    if upper < 2 { return -1; }
    let j = 0;
    let mut pivot = sample[j][u];
    if bunch[v][pivot] { return d[u][pivot] + d[v][pivot]; }
    pivot = sample[j + 1][v];
    if bunch[u][pivot] { return d[u][pivot] + d[v][pivot]; }
    pivot = sample[upper][u];
    if bunch[v][pivot] { return d[u][pivot] + d[v][pivot]; }
    pivot = sample[upper + 1][v];
    d[u][pivot] + d[v][pivot]
}
