const N: usize = 64;
const K: usize = 4;
const INPUT_LIMIT: usize = 67;
const OUTPUT_LIMIT: usize = 320;
const LEVELS: usize = 7;

fn pair_less(a: usize, b: usize, width: usize, rank: &[u8; N], n: usize) -> bool {
    if rank[a] != rank[b] { return rank[a] < rank[b]; }
    let ra = if a + width < n { rank[a + width] as i16 } else { -1 };
    let rb = if b + width < n { rank[b + width] as i16 } else { -1 };
    ra < rb
}

fn lce(a: usize, b: usize, n: usize, inverse: &[usize; N],
       sparse: &[[u8; N]; LEVELS], logs: &[u8; N + 1]) -> usize {
    if a >= n || b >= n { return 0; }
    if a == b { return n - a; }
    let (mut left, right) = if inverse[a] < inverse[b] { (inverse[a], inverse[b]) } else { (inverse[b], inverse[a]) };
    left += 1;
    let count = right - left + 1;
    let level = logs[count] as usize;
    let span = 1usize << level;
    sparse[level][left].min(sparse[level][right - span + 1]) as usize
}

#[no_mangle]
pub unsafe extern "C" fn k_mismatch_longest_extension_table(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 3 || length > INPUT_LIMIT { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if !(1..=N as i64).contains(&input[0]) || !(0..=K as i64).contains(&input[1]) { return -1; }
    let n = input[0] as usize;
    let budget = input[1] as usize;
    if length != n + 2 { return -1; }

    let mut text = [0u8; N];
    let mut suffixes = [0usize; N];
    let mut rank = [0u8; N];
    let mut inverse = [0usize; N];
    let mut lcp = [0u8; N];
    let mut sparse = [[0u8; N]; LEVELS];
    let mut logs = [0u8; N + 1];
    let mut staged = [0u8; OUTPUT_LIMIT];
    for i in 0..n {
        if !(0..=25).contains(&input[i + 2]) { return -1; }
        text[i] = input[i + 2] as u8;
        suffixes[i] = i;
        rank[i] = text[i];
    }
    let mut width = 1;
    while width < n {
        for i in 1..n {
            let key = suffixes[i];
            let mut j = i;
            while j > 0 && pair_less(key, suffixes[j - 1], width, &rank, n) {
                suffixes[j] = suffixes[j - 1];
                j -= 1;
            }
            suffixes[j] = key;
        }
        let mut classes = 0;
        let mut next_rank = [0u8; N];
        next_rank[suffixes[0]] = 0;
        for i in 1..n {
            let (a, b) = (suffixes[i - 1], suffixes[i]);
            let a2 = if a + width < n { rank[a + width] as i16 } else { -1 };
            let b2 = if b + width < n { rank[b + width] as i16 } else { -1 };
            if rank[a] != rank[b] || a2 != b2 { classes += 1; }
            next_rank[b] = classes as u8;
        }
        rank = next_rank;
        if classes == n - 1 || width > n / 2 { break; }
        width *= 2;
    }
    for i in 0..n { inverse[suffixes[i]] = i; }
    let mut matched = 0;
    for start in 0..n {
        let order = inverse[start];
        if order == 0 { matched = 0; continue; }
        let other = suffixes[order - 1];
        while start + matched < n && other + matched < n && text[start + matched] == text[other + matched] { matched += 1; }
        lcp[order] = matched as u8;
        if matched > 0 { matched -= 1; }
    }
    sparse[0] = lcp;
    for level in 1..LEVELS {
        let span = 1usize << level;
        let half = span / 2;
        for i in 0..=n.saturating_sub(span) {
            sparse[level][i] = sparse[level - 1][i].min(sparse[level - 1][i + half]);
        }
    }
    for count in 2..=n { logs[count] = logs[count / 2] + 1; }
    let mut written = 0;
    for p in 0..n {
        let limit = n - p;
        let mut extension = lce(0, p, n, &inverse, &sparse, &logs).min(limit);
        staged[written] = extension as u8;
        written += 1;
        for _ in 1..=budget {
            if extension < limit {
                extension = (extension + 1 + lce(extension + 1, p + extension + 1, n, &inverse, &sparse, &logs)).min(limit);
            }
            staged[written] = extension as u8;
            written += 1;
        }
    }
    if written > OUTPUT_LIMIT { return -1; }
    if output.is_null() || capacity < written { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, written);
    written as i64
}
