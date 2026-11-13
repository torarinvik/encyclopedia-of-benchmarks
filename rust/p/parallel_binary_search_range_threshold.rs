const MAX_N: usize = 16;
const MAX_EVENTS: usize = 32;
const MAX_QUERIES: usize = 32;
const MAX_PARSEABLE_LENGTH: usize = 196;

fn bit_add(bit: &mut [i64; MAX_N + 2], mut index: usize, delta: i64, limit: usize) {
    while index <= limit + 1 {
        bit[index] += delta;
        index += index & index.wrapping_neg();
    }
}

fn bit_sum(bit: &[i64; MAX_N + 2], mut index: usize) -> i64 {
    let mut total = 0_i64;
    while index > 0 {
        total += bit[index];
        index -= index & index.wrapping_neg();
    }
    total
}

fn range_add(
    bit1: &mut [i64; MAX_N + 2],
    bit2: &mut [i64; MAX_N + 2],
    n: usize,
    left: usize,
    right: usize,
    delta: i64,
) {
    let lo = left + 1;
    let hi = right + 1;
    bit_add(bit1, lo, delta, n);
    bit_add(bit1, hi + 1, -delta, n);
    bit_add(bit2, lo, delta * (lo as i64 - 1), n);
    bit_add(bit2, hi + 1, -delta * hi as i64, n);
}

fn prefix_sum(bit1: &[i64; MAX_N + 2], bit2: &[i64; MAX_N + 2], count: usize) -> i64 {
    count as i64 * bit_sum(bit1, count) - bit_sum(bit2, count)
}

fn range_sum(
    bit1: &[i64; MAX_N + 2],
    bit2: &[i64; MAX_N + 2],
    left: usize,
    right: usize,
) -> i64 {
    prefix_sum(bit1, bit2, right + 1) - prefix_sum(bit1, bit2, left)
}

fn solve(values: &[i64]) -> i64 {
    if values.len() < 3 || values.len() > MAX_PARSEABLE_LENGTH {
        return -1;
    }
    if !(1..=MAX_N as i64).contains(&values[0])
        || !(0..=MAX_EVENTS as i64).contains(&values[1])
        || !(0..=MAX_QUERIES as i64).contains(&values[2])
    {
        return -1;
    }
    let n = values[0] as usize;
    let event_count = values[1] as usize;
    let query_count = values[2] as usize;
    if values.len() != 3 + 3 * event_count + 3 * query_count {
        return -1;
    }

    let mut events = [(0_usize, 0_usize, 0_i64); MAX_EVENTS];
    let mut queries = [(0_usize, 0_usize, 0_i64); MAX_QUERIES];
    let mut cursor = 3;
    for event in events.iter_mut().take(event_count) {
        let left = values[cursor];
        let right = values[cursor + 1];
        let delta = values[cursor + 2];
        cursor += 3;
        if left < 0 || left > right || right >= n as i64 || !(0..=1000).contains(&delta) {
            return -1;
        }
        *event = (left as usize, right as usize, delta);
    }
    for query in queries.iter_mut().take(query_count) {
        let left = values[cursor];
        let right = values[cursor + 1];
        let target = values[cursor + 2];
        cursor += 3;
        if left < 0 || left > right || right >= n as i64 || !(1..=512000).contains(&target) {
            return -1;
        }
        *query = (left as usize, right as usize, target);
    }

    let mut low = [0_i64; MAX_QUERIES];
    let mut high = [0_i64; MAX_QUERIES];
    let mut next_query = [-1_i64; MAX_QUERIES];
    for query in 0..query_count {
        high[query] = event_count as i64 + 1;
    }

    loop {
        let mut heads = [-1_i64; MAX_EVENTS + 1];
        next_query.fill(-1);
        let mut active = false;
        for query in 0..query_count {
            if high[query] - low[query] > 1 {
                active = true;
                let middle = ((low[query] + high[query]) / 2) as usize;
                next_query[query] = heads[middle];
                heads[middle] = query as i64;
            }
        }
        if !active {
            break;
        }

        let mut bit1 = [0_i64; MAX_N + 2];
        let mut bit2 = [0_i64; MAX_N + 2];
        let mut applied = 0;
        for middle in 0..=event_count {
            while applied < middle {
                let (left, right, delta) = events[applied];
                range_add(&mut bit1, &mut bit2, n, left, right, delta);
                applied += 1;
            }
            let mut query = heads[middle];
            while query >= 0 {
                let id = query as usize;
                let (left, right, target) = queries[id];
                if range_sum(&bit1, &bit2, left, right) >= target {
                    high[id] = middle as i64;
                } else {
                    low[id] = middle as i64;
                }
                query = next_query[id];
            }
        }
    }

    (0..query_count)
        .map(|query| (query as i64 + 1) * (high[query] + 1))
        .sum()
}

#[no_mangle]
pub unsafe extern "C" fn parallel_binary_search_range_threshold(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE_LENGTH {
        return -1;
    }
    solve(std::slice::from_raw_parts(input, length))
}
