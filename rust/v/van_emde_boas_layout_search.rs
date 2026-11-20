const MAX_HEIGHT: usize = 4;
const MAX_NODES: usize = 15;
const MAX_QUERIES: usize = 4;
const MAX_WORDS: usize = 41;

fn fill_keys(keys: &mut [i64; MAX_NODES + 1], heap: usize, low: i64, high: i64) {
    if low > high { return; }
    let middle = low + (high - low) / 2;
    keys[heap] = middle;
    fill_keys(keys, heap * 2, low, middle - 1);
    fill_keys(keys, heap * 2 + 1, middle + 1, high);
}

fn emit_layout(order: &mut [i64; MAX_NODES], used: &mut usize,
               root: usize, height: usize) {
    if height == 1 {
        order[*used] = root as i64;
        *used += 1;
        return;
    }
    let top_height = height / 2;
    let bottom_height = height - top_height;
    emit_layout(order, used, root, top_height);
    let bottom_count = 1usize << top_height;
    for offset in 0..bottom_count {
        emit_layout(order, used, root * bottom_count + offset, bottom_height);
    }
}

#[no_mangle]
pub extern "C" fn van_emde_boas_layout_search(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 2 + MAX_QUERIES + 1 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let height_value = values[0];
    let query_value = values[1];
    if height_value < 1 || height_value > MAX_HEIGHT as i64 ||
        query_value < 0 || query_value > MAX_QUERIES as i64 { return -1; }
    let height = height_value as usize;
    let query_count = query_value as usize;
    if length != 2 + query_count { return -1; }
    let node_count = (1usize << height) - 1;
    if values[2..].iter().any(|&key| key < -1 || key > node_count as i64) { return -1; }

    let mut order = [0i64; MAX_NODES];
    let mut keys = [0i64; MAX_NODES + 1];
    let mut slots = [0i64; MAX_NODES + 1];
    let mut staged = [0i64; MAX_WORDS];
    let mut used = 0usize;
    emit_layout(&mut order, &mut used, 1, height);
    fill_keys(&mut keys, 1, 0, node_count as i64 - 1);
    for slot in 0..node_count { slots[order[slot] as usize] = slot as i64; }

    let mut out = 0usize;
    staged[out] = node_count as i64;
    out += 1;
    for slot in 0..node_count { staged[out] = order[slot]; out += 1; }
    staged[out] = query_count as i64;
    out += 1;
    for query in 0..query_count {
        let key = values[2 + query];
        let mut heap = 1usize;
        let path_start = out;
        out += 1;
        let mut path_length = 0usize;
        let mut found = -1i64;
        while heap <= node_count {
            staged[out] = slots[heap];
            out += 1;
            path_length += 1;
            if key == keys[heap] {
                found = heap as i64;
                break;
            }
            heap = if key < keys[heap] { 2 * heap } else { 2 * heap + 1 };
        }
        staged[path_start] = path_length as i64;
        staged[out] = found;
        out += 1;
    }
    let required = out * 8;
    if output.is_null() || capacity < required { return -2; }
    for word in 0..out {
        let bytes = staged[word].to_le_bytes();
        for byte in 0..8 {
            unsafe { output.add(word * 8 + byte).write(bytes[byte]); }
        }
    }
    required as i64
}
