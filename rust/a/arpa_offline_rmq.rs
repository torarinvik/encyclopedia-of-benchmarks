const MAX_N: i64 = 64;
const MAX_Q: i64 = 64;
const MAX_INPUT_LENGTH: usize = 195;

fn find_root(parent: &mut [i64; 64], node: usize) -> usize {
    let mut root = node;
    while parent[root] as usize != root { root = parent[root] as usize; }
    let mut current = node;
    while parent[current] as usize != current {
        let next = parent[current] as usize;
        parent[current] = root as i64;
        current = next;
    }
    root
}

#[no_mangle]
pub unsafe extern "C" fn arpa_offline_rmq(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n_value, q_value) = (values[0], values[1]);
    if n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q { return -1; }
    let (n, q) = (n_value as usize, q_value as usize);
    if length != 2 + n + 2 * q { return -1; }
    if values[2..2 + n].iter().any(|&value| !(-1000..=1000).contains(&value)) { return -1; }
    let query_start = 2 + n;
    for j in 0..q {
        let (left, right) = (values[query_start + 2 * j], values[query_start + 2 * j + 1]);
        if left < 0 || left > right || right >= n_value { return -1; }
    }
    let mut parent = [0i64; 64];
    let mut stack = [0i64; 64];
    let mut head = [-1i64; 64];
    let mut query_next = [0i64; 64];
    for i in 0..n { parent[i] = i as i64; }
    for j in 0..q {
        let bucket = values[query_start + 2 * j + 1] as usize;
        query_next[j] = head[bucket];
        head[bucket] = j as i64;
    }
    let mut checksum = 0i64;
    let mut stack_size = 0usize;
    for right in 0..n {
        while stack_size > 0 && values[2 + stack[stack_size - 1] as usize] > values[2 + right] {
            stack_size -= 1;
            parent[stack[stack_size] as usize] = right as i64;
        }
        stack[stack_size] = right as i64;
        stack_size += 1;
        let mut query = head[right];
        while query >= 0 {
            let ordinal = query as usize;
            let index = find_root(&mut parent, values[query_start + 2 * ordinal] as usize);
            checksum += (ordinal as i64 + 1) * (index as i64 + 1);
            query = query_next[ordinal];
        }
    }
    checksum
}
