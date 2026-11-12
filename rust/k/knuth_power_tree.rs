const MAX_TARGET: usize = 127;

fn build_path(target: usize, parent: &mut [usize; MAX_TARGET + 1],
              seen: &mut [bool; MAX_TARGET + 1], queue: &mut [usize; MAX_TARGET + 1],
              reverse: &mut [usize; MAX_TARGET + 1], path: &mut [usize; MAX_TARGET]) -> usize {
    if target == 1 { path[0] = 1; return 1; }
    let mut head = 0usize;
    let mut tail = 1usize;
    queue[0] = 1;
    seen[1] = true;
    while head < tail {
        let current = queue[head];
        head += 1;
        let mut chain_length = 0usize;
        let mut node = current;
        while node != 0 {
            reverse[chain_length] = node;
            chain_length += 1;
            node = parent[node];
        }
        for offset in 0..chain_length {
            let ancestor = reverse[chain_length - offset - 1];
            let child = current + ancestor;
            if child > target || seen[child] { continue; }
            seen[child] = true;
            parent[child] = current;
            if child == target {
                let mut count = 0usize;
                let mut node = target;
                while node != 0 {
                    path[count] = node;
                    count += 1;
                    node = parent[node];
                }
                path[..count].reverse();
                return count;
            }
            queue[tail] = child;
            tail += 1;
        }
    }
    0
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (byte * 8)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn knuth_power_tree(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let target_value = *input;
    if !(1..=MAX_TARGET as i64).contains(&target_value) { return -1; }
    let target = target_value as usize;
    let mut parent = [0usize; MAX_TARGET + 1];
    let mut seen = [false; MAX_TARGET + 1];
    let mut queue = [0usize; MAX_TARGET + 1];
    let mut reverse = [0usize; MAX_TARGET + 1];
    let mut path = [0usize; MAX_TARGET];
    let path_length = build_path(target, &mut parent, &mut seen, &mut queue, &mut reverse, &mut path);
    if path_length == 0 { return -1; }
    let required = 8 * (path_length + 1);
    if output.is_null() || output_capacity < required { return -2; }
    store_i64_le(output, 0, (path_length - 1) as i64);
    for index in 0..path_length { store_i64_le(output, 8 * (index + 1), path[index] as i64); }
    required as i64
}
