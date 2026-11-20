/// Online rectangle counts using Fenwick trees over x-blocks and y-values.
fn inner_add(trees: &mut [i64; 150], n: usize, node: usize, y: i64, delta: i64) {
    let mut index = y as usize + 1;
    while index <= n {
        trees[node * 25 + index] += delta;
        index += index & index.wrapping_neg();
    }
}

fn inner_prefix(trees: &[i64; 150], node: usize, y_limit: i64) -> i64 {
    let mut total = 0;
    let mut index = y_limit as usize;
    while index > 0 {
        total += trees[node * 25 + index];
        index -= index & index.wrapping_neg();
    }
    total
}

fn prefix_count(ys: &[i64; 24], trees: &[i64; 150], block_size: usize,
                x_limit: usize, y_limit: i64) -> i64 {
    let full_blocks = x_limit / block_size;
    let mut node = full_blocks;
    let mut total = 0;
    while node > 0 {
        total += inner_prefix(trees, node, y_limit);
        node -= node & node.wrapping_neg();
    }
    for x in full_blocks * block_size..x_limit {
        if ys[x] < y_limit { total += 1; }
    }
    total
}

#[no_mangle]
pub extern "C" fn fenwick_tree_in_block_array_rectangle_count(
    input: *const i64, length: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 187 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (n_value, q_value) = (values[0], values[1]);
    if !(1..=24).contains(&n_value) || !(1..=32).contains(&q_value) { return -1; }
    let (n, q) = (n_value as usize, q_value as usize);
    let operations_at = 2 + n;
    if length != operations_at + 5 * q { return -1; }

    let mut ys = [0i64; 24];
    for x in 0..n {
        ys[x] = values[2 + x];
        if ys[x] < 0 || ys[x] >= n_value { return -1; }
    }
    for j in 0..q {
        let at = operations_at + 5 * j;
        match values[at] {
            0 => {
                if values[at + 1] < 0 || values[at + 1] >= n_value
                    || values[at + 2] < 0 || values[at + 2] >= n_value
                    || values[at + 3] != 0 || values[at + 4] != 0 { return -1; }
            }
            1 => {
                if values[at + 1] < 0 || values[at + 1] > values[at + 2]
                    || values[at + 2] > n_value
                    || values[at + 3] < 0 || values[at + 3] > values[at + 4]
                    || values[at + 4] > n_value { return -1; }
            }
            _ => return -1,
        }
    }

    let mut block_size = 1usize;
    while block_size * block_size < n { block_size += 1; }
    let block_count = (n + block_size - 1) / block_size;
    let mut trees = [0i64; 150];
    for x in 0..n {
        let mut node = x / block_size + 1;
        while node <= block_count {
            inner_add(&mut trees, n, node, ys[x], 1);
            node += node & node.wrapping_neg();
        }
    }

    let (mut checksum, mut query_ordinal) = (0i64, 0i64);
    for j in 0..q {
        let at = operations_at + 5 * j;
        if values[at] == 0 {
            let x = values[at + 1] as usize;
            let new_y = values[at + 2];
            let mut node = x / block_size + 1;
            while node <= block_count {
                inner_add(&mut trees, n, node, ys[x], -1);
                inner_add(&mut trees, n, node, new_y, 1);
                node += node & node.wrapping_neg();
            }
            ys[x] = new_y;
        } else {
            let x_left = values[at + 1] as usize;
            let x_right = values[at + 2] as usize;
            let (y_low, y_high) = (values[at + 3], values[at + 4]);
            let count = prefix_count(&ys, &trees, block_size, x_right, y_high)
                - prefix_count(&ys, &trees, block_size, x_left, y_high)
                - prefix_count(&ys, &trees, block_size, x_right, y_low)
                + prefix_count(&ys, &trees, block_size, x_left, y_low);
            query_ordinal += 1;
            checksum += query_ordinal * count;
        }
    }
    checksum
}
