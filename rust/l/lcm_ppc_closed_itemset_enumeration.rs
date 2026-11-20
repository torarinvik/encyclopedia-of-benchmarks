const MAX_ITEMS: usize = 8;
const MAX_ROWS: usize = 16;
const MAX_WORDS: usize = 513;

fn support(rows: &[i64; MAX_ROWS], row_count: usize, mask: i64) -> usize {
    rows[..row_count].iter().filter(|&&row| row & mask == mask).count()
}

fn closure(rows: &[i64; MAX_ROWS], row_count: usize, item_count: usize, mask: i64) -> i64 {
    let mut common = (1i64 << item_count) - 1;
    for &row in &rows[..row_count] {
        if row & mask == mask { common &= row; }
    }
    common
}

fn core_index(rows: &[i64; MAX_ROWS], row_count: usize, item_count: usize,
        mask: i64, pattern_support: usize) -> usize {
    for item in 0..item_count {
        let prefix_mask = (1i64 << (item + 1)) - 1;
        if support(rows, row_count, mask & prefix_mask) == pattern_support { return item; }
    }
    item_count - 1
}

fn put_i64_le(output: *mut u8, word: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { *output.add(word * 8 + byte) = (bits >> (8 * byte)) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn lcm_ppc_closed_itemset_enumeration(
        input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > 3 + MAX_ROWS { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let item_value = values[0];
    let row_value = values[1];
    let minimum = values[2];
    if item_value < 1 || item_value > MAX_ITEMS as i64 || row_value < 1 ||
        row_value > MAX_ROWS as i64 || minimum < 1 || minimum > row_value ||
        length != 3 + row_value as usize { return -1; }
    let item_count = item_value as usize;
    let row_count = row_value as usize;
    let limit = 1i64 << item_count;
    let mut rows = [0i64; MAX_ROWS];
    for row in 0..row_count {
        let mask = values[3 + row];
        if mask < 0 || mask >= limit { return -1; }
        rows[row] = mask;
    }

    let mut words = [0i64; MAX_WORDS];
    let mut stack_mask = [0i64; MAX_ITEMS + 1];
    let mut stack_support = [0usize; MAX_ITEMS + 1];
    let mut stack_core = [0usize; MAX_ITEMS + 1];
    let mut next_item = [0usize; MAX_ITEMS + 1];
    let mut entered = [false; MAX_ITEMS + 1];
    stack_mask[0] = closure(&rows, row_count, item_count, 0);
    stack_support[0] = row_count;
    stack_core[0] = usize::MAX;
    let mut depth = 0usize;
    let mut record_count = 0usize;
    loop {
        if !entered[depth] {
            words[1 + 2 * record_count] = stack_mask[depth];
            words[2 + 2 * record_count] = stack_support[depth] as i64;
            record_count += 1;
            entered[depth] = true;
            next_item[depth] = if depth == 0 { 0 } else { stack_core[depth] + 1 };
        }
        if next_item[depth] >= item_count {
            entered[depth] = false;
            if depth == 0 { break; }
            depth -= 1;
            continue;
        }

        let item = next_item[depth];
        next_item[depth] += 1;
        let bit = 1i64 << item;
        let parent_mask = stack_mask[depth];
        if parent_mask & bit != 0 { continue; }
        let extended = parent_mask | bit;
        let child_support = support(&rows, row_count, extended);
        if child_support < minimum as usize { continue; }
        let child = closure(&rows, row_count, item_count, extended);
        let lower_prefix = bit - 1;
        if parent_mask & lower_prefix != child & lower_prefix { continue; }
        depth += 1;
        stack_mask[depth] = child;
        stack_support[depth] = child_support;
        stack_core[depth] = core_index(&rows, row_count, item_count, child, child_support);
        entered[depth] = false;
    }

    words[0] = record_count as i64;
    let output_bytes = 8 * (1 + 2 * record_count);
    if output.is_null() || capacity < output_bytes { return -2; }
    for word in 0..1 + 2 * record_count { put_i64_le(output, word, words[word]); }
    output_bytes as i64
}
