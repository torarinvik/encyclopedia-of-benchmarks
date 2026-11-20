const MAX_N: usize = 32;
const MAX_DOCS: usize = 8;
const MAX_Q: usize = 16;
const MAX_INPUT: usize = 68;
const MAX_OUTPUT: usize = 144;

fn range_min(
    lo: usize,
    hi: usize,
    previous: &[i64; MAX_N],
    table: &[[i32; MAX_N]; 6],
    logs: &[usize; MAX_N + 1],
) -> usize {
    let level = logs[hi - lo + 1];
    let width = 1usize << level;
    let left = table[level][lo] as usize;
    let right = table[level][hi - width + 1] as usize;
    if previous[left] < previous[right] || (previous[left] == previous[right] && left < right) {
        left
    } else {
        right
    }
}

fn report(
    lo: usize,
    hi: usize,
    query_lo: usize,
    previous: &[i64; MAX_N],
    da: &[i64; MAX_N],
    table: &[[i32; MAX_N]; 6],
    logs: &[usize; MAX_N + 1],
    ranks: &mut [usize; MAX_DOCS],
    found_docs: &mut [u8; MAX_DOCS],
    count: &mut usize,
) {
    if lo > hi {
        return;
    }
    let index = range_min(lo, hi, previous, table, logs);
    if previous[index] >= query_lo as i64 {
        return;
    }
    ranks[*count] = index;
    found_docs[*count] = da[index] as u8;
    *count += 1;
    if index > lo {
        report(lo, index - 1, query_lo, previous, da, table, logs, ranks, found_docs, count);
    }
    if index < hi {
        report(index + 1, hi, query_lo, previous, da, table, logs, ranks, found_docs, count);
    }
}

#[no_mangle]
pub unsafe extern "C" fn muthukrishnan_document_listing(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 3 || length > MAX_INPUT {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);
    let n_value = input[0];
    let docs_value = input[1];
    let q_value = input[2];
    if !(1..=MAX_N as i64).contains(&n_value)
        || !(1..=MAX_DOCS as i64).contains(&docs_value)
        || !(1..=MAX_Q as i64).contains(&q_value)
    {
        return -1;
    }
    let n = n_value as usize;
    let q = q_value as usize;
    if length != 3 + n + 2 * q {
        return -1;
    }

    let mut da = [0i64; MAX_N];
    let mut previous = [0i64; MAX_N];
    let mut last = [-1i64; MAX_DOCS];
    for i in 0..n {
        let document = input[3 + i];
        if document < 0 || document >= docs_value {
            return -1;
        }
        da[i] = document;
        previous[i] = last[document as usize];
        last[document as usize] = i as i64;
    }
    for query in 0..q {
        let lo = input[3 + n + 2 * query];
        let hi = input[4 + n + 2 * query];
        if lo < 0 || hi < lo || hi >= n_value {
            return -1;
        }
    }

    let mut logs = [0usize; MAX_N + 1];
    for size in 2..=n {
        logs[size] = logs[size / 2] + 1;
    }
    let mut table = [[-1i32; MAX_N]; 6];
    for i in 0..n {
        table[0][i] = i as i32;
    }
    let level_count = logs[n] + 1;
    for level in 1..level_count {
        let width = 1usize << level;
        let half = width / 2;
        for start in 0..=n - width {
            let left = table[level - 1][start] as usize;
            let right = table[level - 1][start + half] as usize;
            table[level][start] = if previous[left] < previous[right]
                || (previous[left] == previous[right] && left < right)
            {
                left as i32
            } else {
                right as i32
            };
        }
    }

    let mut staged = [0u8; MAX_OUTPUT];
    let mut written = 0usize;
    for query in 0..q {
        let lo = input[3 + n + 2 * query] as usize;
        let hi = input[4 + n + 2 * query] as usize;
        let count_at = written;
        written += 1;
        let mut ranks = [0usize; MAX_DOCS];
        let mut found_docs = [0u8; MAX_DOCS];
        let mut count = 0usize;
        report(lo, hi, lo, &previous, &da, &table, &logs, &mut ranks, &mut found_docs, &mut count);
        for i in 1..count {
            let rank = ranks[i];
            let document = found_docs[i];
            let mut j = i;
            while j > 0 && ranks[j - 1] > rank {
                ranks[j] = ranks[j - 1];
                found_docs[j] = found_docs[j - 1];
                j -= 1;
            }
            ranks[j] = rank;
            found_docs[j] = document;
        }
        staged[count_at] = count as u8;
        for i in 0..count {
            staged[written] = found_docs[i];
            written += 1;
        }
    }
    if written > MAX_OUTPUT {
        return -1;
    }
    if output.is_null() || output_capacity < written {
        return -2;
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, written);
    written as i64
}
