struct Context {
    minimum_support: i64,
    words: [i64; 511],
    records: usize,
}

fn enumerate(ctx: &mut Context, rows: &[i64], item_count: usize,
             start_item: usize, prefix: i64) {
    for item in start_item..item_count {
        let bit = 1i64 << item;
        let mut projected = [0i64; 16];
        let mut projected_count = 0usize;
        for &row in rows {
            if row & bit != 0 {
                projected[projected_count] = row;
                projected_count += 1;
            }
        }
        if (projected_count as i64) < ctx.minimum_support { continue; }
        let mask = prefix | bit;
        let at = 1 + 2 * ctx.records;
        ctx.words[at] = mask;
        ctx.words[at + 1] = projected_count as i64;
        ctx.records += 1;
        enumerate(ctx, &projected[..projected_count], item_count, item + 1, mask);
    }
}

#[no_mangle]
pub unsafe extern "C" fn frequent_itemset_backtrack(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > 19 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let item_count0 = values[0];
    let row_count0 = values[1];
    let minimum = values[2];
    if !(1..=8).contains(&item_count0) || !(1..=16).contains(&row_count0) ||
       minimum < 1 || minimum > row_count0 || length != 3 + row_count0 as usize { return -1; }
    let item_count = item_count0 as usize;
    let limit = 1i64 << item_count;
    let rows = &values[3..];
    if rows.iter().any(|&mask| mask < 0 || mask >= limit) { return -1; }
    let mut ctx = Context { minimum_support: minimum, words: [0; 511], records: 0 };
    enumerate(&mut ctx, rows, item_count, 0, 0);
    ctx.words[0] = ctx.records as i64;
    let word_count = 1 + 2 * ctx.records;
    let bytes = word_count * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let dst = std::slice::from_raw_parts_mut(output, bytes);
    for i in 0..word_count {
        dst[i * 8..i * 8 + 8].copy_from_slice(&ctx.words[i].to_le_bytes());
    }
    bytes as i64
}
