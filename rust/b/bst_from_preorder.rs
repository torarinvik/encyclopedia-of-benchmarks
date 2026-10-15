/// Validate and serialize a strict BST reconstructed from preorder values.
fn valid_preorder(values: &[i64], lower: i64, upper: i64) -> bool {
    fn visit(values: &[i64], index: &mut usize, lower: i64, upper: i64) -> bool {
        if *index == values.len() { return true; }
        let root = values[*index];
        if root <= lower || root >= upper { return true; }
        *index += 1;
        visit(values, index, lower, root) && visit(values, index, root, upper)
    }
    let mut index = 0;
    visit(values, &mut index, lower, upper) && index == values.len()
}

fn emit_preorder_tree(values: &[i64], output: *mut u8, position: usize) -> usize {
    if values.is_empty() {
        unsafe { output.add(position).write(0); }
        return position + 1;
    }
    let root = values[0];
    let split = values[1..].iter().position(|&value| value >= root)
        .map_or(values.len(), |offset| offset + 1);
    unsafe {
        output.add(position).write(1);
        let encoded = root as i32 as u32;
        output.add(position + 1).write(encoded as u8);
        output.add(position + 2).write((encoded >> 8) as u8);
        output.add(position + 3).write((encoded >> 16) as u8);
        output.add(position + 4).write((encoded >> 24) as u8);
    }
    let next_position = emit_preorder_tree(&values[1..split], output, position + 5);
    emit_preorder_tree(&values[split..], output, next_position)
}

#[no_mangle]
pub extern "C" fn bst_from_preorder(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length == 0 || length > 15 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values.iter().any(|&value| !(-2147483648..=2147483647).contains(&value)) ||
        !valid_preorder(values, -2147483649, 2147483648) { return -1; }
    let required = 6 * length + 1;
    if output_capacity < required || output.is_null() { return -2; }
    emit_preorder_tree(values, output, 0);
    length as i64
}
