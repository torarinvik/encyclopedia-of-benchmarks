const MAX_LEN: usize = 32;
const MAX_BLOCKS: usize = 16;
const MAX_WORDS: usize = 114;
const MAX_INPUT: usize = 68;
const INSERT: i64 = 0;
const COPY: i64 = 1;

fn hash(data: &[i64], start: usize, width: usize) -> i64 {
    let mut value = 0i64;
    for i in 0..width { value = value * 257 + data[start + i] + 1; }
    value
}

fn suffix_cmp(hashes: &[i64; MAX_BLOCKS], count: usize, mut a: usize, mut b: usize) -> i32 {
    while a < count && b < count {
        if hashes[a] != hashes[b] { return if hashes[a] < hashes[b] { -1 } else { 1 }; }
        a += 1; b += 1;
    }
    if a == count && b == count { 0 } else if a == count { -1 } else { 1 }
}

fn prefix_cmp(hashes: &[i64; MAX_BLOCKS], count: usize, suffix: usize,
              query: &[i64; MAX_BLOCKS], depth: usize) -> i32 {
    for i in 0..depth {
        if suffix + i >= count { return -1; }
        if hashes[suffix + i] != query[i] { return if hashes[suffix + i] < query[i] { -1 } else { 1 }; }
    }
    0
}

fn interval(sa: &[usize; MAX_BLOCKS], count: usize, hashes: &[i64; MAX_BLOCKS],
             query: &[i64; MAX_BLOCKS], depth: usize) -> (usize, usize) {
    let (mut lo, mut hi) = (0, count);
    while lo < hi {
        let mid = lo + (hi - lo) / 2;
        if prefix_cmp(hashes, count, sa[mid], query, depth) < 0 { lo = mid + 1; } else { hi = mid; }
    }
    let first = lo; hi = count;
    while lo < hi {
        let mid = lo + (hi - lo) / 2;
        if prefix_cmp(hashes, count, sa[mid], query, depth) <= 0 { lo = mid + 1; } else { hi = mid; }
    }
    (first, lo)
}

fn best_depth(sa: &[usize; MAX_BLOCKS], count: usize, hashes: &[i64; MAX_BLOCKS],
              query: &[i64; MAX_BLOCKS], qcount: usize) -> usize {
    let (mut lo, mut hi) = (0, count.min(qcount) + 1);
    while lo + 1 < hi {
        let mid = lo + (hi - lo) / 2;
        let (first, last) = interval(sa, count, hashes, query, mid);
        if first < last { lo = mid; } else { hi = mid; }
    }
    lo
}

fn extend(reference: &[i64], version: &[i64], source: usize, target: usize,
           floor: usize) -> (usize, usize, usize) {
    let (mut s, mut t, mut length) = (source, target, 0);
    while s + length < reference.len() && t + length < version.len()
        && reference[s + length] == version[t + length] { length += 1; }
    while s > 0 && t > floor && reference[s - 1] == version[t - 1] { s -= 1; t -= 1; length += 1; }
    (s, t, length)
}

fn find_at(reference: &[i64], version: &[i64], p: usize, sa: &[usize; MAX_BLOCKS],
            count: usize, hashes: &[i64; MAX_BLOCKS], target: usize, floor: usize)
            -> Option<(usize, usize, usize)> {
    let qcount = (version.len() - target) / p;
    if qcount == 0 || count == 0 { return None; }
    let mut query = [0i64; MAX_BLOCKS];
    for i in 0..qcount { query[i] = hash(version, target + i * p, p); }
    let depth = best_depth(sa, count, hashes, &query, qcount);
    if depth == 0 { return None; }
    let (first, last) = interval(sa, count, hashes, &query, depth.saturating_sub(1).max(1));
    let mut best: Option<(usize, usize, usize)> = None;
    for rank in first..last {
        let source = sa[rank] * p;
        if source + p > reference.len() { continue; }
        let candidate = extend(reference, version, source, target, floor);
        if candidate.2 < p { continue; }
        if best.map_or(true, |old| candidate.2 > old.2 ||
            (candidate.2 == old.2 && (candidate.1, candidate.0) < (old.1, old.0))) { best = Some(candidate); }
    }
    best
}

fn push_insert(tokens: &mut [i64; MAX_WORDS], words: &mut usize, version: &[i64], start: usize, end: usize) {
    if end <= start { return; }
    tokens[*words] = INSERT; *words += 1;
    tokens[*words] = (end - start) as i64; *words += 1;
    for i in start..end { tokens[*words] = version[i]; *words += 1; }
}

fn execute(values: &[i64], output_is_null: bool, capacity: usize) -> (i64, [i64; MAX_WORDS]) {
    let mut tokens = [0i64; MAX_WORDS];
    if values.len() < 3 || values.len() > MAX_INPUT { return (-1, tokens); }
    let (mv, nv, pv) = (values[0], values[1], values[2]);
    if !(0..=MAX_LEN as i64).contains(&mv) || !(0..=MAX_LEN as i64).contains(&nv) || !(2..=4).contains(&pv) { return (-1, tokens); }
    let (m, n, p) = (mv as usize, nv as usize, pv as usize);
    if values.len() != 3 + m + n || values[3..].iter().any(|&x| !(0..=255).contains(&x)) { return (-1, tokens); }
    let reference = &values[3..3 + m];
    let version = &values[3 + m..];
    let mut hashes = [0i64; MAX_BLOCKS];
    let mut sa = [0usize; MAX_BLOCKS];
    let count = if m >= p { (m - p) / p + 1 } else { 0 };
    for i in 0..count { hashes[i] = hash(reference, i * p, p); sa[i] = i; }
    for i in 1..count {
        let value = sa[i]; let mut j = i;
        while j > 0 && (suffix_cmp(&hashes, count, value, sa[j - 1]) < 0 ||
            (suffix_cmp(&hashes, count, value, sa[j - 1]) == 0 && value < sa[j - 1])) {
            sa[j] = sa[j - 1]; j -= 1;
        }
        sa[j] = value;
    }
    let mut words = 0usize;
    let (mut cursor, mut consumed) = (0usize, 0usize);
    while cursor + p <= n {
        let mut best: Option<(usize, usize, usize)> = None;
        let scan_end = (cursor + p - 1).min(n - p);
        for target in cursor..=scan_end {
            if let Some(candidate) = find_at(reference, version, p, &sa, count, &hashes, target, consumed) {
                if best.map_or(true, |old| candidate.2 > old.2 ||
                    (candidate.2 == old.2 && (candidate.1, candidate.0) < (old.1, old.0))) { best = Some(candidate); }
            }
        }
        if let Some((source, target, length)) = best {
            push_insert(&mut tokens, &mut words, version, consumed, target);
            tokens[words] = COPY; words += 1;
            tokens[words] = source as i64; words += 1;
            tokens[words] = length as i64; words += 1;
            consumed = target + length; cursor = consumed;
        } else { cursor += 1; }
    }
    push_insert(&mut tokens, &mut words, version, consumed, n);
    let required = words * 8;
    if required > 0 && (output_is_null || capacity < required) { return (-2, tokens); }
    (required as i64, tokens)
}

#[no_mangle]
pub unsafe extern "C" fn hsadelta_differential_compression(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let (result, tokens) = execute(std::slice::from_raw_parts(input, length), output.is_null(), capacity);
    if result > 0 {
        for i in 0..(result as usize / 8) {
            let bytes = tokens[i].to_le_bytes();
            for b in 0..8 { *output.add(8 * i + b) = bytes[b]; }
        }
    }
    result
}
