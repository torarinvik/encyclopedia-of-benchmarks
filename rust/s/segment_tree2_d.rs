const MAX_ROWS: usize = 16;
const MAX_COLUMNS: usize = 16;
const MAX_OPERATIONS: usize = 256;
const MAX_TREE_SIDE: usize = 64;
const MAX_VALID_INPUT_LENGTH: usize = 1_283;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1_284;
const CHECKSUM_OFFSET: i64 = 256_001;

fn set_column(tree: &mut [[i64; MAX_TREE_SIDE]; MAX_TREE_SIDE], row_node: usize,
              column_base: usize, column: usize, value: i64) {
    let mut node = column_base + column;
    tree[row_node][node] = value;
    node >>= 1;
    while node > 0 {
        tree[row_node][node] = tree[row_node][node << 1] + tree[row_node][(node << 1) | 1];
        node >>= 1;
    }
}

fn query_columns(tree: &[[i64; MAX_TREE_SIDE]; MAX_TREE_SIDE], row_node: usize,
                 column_base: usize, left: usize, right: usize) -> i64 {
    let mut first = left + column_base;
    let mut last = right + column_base;
    let mut sum = 0_i64;
    while first < last {
        if first & 1 != 0 { sum += tree[row_node][first]; first += 1; }
        if last & 1 != 0 { last -= 1; sum += tree[row_node][last]; }
        first >>= 1;
        last >>= 1;
    }
    sum
}

fn assign_point(tree: &mut [[i64; MAX_TREE_SIDE]; MAX_TREE_SIDE],
                 row_base: usize, column_base: usize, row: usize, column: usize, value: i64) {
    let row_leaf = row_base + row;
    set_column(tree, row_leaf, column_base, column, value);
    let mut row_node = row_leaf >> 1;
    while row_node > 0 {
        let left_value = tree[row_node << 1][column_base + column];
        let right_value = tree[(row_node << 1) | 1][column_base + column];
        set_column(tree, row_node, column_base, column, left_value + right_value);
        row_node >>= 1;
    }
}

fn query_rectangle(tree: &[[i64; MAX_TREE_SIDE]; MAX_TREE_SIDE], row_base: usize,
                   column_base: usize, top: usize, bottom: usize,
                   left: usize, right: usize) -> i64 {
    let mut first = top + row_base;
    let mut last = bottom + row_base;
    let mut sum = 0_i64;
    while first < last {
        if first & 1 != 0 { sum += query_columns(tree, first, column_base, left, right); first += 1; }
        if last & 1 != 0 { last -= 1; sum += query_columns(tree, last, column_base, left, right); }
        first >>= 1;
        last >>= 1;
    }
    sum
}

#[no_mangle]
pub unsafe extern "C" fn segment_tree2_d_benchmark(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_ROWS as i64 || values[1] < 1 || values[1] > MAX_COLUMNS as i64 { return -1; }
    if values[2] < 0 || values[2] > MAX_OPERATIONS as i64 { return -1; }
    let rows = values[0] as usize;
    let columns = values[1] as usize;
    let operation_count = values[2] as usize;
    if length != 3 + 5 * operation_count || length > MAX_VALID_INPUT_LENGTH { return -1; }

    let mut row_base = 1;
    while row_base < rows { row_base <<= 1; }
    let mut column_base = 1;
    while column_base < columns { column_base <<= 1; }
    let mut tree = [[0_i64; MAX_TREE_SIDE]; MAX_TREE_SIDE];
    let mut checksum = 0_i64;
    for operation in 0..operation_count {
        let offset = 3 + 5 * operation;
        let opcode = values[offset];
        let first = values[offset + 1];
        let second = values[offset + 2];
        let third = values[offset + 3];
        let fourth = values[offset + 4];
        if opcode == 0 {
            if first < 0 || first >= rows as i64 || second < 0 || second >= columns as i64 || third < -1_000 || third > 1_000 || fourth != 0 { return -1; }
            assign_point(&mut tree, row_base, column_base, first as usize, second as usize, third);
        } else if opcode == 1 {
            if first < 0 || first > second || second > rows as i64 || third < 0 || third > fourth || fourth > columns as i64 { return -1; }
            let result = query_rectangle(&tree, row_base, column_base, first as usize, second as usize, third as usize, fourth as usize);
            checksum += (operation as i64 + 1) * (result + CHECKSUM_OFFSET);
        } else { return -1; }
    }
    checksum
}
