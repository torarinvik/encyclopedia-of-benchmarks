const MAX_N: usize = 8;
const MAX_ROUNDS: usize = 32;
const MAX_INPUT: usize = 275;
const MAX_OUTPUT: usize = 64;

unsafe fn put64(output: *mut u8, position: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(position + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn list_ranking_random_mate(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let head64 = *input.add(1);
    if n64 < 1 || n64 > MAX_N as i64 || head64 < 0 || head64 >= n64 { return -1; }
    let n = n64 as usize;
    let head = head64 as usize;
    if length < 3 + 2*n { return -1; }
    let rounds64 = *input.add(2 + 2*n);
    if rounds64 < 0 || rounds64 > MAX_ROUNDS as i64 ||
        length != 3 + 2*n + rounds64 as usize*n { return -1; }
    let rounds = rounds64 as usize;
    let mut weight = [0i64; MAX_N];
    let mut successor = [0i64; MAX_N];
    let mut indegree = [0usize; MAX_N];
    let mut tails = 0;
    for index in 0..n {
        weight[index] = *input.add(2 + index);
        successor[index] = *input.add(2 + n + index);
        if weight[index] < 1 || weight[index] > 10000 || successor[index] < -1 || successor[index] >= n64 {
            return -1;
        }
        if successor[index] == -1 { tails += 1; }
        else {
            let target = successor[index] as usize;
            indegree[target] += 1;
            if indegree[target] > 1 { return -1; }
        }
    }
    if tails != 1 || indegree[head] != 0 { return -1; }
    let coin_start = 3 + 2*n;
    for index in 0..rounds*n {
        let coin = *input.add(coin_start + index);
        if coin < 0 || coin > 1 { return -1; }
    }

    let mut seen = [false; MAX_N];
    let mut path_length = 0;
    let mut node = head64;
    while node != -1 {
        let index = node as usize;
        if seen[index] || path_length == n { return -1; }
        seen[index] = true;
        path_length += 1;
        node = successor[index];
    }
    if path_length != n { return -1; }

    let mut active = [true; MAX_N];
    let mut removal_round = [-1i32; MAX_N];
    for round in 0..rounds {
        if successor[head] == -1 { break; }
        let old_successor = successor;
        let old_weight = weight;
        let mut remove = [false; MAX_N];
        let coin_offset = coin_start + round*n;
        for index in 0..n {
            let target = old_successor[index];
            if active[index] && target != -1 && *input.add(coin_offset + index) == 0 &&
                *input.add(coin_offset + target as usize) == 1 {
                remove[target as usize] = true;
                removal_round[target as usize] = round as i32;
            }
        }
        for index in 0..n {
            let target = old_successor[index];
            if active[index] && target != -1 && remove[target as usize] {
                weight[index] = old_weight[index] + old_weight[target as usize];
                successor[index] = old_successor[target as usize];
            }
        }
        for index in 0..n { if remove[index] { active[index] = false; } }
    }
    if successor[head] != -1 { return -1; }

    let mut rank = weight;
    for round in (0..rounds).rev() {
        for index in 0..n {
            if removal_round[index] == round as i32 && successor[index] != -1 {
                rank[index] += rank[successor[index] as usize];
            }
        }
    }
    let output_bytes = 8*n;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    for index in 0..n { put64(staged.as_mut_ptr(), 8*index, rank[index]); }
    for index in 0..output_bytes { *output.add(index) = staged[index]; }
    output_bytes as i64
}
