const MAX_N: usize = 12;
const MAX_LENGTH: usize = 14;
const MAX_STATES: usize = 1 << MAX_N;

#[no_mangle]
pub unsafe extern "C" fn linear_extension_count(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_LENGTH).contains(&length) { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    if words[0] < 0 || words[0] > MAX_N as i64 { return -1; }
    let n = words[0] as usize;
    if length != n + 1 { return -1; }
    let full = (1_usize << n) - 1;
    let mut predecessor = [0_usize; MAX_N];
    for vertex in 0..n {
        if words[1 + vertex] < 0 || words[1 + vertex] > full as i64 { return -1; }
        predecessor[vertex] = words[1 + vertex] as usize;
    }

    let mut ways = [0_i64; MAX_STATES];
    ways[0] = 1;
    for prefix in 0..=full {
        let count = ways[prefix];
        if count == 0 { continue; }
        for vertex in 0..n {
            let bit = 1_usize << vertex;
            if prefix & bit == 0 && predecessor[vertex] & prefix == predecessor[vertex] {
                ways[prefix | bit] += count;
            }
        }
    }
    ways[full]
}
