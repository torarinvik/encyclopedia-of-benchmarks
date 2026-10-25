/// Root separator routes point lookup into one of two sorted B+ tree leaves.
#[no_mangle]
pub extern "C" fn rodinia_bplus_tree(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 7 || length > 31 { return -1; }
    let v = unsafe { std::slice::from_raw_parts(input, length) };
    if v[0] < 1 || v[0] > 3 || v[1] < 1 || v[1] > 3 || v[2] < 1 || v[2] > 16 { return -1; }
    let left_n = v[0] as usize; let right_n = v[1] as usize; let query_n = v[2] as usize;
    if length != 3 + 2 * (left_n + right_n) + query_n { return -1; }
    let mut keys = [[0i64; 3]; 2];
    let mut vals = [[0i64; 3]; 2];
    let counts = [left_n, right_n];
    let mut cursor = 3;
    for leaf in 0..2 {
        for slot in 0..counts[leaf] {
            let key = v[cursor]; let value = v[cursor + 1]; cursor += 2;
            if !(-1_000_000..=1_000_000).contains(&key) || !(0..=1_000_000).contains(&value) ||
                (slot > 0 && key <= keys[leaf][slot - 1]) { return -1; }
            keys[leaf][slot] = key; vals[leaf][slot] = value;
        }
    }
    if keys[0][left_n - 1] >= keys[1][0] { return -1; }
    let mut answer = 0i64;
    for qi in 0..query_n {
        let query = v[cursor]; cursor += 1;
        if !(-1_000_000..=1_000_000).contains(&query) { return -1; }
        let leaf = if query < keys[1][0] { 0 } else { 1 };
        for slot in 0..counts[leaf] {
            if keys[leaf][slot] == query {
                answer += (qi as i64 + 1) * (vals[leaf][slot] + 1);
                break;
            }
        }
    }
    answer
}
