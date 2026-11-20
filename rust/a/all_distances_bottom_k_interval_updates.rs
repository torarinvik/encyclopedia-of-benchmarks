const MAX_N: usize = 32;
const MAX_K: usize = 4;
const MAX_INPUT: usize = 99;
const MAX_WORDS: usize = 97;
const DISTANCE_LIMIT: i64 = 1_000_000;
const END_SENTINEL: i64 = 1_000_001;

#[derive(Clone, Copy, Default)]
struct Interval { item_id: i64, rank: i64, first: i64, past: i64 }

fn put_i64(output: &mut [u8], word: usize, value: i64) {
    output[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn all_distances_bottom_k_interval_updates(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n0, k0) = (values[0], values[1]);
    if n0 < 2 || n0 > MAX_N as i64 || k0 < 2 || k0 > MAX_K as i64 || k0 > n0 { return -1; }
    let n = n0 as usize;
    let k = k0 as usize;
    if length != 2 + 3 * n { return -1; }

    let mut records = [Interval::default(); MAX_N];
    let mut seen_id = [false; MAX_N];
    let mut seen_rank = [false; MAX_N];
    for i in 0..n {
        let id = values[2 + 3 * i];
        let distance = values[3 + 3 * i];
        let rank = values[4 + 3 * i];
        if id < 0 || id >= n0 || seen_id[id as usize] || rank < 0 || rank >= n0
            || seen_rank[rank as usize] || !(0..=DISTANCE_LIMIT).contains(&distance) { return -1; }
        seen_id[id as usize] = true;
        seen_rank[rank as usize] = true;
        for j in 0..i { if records[j].first == distance { return -1; } }
        records[i] = Interval { item_id: id, rank, first: distance, past: 0 };
    }
    for i in 1..k { if records[i - 1].first >= records[i].first { return -1; } }
    for i in k..n { if records[i].first <= records[k - 1].first { return -1; } }

    let mut intervals = [Interval::default(); MAX_N];
    let mut count = k;
    for i in 0..k {
        intervals[i] = Interval { item_id: records[i].item_id, rank: records[i].rank,
                                  first: records[i].first, past: END_SENTINEL };
    }
    for i in k..n {
        let mut worst = MAX_N;
        let mut active = 0usize;
        for j in 0..count {
            if intervals[j].first <= records[i].first && records[i].first < intervals[j].past {
                active += 1;
                if worst == MAX_N || intervals[j].rank > intervals[worst].rank { worst = j; }
            }
        }
        if active != k || worst == MAX_N { return -1; }
        if records[i].rank >= intervals[worst].rank { continue; }
        let mut cursor = intervals[worst].past;
        intervals[worst].past = records[i].first;
        while cursor < END_SENTINEL {
            let mut next_worst = MAX_N;
            for j in 0..count {
                if intervals[j].first <= cursor && cursor < intervals[j].past
                    && (next_worst == MAX_N || intervals[j].rank > intervals[next_worst].rank) {
                    next_worst = j;
                }
            }
            if next_worst == MAX_N || intervals[next_worst].rank <= records[i].rank { break; }
            let next_cursor = intervals[next_worst].past;
            intervals[next_worst].past = cursor;
            cursor = next_cursor;
        }
        intervals[count] = Interval { item_id: records[i].item_id, rank: records[i].rank,
                                      first: records[i].first, past: cursor };
        count += 1;
    }

    let mut order = [0usize; MAX_N];
    let mut out_count = 0usize;
    for i in 0..count {
        if intervals[i].first < intervals[i].past { order[out_count] = i; out_count += 1; }
    }
    for i in 1..out_count {
        let key = order[i];
        let mut j = i;
        while j > 0 && (intervals[order[j - 1]].first > intervals[key].first
            || (intervals[order[j - 1]].first == intervals[key].first
                && intervals[order[j - 1]].item_id > intervals[key].item_id)) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = key;
    }
    let mut staged = [0i64; MAX_WORDS];
    staged[0] = out_count as i64;
    for i in 0..out_count {
        let entry = intervals[order[i]];
        staged[1 + 3 * i] = entry.item_id;
        staged[2 + 3 * i] = entry.first;
        staged[3 + 3 * i] = entry.past;
    }
    let words = 1 + 3 * out_count;
    let bytes = 8 * words;
    if output.is_null() || capacity < bytes { return -2; }
    let output_bytes = std::slice::from_raw_parts_mut(output, bytes);
    for word in 0..words { put_i64(output_bytes, word, staged[word]); }
    bytes as i64
}
