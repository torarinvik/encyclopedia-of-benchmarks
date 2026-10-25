/// Clean-room bounded MUMmerGPU maximal exact-match query; see package LICENSE.txt.
const MAX_REF: usize = 32;
const MAX_QUERY: usize = 32;
const ALPHABET: usize = 5;
const MAX_NODES: usize = 1 + MAX_REF * (MAX_REF + 3) / 2;
const MAX_MATCHES: usize = MAX_REF * MAX_QUERY;

fn suffix_less(reference: &[i64], length: usize, left: usize, right: usize) -> bool {
    let (mut a, mut b) = (left, right);
    while a < length && b < length && reference[a] == reference[b] { a += 1; b += 1; }
    if a == length && b == length { return false; }
    if a == length { return false; }
    if b == length { return true; }
    reference[a] < reference[b]
}

fn put_i64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); } }
}

#[no_mangle]
pub unsafe extern "C" fn rodinia_mummergpu(input: *const i64, length: usize,
                                              output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > 3 + MAX_REF + MAX_QUERY { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_REF as i64 || values[1] < 1 || values[1] > MAX_QUERY as i64 || values[2] < 1 || values[2] > MAX_QUERY as i64 { return -1; }
    let ref_len = values[0] as usize; let query_len = values[1] as usize; let min_len = values[2] as usize;
    if length != 3 + ref_len + query_len { return -1; }
    let mut reference = [0i64; MAX_REF]; let mut query = [0i64; MAX_QUERY];
    for i in 0..ref_len { let code = values[3 + i]; if !(0..=3).contains(&code) { return -1; } reference[i] = code; }
    for i in 0..query_len { let code = values[3 + ref_len + i]; if !(0..=3).contains(&code) { return -1; } query[i] = code; }

    let mut children = [-1i32; MAX_NODES * ALPHABET];
    let mut path_node = [-1i32; MAX_REF * (MAX_REF + 1)];
    let mut suffix_order = [0usize; MAX_REF];
    let mut node_count = 1usize;
    for start in 0..ref_len {
        let mut node = 0usize; let mut depth = 0usize;
        path_node[start * (MAX_REF + 1)] = 0;
        for pos in start..ref_len {
            let slot = node * ALPHABET + reference[pos] as usize;
            if children[slot] < 0 {
                let fresh = node_count; node_count += 1; children[slot] = fresh as i32;
                for symbol in 0..ALPHABET { children[fresh * ALPHABET + symbol] = -1; }
            }
            node = children[slot] as usize; depth += 1;
            path_node[start * (MAX_REF + 1) + depth] = node as i32;
        }
        let terminal = node * ALPHABET + 4;
        if children[terminal] < 0 {
            let fresh = node_count; node_count += 1; children[terminal] = fresh as i32;
            for symbol in 0..ALPHABET { children[fresh * ALPHABET + symbol] = -1; }
        }
    }
    for i in 0..ref_len { suffix_order[i] = i; }
    for i in 1..ref_len {
        let key = suffix_order[i]; let mut j = i;
        while j > 0 && suffix_less(&reference, ref_len, key, suffix_order[j - 1]) { suffix_order[j] = suffix_order[j - 1]; j -= 1; }
        suffix_order[j] = key;
    }

    let mut records = [0i64; MAX_MATCHES * 3]; let mut match_count = 0usize;
    for qstart in 0..query_len {
        let mut candidate = [-1i32; MAX_REF];
        let mut node = 0usize; let mut depth = 0usize;
        loop {
            let query_has_next = qstart + depth < query_len;
            for rstart in 0..ref_len {
                if path_node[rstart * (MAX_REF + 1) + depth] != node as i32 { continue; }
                let suffix_ends = rstart + depth == ref_len;
                if suffix_ends || !query_has_next || reference[rstart + depth] != query[qstart + depth] { candidate[rstart] = depth as i32; }
            }
            if !query_has_next { break; }
            let slot = node * ALPHABET + query[qstart + depth] as usize;
            if children[slot] < 0 { break; }
            node = children[slot] as usize; depth += 1;
        }
        for order in 0..ref_len {
            let rstart = suffix_order[order]; let match_len = candidate[rstart];
            if match_len < min_len as i32 { continue; }
            if qstart > 0 && rstart > 0 && query[qstart - 1] == reference[rstart - 1] { continue; }
            records[3 * match_count] = (rstart + 1) as i64;
            records[3 * match_count + 1] = (qstart + 1) as i64;
            records[3 * match_count + 2] = match_len as i64;
            match_count += 1;
        }
    }
    let output_bytes = match_count * 24;
    if output.is_null() || capacity < output_bytes { return -2; }
    for i in 0..3 * match_count { put_i64(output, i * 8, records[i]); }
    output_bytes as i64
}
