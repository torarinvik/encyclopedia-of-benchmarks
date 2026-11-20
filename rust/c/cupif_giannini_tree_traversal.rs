#[no_mangle]
pub unsafe extern "C" fn cupif_giannini_tree_traversal(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 3 {
        return -1;
    }
    if length != 2 {
        return -1;
    }

    let height = *input;
    let key_value = *input.add(1);
    if !(0..=6).contains(&height) {
        return -1;
    }
    let leaf_count = 1u64 << (height as u32);
    if key_value < 0 || key_value as u64 >= leaf_count {
        return -1;
    }
    let required = leaf_count as usize;
    if output.is_null() || capacity < required {
        return -2;
    }

    for count in 0..leaf_count {
        let path = count ^ key_value as u64;
        let mut leaf_code = 0u8;
        for depth in 0..height as u32 {
            if ((path >> depth) & 1) != 0 {
                leaf_code |= 1u8 << depth;
            }
        }
        *output.add(count as usize) = leaf_code;
    }
    required as i64
}
