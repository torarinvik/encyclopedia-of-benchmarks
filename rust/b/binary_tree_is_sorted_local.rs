const MISSING_NODE: i64 = -2_147_483_649;
const MAX_SLOTS: usize = 255;

#[no_mangle]
pub extern "C" fn binary_tree_is_sorted_local(nodes: *const i64, length: usize) -> i64 {
    if length == 0 || length > MAX_SLOTS || nodes.is_null() { return -1; }
    let nodes = unsafe { std::slice::from_raw_parts(nodes, length) };
    if nodes[0] == MISSING_NODE { return -1; }
    for (index, &value) in nodes.iter().enumerate() {
        if value == MISSING_NODE { continue; }
        if !(-2_147_483_648..=2_147_483_647).contains(&value) { return -1; }
        if index > 0 {
            let parent = (index - 1) / 2;
            if nodes[parent] == MISSING_NODE { return -1; }
            if (index % 2 == 1 && value > nodes[parent]) ||
                (index % 2 == 0 && value < nodes[parent]) { return 0; }
        }
    }
    1
}
