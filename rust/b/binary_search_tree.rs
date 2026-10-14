/// Bounded unbalanced binary search tree with an index-based node pool.
#[no_mangle]
pub unsafe extern "C" fn binary_search_tree_benchmark(values: *const i64, length: usize) -> i64 {
    if length > 1024 || length % 2 != 0 { return -1; }
    let operation_count = length / 2;
    let mut key = [0_i64; 256];
    let mut left = [256_usize; 256];
    let mut right = [256_usize; 256];
    let mut free_next = [256_usize; 256];
    for i in 0..256 { free_next[i] = i + 1; }
    let mut free_head = 0; let mut root = 256; let mut count = 0; let mut checksum = 0_i64;
    for operation in 0..operation_count {
        let opcode = *values.add(2 * operation);
        let payload = *values.add(2 * operation + 1);
        let mut observed = 0_i64;
        if opcode == 0 {
            if !(-1_000_000..=1_000_000).contains(&payload) { return -1; }
            let mut parent = 256; let mut node = root;
            while node != 256 && key[node] != payload { parent = node; node = if payload < key[node] { left[node] } else { right[node] }; }
            if node == 256 {
                if count == 256 || free_head == 256 { return -1; }
                node = free_head; free_head = free_next[node]; key[node] = payload; left[node] = 256; right[node] = 256;
                if parent == 256 { root = node; } else if payload < key[parent] { left[parent] = node; } else { right[parent] = node; }
                count += 1; observed = 1;
            }
        } else if opcode == 1 {
            if !(-1_000_000..=1_000_000).contains(&payload) { return -1; }
            let mut parent = 256; let mut node = root;
            while node != 256 && key[node] != payload { parent = node; node = if payload < key[node] { left[node] } else { right[node] }; }
            observed = i64::from(node != 256);
            if node != 256 {
                if left[node] != 256 && right[node] != 256 {
                    let mut pred_parent = node; let mut pred = left[node];
                    while right[pred] != 256 { pred_parent = pred; pred = right[pred]; }
                    key[node] = key[pred]; parent = pred_parent; node = pred;
                }
                let child = if left[node] != 256 { left[node] } else { right[node] };
                if parent == 256 { root = child; } else if left[parent] == node { left[parent] = child; } else { right[parent] = child; }
                free_next[node] = free_head; free_head = node; count -= 1;
            }
        } else if opcode == 2 {
            if !(-1_000_000..=1_000_000).contains(&payload) { return -1; }
            let mut node = root;
            while node != 256 && key[node] != payload { node = if payload < key[node] { left[node] } else { right[node] }; }
            observed = i64::from(node != 256);
        } else if opcode == 3 || opcode == 4 {
            if payload != 0 || root == 256 { return -1; }
            let mut node = root;
            if opcode == 3 { while left[node] != 256 { node = left[node]; } }
            else { while right[node] != 256 { node = right[node]; } }
            observed = key[node];
        } else if opcode == 5 {
            if payload != 0 { return -1; }
            observed = count as i64;
        } else { return -1; }
        checksum += (operation as i64 + 1) * (observed + 1_000_000);
    }
    let mut stack = [0_usize; 256]; let mut top = 0; let mut node = root; let mut index = 0;
    while node != 256 || top != 0 {
        while node != 256 { stack[top] = node; top += 1; node = left[node]; }
        top -= 1; node = stack[top];
        checksum += (operation_count as i64 + index as i64 + 1) * (key[node] + 1_000_000);
        index += 1; node = right[node];
    }
    checksum
}
