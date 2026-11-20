const MAX_TEXT: usize = 64;
const MAX_TOTAL: usize = 65;
const MAX_INPUT: usize = 195;

struct Index {
    cumulative: [usize; 5],
    bwt: [i64; MAX_TOTAL],
}

fn suffix_less(s: &[i64; MAX_TOTAL], total: usize, mut a: usize, mut b: usize) -> bool {
    while a < total && b < total {
        if s[a] != s[b] { return s[a] < s[b]; }
        a += 1;
        b += 1;
    }
    a == total && b != total
}

fn build_index(s: &[i64; MAX_TOTAL], total: usize) -> Index {
    let mut result = Index { cumulative: [0; 5], bwt: [0; MAX_TOTAL] };
    let mut suffixes = [0usize; MAX_TOTAL];
    let mut frequency = [0usize; 5];
    for i in 0..total { suffixes[i] = i; }
    for i in 1..total {
        let key = suffixes[i];
        let mut j = i;
        while j > 0 && suffix_less(s, total, key, suffixes[j - 1]) {
            suffixes[j] = suffixes[j - 1];
            j -= 1;
        }
        suffixes[j] = key;
    }
    for i in 0..total {
        result.bwt[i] = s[(suffixes[i] + total - 1) % total];
        frequency[result.bwt[i] as usize] += 1;
    }
    let mut seen = 0;
    for symbol in 0..5 { result.cumulative[symbol] = seen; seen += frequency[symbol]; }
    result
}

fn rank_before(index: &Index, end: usize, symbol: usize) -> usize {
    let mut count = 0;
    for i in 0..end { if index.bwt[i] as usize == symbol { count += 1; } }
    count
}

#[no_mangle]
pub unsafe extern "C" fn bidirectional_fm_index(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n0 = *input;
    let q0 = *input.add(1);
    if n0 < 0 || n0 > MAX_TEXT as i64 || q0 < 0 || q0 > 64 { return -1; }
    let n = n0 as usize;
    let q = q0 as usize;
    if length != 2 + n + 2 * q { return -1; }
    let mut forward_text = [0i64; MAX_TOTAL];
    let mut reverse_text = [0i64; MAX_TOTAL];
    for i in 0..n {
        let symbol = *input.add(2 + i);
        if symbol < 1 || symbol > 4 { return -1; }
        forward_text[i] = symbol;
        reverse_text[n - 1 - i] = symbol;
    }
    forward_text[n] = 0;
    reverse_text[n] = 0;
    for op in 0..q {
        let side = *input.add(2 + n + 2 * op);
        let symbol = *input.add(3 + n + 2 * op);
        if (side != 0 && side != 1) || symbol < 1 || symbol > 4 { return -1; }
    }

    let total = n + 1;
    let forward = build_index(&forward_text, total);
    let reverse = build_index(&reverse_text, total);
    let (mut fl, mut fr, mut rl, mut rr) = (0usize, total, 0usize, total);
    let mut checksum = 0i64;
    for op in 0..q {
        let side = *input.add(2 + n + 2 * op) as usize;
        let symbol = *input.add(3 + n + 2 * op) as usize;
        let (old_fl, old_fr, old_rl, old_rr) = (fl, fr, rl, rr);
        if side == 0 {
            fl = forward.cumulative[symbol] + rank_before(&forward, old_fl, symbol);
            fr = forward.cumulative[symbol] + rank_before(&forward, old_fr, symbol);
            let mut start = old_rl;
            for smaller in 0..symbol {
                start += rank_before(&forward, old_fr, smaller) - rank_before(&forward, old_fl, smaller);
            }
            let count = rank_before(&forward, old_fr, symbol) - rank_before(&forward, old_fl, symbol);
            rl = start;
            rr = start + count;
        } else {
            rl = reverse.cumulative[symbol] + rank_before(&reverse, old_rl, symbol);
            rr = reverse.cumulative[symbol] + rank_before(&reverse, old_rr, symbol);
            let mut start = old_fl;
            for smaller in 0..symbol {
                start += rank_before(&reverse, old_rr, smaller) - rank_before(&reverse, old_rl, smaller);
            }
            let count = rank_before(&reverse, old_rr, symbol) - rank_before(&reverse, old_rl, symbol);
            fl = start;
            fr = start + count;
        }
        checksum += (op as i64 + 1) * (fr - fl) as i64;
    }
    checksum
}
