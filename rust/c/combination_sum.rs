const MAX_CANDIDATES: usize = 8;
const MAX_TARGET: i64 = 20;
const MAX_PACKED_WORDS: usize = 4096;

struct Search<'a> {
    candidates: &'a [i64],
    path: [i64; MAX_TARGET as usize],
    packed: [i64; MAX_PACKED_WORDS],
    used: usize,
}

fn enumerate(search: &mut Search<'_>, start: usize, remaining: i64, depth: usize) {
    if remaining == 0 {
        search.packed[search.used] = depth as i64;
        search.used += 1;
        for i in 0..depth {
            search.packed[search.used] = search.path[i];
            search.used += 1;
        }
        search.packed[0] += 1;
        return;
    }
    for i in start..search.candidates.len() {
        let candidate = search.candidates[i];
        if candidate > remaining { break; }
        search.path[depth] = candidate;
        enumerate(search, i, remaining - candidate, depth + 1);
    }
}

#[no_mangle]
pub unsafe extern "C" fn combination_sum(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    let target = values[1];
    if !(1..=MAX_CANDIDATES as i64).contains(&count_value) || !(0..=MAX_TARGET).contains(&target) {
        return -1;
    }
    let count = count_value as usize;
    if length != count + 2 { return -1; }
    let candidates = &values[2..];
    for i in 0..count {
        if !(1..=24).contains(&candidates[i]) || (i > 0 && candidates[i - 1] >= candidates[i]) {
            return -1;
        }
    }

    let mut search = Search { candidates, path: [0; MAX_TARGET as usize],
                              packed: [0; MAX_PACKED_WORDS], used: 1 };
    enumerate(&mut search, 0, target, 0);
    let required = search.used * 8;
    if output.is_null() || capacity < required { return -2; }
    for (index, value) in search.packed[..search.used].iter().enumerate() {
        let bytes = value.to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(index * 8), 8);
    }
    required as i64
}
