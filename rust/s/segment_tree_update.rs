const MAX_N: usize = 64;
const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 259;
const MAX_TREE_LENGTH: usize = 128;
const VALUE_MIN: i64 = -1_000_000;
const VALUE_MAX: i64 = 1_000_000;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

fn query_sum(tree: &[i32; MAX_TREE_LENGTH], node: usize,
             segment_left: usize, segment_right: usize,
             query_left: usize, query_right: usize) -> i32 {
    if query_left <= segment_left && segment_right <= query_right { return tree[node]; }
    if query_right < segment_left || segment_right < query_left { return 0; }
    let middle = segment_left + (segment_right - segment_left) / 2;
    query_sum(tree, node * 2, segment_left, middle, query_left, query_right)
        + query_sum(tree, node * 2 + 1, middle + 1, segment_right, query_left, query_right)
}

fn hash_i64_word(mut hash: u64, word: i64) -> u64 {
    for byte in word.to_le_bytes() {
        hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME);
    }
    hash
}

#[no_mangle]
pub unsafe extern "C" fn segment_tree_update_benchmark(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    if input[0] < 1 || input[0] > MAX_N as i64 { return -1; }
    let n = input[0] as usize;
    if length < n + 2 { return -1; }
    if input[n + 1] < 1 || input[n + 1] > MAX_OPERATIONS as i64 { return -1; }
    let operation_count = input[n + 1] as usize;
    if length != n + 2 + 3 * operation_count { return -1; }

    for &value in &input[1..1 + n] {
        if !(VALUE_MIN..=VALUE_MAX).contains(&value) { return -1; }
    }
    let operations_start = n + 2;
    let mut query_count = 0usize;
    for operation in 0..operation_count {
        let offset = operations_start + 3 * operation;
        let (kind, first, second) = (input[offset], input[offset + 1], input[offset + 2]);
        if kind == 0 {
            if first < 0 || first > second || second >= n as i64 { return -1; }
            query_count += 1;
        } else if kind == 1 {
            if first < 0 || first >= n as i64 || !(VALUE_MIN..=VALUE_MAX).contains(&second) { return -1; }
        } else {
            return -1;
        }
    }
    if query_count == 0 { return -1; }

    let mut power = 1usize;
    while power < n { power *= 2; }
    let mut tree = [0i32; MAX_TREE_LENGTH];
    for index in 0..n { tree[power + index] = input[index + 1] as i32; }
    for node in (1..power).rev() { tree[node] = tree[node * 2] + tree[node * 2 + 1]; }

    let mut hash = hash_i64_word(FNV_OFFSET, query_count as i64);
    for operation in 0..operation_count {
        let offset = operations_start + 3 * operation;
        let (kind, first, second) = (input[offset], input[offset + 1], input[offset + 2]);
        if kind == 0 {
            let sum = query_sum(&tree, 1, 1, power, first as usize + 1, second as usize + 1);
            hash = hash_i64_word(hash, i64::from(sum));
        } else {
            let mut node = power + first as usize;
            tree[node] = second as i32;
            while node > 1 {
                node /= 2;
                tree[node] = tree[node * 2] + tree[node * 2 + 1];
            }
        }
    }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}
