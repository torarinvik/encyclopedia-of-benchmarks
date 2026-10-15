/// Find the first shared node identity by switching traversal heads.
const MAX_LIST_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_LIST_LENGTH;

#[no_mangle]
pub extern "C" fn intersection_of_two_linked_lists(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -2; }
    let first_length_value = unsafe { *input };
    let second_length_value = unsafe { *input.add(1) };
    if first_length_value < 0 || first_length_value > MAX_LIST_LENGTH as i64 ||
        second_length_value < 0 || second_length_value > MAX_LIST_LENGTH as i64 { return -2; }
    let first_length = first_length_value as usize;
    let second_length = second_length_value as usize;
    if length != 2 + first_length + second_length { return -2; }
    for index in 2..length {
        let value = unsafe { *input.add(index) };
        if !(0..=i32::MAX as i64).contains(&value) { return -2; }
    }
    if first_length == 0 || second_length == 0 { return -1; }

    let mut first_position = 0;
    let mut second_position = 0;
    let mut first_on_first_list = true;
    let mut second_on_first_list = false;
    for _ in 0..=first_length + second_length {
        let first_base = if first_on_first_list { 2 } else { 2 + first_length };
        let first_source_length = if first_on_first_list { first_length } else { second_length };
        let second_base = if second_on_first_list { 2 } else { 2 + first_length };
        let second_source_length = if second_on_first_list { first_length } else { second_length };
        let first_node = unsafe { *input.add(first_base + first_position) };
        let second_node = unsafe { *input.add(second_base + second_position) };
        if first_node == second_node { return first_node; }
        first_position += 1;
        second_position += 1;
        let first_is_null = first_position == first_source_length;
        let second_is_null = second_position == second_source_length;
        if first_is_null && second_is_null { return -1; }
        if first_is_null { first_on_first_list = !first_on_first_list; first_position = 0; }
        if second_is_null { second_on_first_list = !second_on_first_list; second_position = 0; }
    }
    -1
}
