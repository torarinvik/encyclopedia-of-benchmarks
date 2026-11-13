const MAX_KEYS: usize = 24;
const MAX_QUERIES: usize = 24;
const UNIVERSE_BITS: usize = 16;
const LEVELS: usize = UNIVERSE_BITS + 1;
const MAX_PARSEABLE: usize = 51;

fn prefix_of(key: i64, depth: usize) -> i64 {
    if depth == 0 { 0 } else { key >> (UNIVERSE_BITS - depth) }
}

fn find_prefix(prefixes: &[[i64; MAX_KEYS]; LEVELS], counts: &[usize; LEVELS],
               depth: usize, wanted: i64) -> Option<usize> {
    let mut low = 0;
    let mut high = counts[depth];
    while low < high {
        let middle = low + (high - low) / 2;
        if prefixes[depth][middle] < wanted { low = middle + 1; }
        else { high = middle; }
    }
    if low < counts[depth] && prefixes[depth][low] == wanted { Some(low) } else { None }
}

fn predecessor(prefixes: &[[i64; MAX_KEYS]; LEVELS], maxima: &[[i64; MAX_KEYS]; LEVELS],
               counts: &[usize; LEVELS], query: i64) -> i64 {
    let mut low = 0;
    let mut high = LEVELS;
    while high - low > 1 {
        let middle = low + (high - low) / 2;
        if find_prefix(prefixes, counts, middle, prefix_of(query, middle)).is_some() { low = middle; }
        else { high = middle; }
    }
    if low == UNIVERSE_BITS { return query; }
    let mut depth = low + 1;
    while depth > 0 {
        let query_prefix = query >> (UNIVERSE_BITS - depth);
        if query_prefix & 1 != 0 {
            if let Some(position) = find_prefix(prefixes, counts, depth, query_prefix - 1) {
                return maxima[depth][position];
            }
        }
        depth -= 1;
    }
    -1
}

#[no_mangle]
pub unsafe extern "C" fn x_fast_trie_static_predecessor(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE { return -1; }
    let n_value = *input;
    let q_value = *input.add(1);
    if n_value < 0 || n_value > MAX_KEYS as i64 || q_value < 0 || q_value > MAX_QUERIES as i64 { return -1; }
    let n = n_value as usize;
    let q = q_value as usize;
    if length != 2 + n + q { return -1; }
    let mut keys = [0_i64; MAX_KEYS];
    let mut queries = [0_i64; MAX_QUERIES];
    for i in 0..n {
        keys[i] = *input.add(2 + i);
        if !(0..=65535).contains(&keys[i]) { return -1; }
    }
    keys[..n].sort_unstable();
    for i in 1..n { if keys[i] == keys[i - 1] { return -1; } }
    for i in 0..q {
        queries[i] = *input.add(2 + n + i);
        if !(0..=65535).contains(&queries[i]) { return -1; }
    }
    if n == 0 || q == 0 { return 0; }

    let mut prefixes = [[0_i64; MAX_KEYS]; LEVELS];
    let mut maxima = [[0_i64; MAX_KEYS]; LEVELS];
    let mut counts = [0_usize; LEVELS];
    for depth in 0..LEVELS {
        for &key in &keys[..n] {
            let value = prefix_of(key, depth);
            if counts[depth] == 0 || prefixes[depth][counts[depth] - 1] != value {
                let position = counts[depth];
                prefixes[depth][position] = value;
                maxima[depth][position] = key;
                counts[depth] += 1;
            } else {
                maxima[depth][counts[depth] - 1] = key;
            }
        }
    }
    let mut checksum = 0_i64;
    for i in 0..q {
        checksum += (i as i64 + 1) * (predecessor(&prefixes, &maxima, &counts, queries[i]) + 1);
    }
    checksum
}
