const MAX_N: usize = 6;
const MAX_ASSIGNMENTS: usize = 3;
const MAX_INPUT: usize = 27;
const MAX_WORDS: usize = 73;

#[no_mangle]
pub unsafe extern "C" fn all_distances_sketch_k_mins(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n0, assignments0) = (values[0], values[1]);
    if !(1..=MAX_N as i64).contains(&n0)
        || !(1..=MAX_ASSIGNMENTS as i64).contains(&assignments0) { return -1; }
    let n = n0 as usize;
    let assignments = assignments0 as usize;
    if length != 2 + n + assignments * n { return -1; }

    let mut distances = [0i64; MAX_N];
    for item in 0..n {
        let distance = values[2 + item];
        if !(0..=1_000_000).contains(&distance)
            || (item > 0 && distances[item - 1] >= distance) { return -1; }
        distances[item] = distance;
    }
    let mut ranks = [[0i64; MAX_N]; MAX_ASSIGNMENTS];
    for assignment in 0..assignments {
        let mut seen = [false; MAX_N];
        for item in 0..n {
            let rank = values[2 + n + assignment * n + item];
            if rank < 0 || rank >= n0 || seen[rank as usize] { return -1; }
            seen[rank as usize] = true;
            ranks[assignment][item] = rank;
        }
    }

    let mut staged = [0i64; MAX_WORDS];
    let mut count = 0usize;
    for assignment in 0..assignments {
        let mut best_rank = n0;
        for item in 0..n {
            let rank = ranks[assignment][item];
            if rank < best_rank {
                staged[1 + 4 * count] = assignment as i64;
                staged[2 + 4 * count] = item as i64;
                staged[3 + 4 * count] = rank;
                staged[4 + 4 * count] = distances[item];
                count += 1;
                best_rank = rank;
            }
        }
    }
    staged[0] = count as i64;
    let words = 1 + 4 * count;
    let bytes = 8 * words;
    if output.is_null() || capacity < bytes { return -2; }
    let output_bytes = std::slice::from_raw_parts_mut(output, bytes);
    for word in 0..words {
        output_bytes[word * 8..word * 8 + 8].copy_from_slice(&staged[word].to_le_bytes());
    }
    bytes as i64
}
