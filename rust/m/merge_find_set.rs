const MAX_N: usize = 256;
const MAX_MERGES: usize = 512;
const MAX_VALID_INPUT_LENGTH: usize = 1027;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1028;

fn find_root(parent: &[usize; MAX_N], mut element: usize) -> usize {
    while parent[element] != element { element = parent[element]; }
    element
}

#[no_mangle]
pub unsafe extern "C" fn merge_find_set(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_N as i64 || values[1] < 0 || values[1] > MAX_MERGES as i64 { return -1; }
    let n = values[0] as usize;
    let merge_count = values[1] as usize;
    if length != 2 * merge_count + 3 || length > MAX_VALID_INPUT_LENGTH { return -1; }

    let mut parent = [0_usize; MAX_N];
    let mut rank = [0_u32; MAX_N];
    for element in 0..n { parent[element] = element; }
    for merge_index in 0..merge_count {
        let position = 2 + 2 * merge_index;
        let first = values[position];
        let second = values[position + 1];
        if first < 0 || first >= n as i64 || second < 0 || second >= n as i64 { return -1; }
        let first_root = find_root(&parent, first as usize);
        let second_root = find_root(&parent, second as usize);
        if first_root == second_root { continue; }
        if rank[first_root] < rank[second_root] {
            parent[first_root] = second_root;
        } else if rank[first_root] > rank[second_root] {
            parent[second_root] = first_root;
        } else {
            parent[first_root] = second_root;
            rank[second_root] += 1;
        }
    }
    let query = values[2 + 2 * merge_count];
    if query < 0 || query >= n as i64 { return -1; }
    find_root(&parent, query as usize) as i64
}
