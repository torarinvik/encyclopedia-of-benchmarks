const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_LENGTH: usize = 58;

#[no_mangle]
pub unsafe extern "C" fn dag_transitive_reduction(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_LENGTH + 1 { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    if words[0] < 1 || words[0] > MAX_N as i64 || words[1] < 0 || words[1] > MAX_M as i64 {
        return -1;
    }
    let n = words[0] as usize;
    let m = words[1] as usize;
    if length != 2 + 2 * m { return -1; }

    let mut outgoing = [0_usize; MAX_N];
    for edge in 0..m {
        let tail_value = words[2 + 2 * edge];
        let head_value = words[3 + 2 * edge];
        if tail_value < 0 || head_value < 0 || tail_value >= n as i64 ||
            head_value >= n as i64 || tail_value == head_value { return -1; }
        let tail = tail_value as usize;
        let head = head_value as usize;
        let bit = 1_usize << head;
        if outgoing[tail] & bit != 0 { return -1; }
        outgoing[tail] |= bit;
    }

    let mut reach = outgoing;
    for middle in 0..n {
        let middle_bit = 1_usize << middle;
        for source in 0..n {
            if reach[source] & middle_bit != 0 { reach[source] |= reach[middle]; }
        }
    }
    for vertex in 0..n {
        if reach[vertex] & (1_usize << vertex) != 0 { return -1; }
    }

    let mut retained = 0_i64;
    for edge in 0..m {
        let tail = words[2 + 2 * edge] as usize;
        let head = words[3 + 2 * edge] as usize;
        let mut redundant = false;
        for middle in 0..n {
            if middle != tail && middle != head &&
                outgoing[tail] & (1_usize << middle) != 0 &&
                reach[middle] & (1_usize << head) != 0 {
                redundant = true;
            }
        }
        if !redundant { retained += 1; }
    }
    retained
}
