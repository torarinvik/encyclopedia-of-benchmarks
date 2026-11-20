const MAX_N: usize = 8;
const MAX_M: usize = 24;
const MAX_PARSEABLE_IN: usize = 99;
const MAX_WORDS: usize = 44;

#[derive(Clone, Copy)]
struct Formula {
    literals: [[i32; 3]; MAX_M],
    lengths: [usize; MAX_M],
    active: [bool; MAX_M],
}

#[derive(Clone, Copy, Default)]
struct Event { literal: i64, kind: i64, bi: i64, bj: i64 }

impl Formula {
    const fn empty() -> Self {
        Self { literals: [[0; 3]; MAX_M], lengths: [0; MAX_M], active: [false; MAX_M] }
    }
}

fn simplify(f: &mut Formula, m: usize, values: &mut [i32; MAX_N], literal: i32) -> bool {
    let v = literal.unsigned_abs() as usize - 1;
    let value = if literal > 0 { 1 } else { -1 };
    if values[v] != 0 && values[v] != value { return false; }
    values[v] = value;
    for c in 0..m {
        if !f.active[c] { continue; }
        let mut satisfied = false;
        for j in 0..f.lengths[c] { if f.literals[c][j] == literal { satisfied = true; } }
        if satisfied { f.active[c] = false; continue; }
        let mut kept = 0;
        for j in 0..f.lengths[c] {
            let item = f.literals[c][j];
            if item != -literal { f.literals[c][kept] = item; kept += 1; }
        }
        f.lengths[c] = kept;
        if kept == 0 { return false; }
    }
    true
}

fn propagate(f: &mut Formula, m: usize, values: &mut [i32; MAX_N],
             events: Option<&mut [Event; MAX_N]>, count: &mut usize) -> bool {
    let mut events = events;
    loop {
        let mut unit = 0;
        for c in 0..m {
            if f.active[c] && f.lengths[c] == 1 { unit = f.literals[c][0]; break; }
        }
        if unit == 0 { return true; }
        if let Some(log) = events.as_deref_mut() {
            log[*count] = Event { literal: unit as i64, kind: 1, bi: -1, bj: -1 };
            *count += 1;
        }
        if !simplify(f, m, values, unit) { return false; }
    }
}

fn degrees(f: &Formula, m: usize, n: usize) -> ([i32; MAX_N], [i32; MAX_N]) {
    let mut p = [0; MAX_N];
    let mut q = [0; MAX_N];
    for c in 0..m { if f.active[c] {
        for j in 0..f.lengths[c] {
            let x = f.literals[c][j];
            if x > 0 { p[x as usize - 1] += 1; } else { q[x.unsigned_abs() as usize - 1] += 1; }
        }
    }}
    let _ = n;
    (p, q)
}

fn member(f: &Formula, m: usize, n: usize, values: &[i32; MAX_N], bi: usize, bj: usize) -> i32 {
    let (p, q) = degrees(f, m, n);
    for v in 0..n {
        if values[v] != 0 { continue; }
        let pi = p[v].min(10) as usize;
        let qj = q[v].min(10) as usize;
        if pi == bi && qj == bj { return v as i32 + 1; }
        if qj == bi && pi == bj { return -(v as i32 + 1); }
    }
    0
}

fn flows(f: &Formula, m: usize, n: usize) -> (i64, i64, i64) {
    let mut p2 = [0i64; MAX_N]; let mut q2 = [0i64; MAX_N];
    let mut p3 = [0i64; MAX_N]; let mut q3 = [0i64; MAX_N];
    let mut count2 = 0i64;
    for c in 0..m { if f.active[c] {
        let (p, q) = if f.lengths[c] == 2 { count2 += 1; (&mut p2, &mut q2) }
                    else if f.lengths[c] == 3 { (&mut p3, &mut q3) } else { continue };
        for j in 0..f.lengths[c] {
            let x = f.literals[c][j];
            if x > 0 { p[x as usize - 1] += 1; } else { q[x.unsigned_abs() as usize - 1] += 1; }
        }
    }}
    let mut s2 = 0i64; let mut s3 = 0i64;
    for c in 0..m { if f.active[c] && f.lengths[c] == 2 {
        for j in 0..2 {
            let x = -f.literals[c][j];
            let v = x.unsigned_abs() as usize - 1;
            s2 += if x > 0 { p2[v] } else { q2[v] };
            s3 += if x > 0 { p3[v] } else { q3[v] };
        }
    }}
    let den = if count2 == 0 { 1 } else { 2 * count2 };
    let _ = n;
    (s2, s3, den)
}

fn choose(f: &Formula, m: usize, n: usize, values: &[i32; MAX_N]) -> Option<(usize, usize)> {
    let (old2, old3, old_den) = flows(f, m, n);
    let mut best: Option<(i64, i64, usize, usize)> = None;
    for bi in 0..=10 { for bj in 0..=10 {
        let literal = member(f, m, n, values, bi, bj);
        if literal == 0 { continue; }
        let mut trial = *f;
        let mut trial_values = *values;
        let mut ignored_count = 0usize;
        if !simplify(&mut trial, m, &mut trial_values, literal) ||
           !propagate(&mut trial, m, &mut trial_values, None, &mut ignored_count) { continue; }
        let (next2, next3, next_den) = flows(&trial, m, n);
        let mut num = next2 * old_den - old2 * next_den;
        let mut den = next3 * old_den - old3 * next_den;
        if den == 0 { continue; }
        if den < 0 { num = -num; den = -den; }
        let replace = match best {
            None => true,
            Some((bn, bd, ii, jj)) => num * bd > bn * den ||
                (num * bd == bn * den && (bi < ii || (bi == ii && bj < jj))),
        };
        if replace { best = Some((num, den, bi, bj)); }
    }}
    best.map(|(_, _, i, j)| (i, j))
}

fn store(out: &mut [u8], at: usize, value: i64) {
    let bytes = value.to_le_bytes();
    out[at..at + 8].copy_from_slice(&bytes);
}

#[no_mangle]
pub unsafe extern "C" fn random_3sat_cl_bucket_heuristic(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_IN { return -1; }
    let frame = core::slice::from_raw_parts(input, length);
    let n0 = frame[0]; let m0 = frame[1];
    if n0 < 1 || n0 > MAX_N as i64 || m0 < 0 || m0 > MAX_M as i64 || length != 2 + 4 * m0 as usize { return -1; }
    let n = n0 as usize; let m = m0 as usize;
    let mut f = Formula::empty();
    for c in 0..m {
        let base = 2 + 4 * c;
        let k = frame[base];
        if !(1..=3).contains(&k) { return -1; }
        f.lengths[c] = k as usize;
        let mut seen = [false; MAX_N];
        for j in 0..3 {
            let x = frame[base + 1 + j];
            if j < k as usize {
                if x == 0 || x < -n0 || x > n0 { return -1; }
                let v = x.unsigned_abs() as usize - 1;
                if seen[v] { return -1; }
                seen[v] = true; f.literals[c][j] = x as i32;
            } else if x != 0 { return -1; }
        }
        f.active[c] = true;
    }

    let mut values = [0i32; MAX_N];
    let mut events = [Event::default(); MAX_N];
    let mut count = 0usize;
    let mut status = 0i64;
    if !propagate(&mut f, m, &mut values, Some(&mut events), &mut count) { status = 1; }
    while status == 0 && values[..n].contains(&0) {
        let Some((bi, bj)) = choose(&f, m, n, &values) else { status = 2; break; };
        let literal = member(&f, m, n, &values, bi, bj);
        if literal == 0 { status = 2; break; }
        events[count] = Event { literal: literal as i64, kind: 0, bi: bi as i64, bj: bj as i64 };
        count += 1;
        if !simplify(&mut f, m, &mut values, literal) { status = 1; break; }
        if !propagate(&mut f, m, &mut values, Some(&mut events), &mut count) { status = 1; break; }
    }
    if output.is_null() { return -2; }
    let mut words = [0i64; MAX_WORDS];
    let mut at = 0usize;
    words[at] = status; at += 1; words[at] = n as i64; at += 1;
    words[at] = values[..n].iter().filter(|&&v| v != 0).count() as i64; at += 1;
    for &v in &values[..n] { words[at] = v as i64; at += 1; }
    words[at] = count as i64; at += 1;
    for e in &events[..count] {
        words[at] = e.literal; at += 1; words[at] = e.kind; at += 1;
        words[at] = e.bi; at += 1; words[at] = e.bj; at += 1;
    }
    let bytes = at * 8;
    if capacity < bytes { return -2; }
    let mut staged = [0u8; 352];
    for i in 0..at { store(&mut staged, i * 8, words[i]); }
    core::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes);
    bytes as i64
}
