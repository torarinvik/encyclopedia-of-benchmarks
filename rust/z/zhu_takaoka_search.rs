const MAX_TEXT: usize = 256;
const MAX_PATTERN: usize = 16;
const ALPHABET: usize = 16;
const MAX_INPUT: usize = 274;

#[no_mangle]
pub unsafe extern "C" fn zhu_takaoka_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT {
        return -2;
    }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_TEXT as i64).contains(&values[0])
        || !(2..=MAX_PATTERN as i64).contains(&values[1])
    {
        return -2;
    }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + n + m {
        return -2;
    }
    if values[2..].iter().any(|&symbol| !(0..ALPHABET as i64).contains(&symbol)) {
        return -2;
    }
    if m > n {
        return -1;
    }

    let p = 2 + n;
    let mut pair_shift = [[m; ALPHABET]; ALPHABET];
    for first in 0..ALPHABET {
        pair_shift[first][values[p] as usize] = m - 1;
    }
    for i in 1..m - 1 {
        pair_shift[values[p + i - 1] as usize][values[p + i] as usize] = m - 1 - i;
    }

    let mut good_suffix = [m; MAX_PATTERN];
    for mismatch in 0..m {
        for shift in 1..=m {
            let first_known = (mismatch + 1).max(shift);
            let mut position = first_known;
            while position < m && values[p + position] == values[p + position - shift] {
                position += 1;
            }
            if position < m {
                continue;
            }
            if mismatch + 1 < m
                && shift <= mismatch
                && values[p + mismatch - shift] == values[p + mismatch]
            {
                continue;
            }
            good_suffix[mismatch] = shift;
            break;
        }
    }

    let mut start = 0;
    while start <= n - m {
        let mut mismatch = m;
        while mismatch > 0 && values[p + mismatch - 1] == values[2 + start + mismatch - 1] {
            mismatch -= 1;
        }
        if mismatch == 0 {
            return start as i64;
        }
        mismatch -= 1;
        let first = values[2 + start + m - 2] as usize;
        let second = values[2 + start + m - 1] as usize;
        start += good_suffix[mismatch].max(pair_shift[first][second]);
    }
    -1
}
