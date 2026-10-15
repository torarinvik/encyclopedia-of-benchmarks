/// Find the first shared node identity by switching traversal heads.
const MAX_LIST_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_LIST_LENGTH;

export fn intersection_of_two_linked_lists(input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_INPUT_LENGTH) return -2;
    const first_length_value = input[0];
    const second_length_value = input[1];
    if (first_length_value < 0 or first_length_value > MAX_LIST_LENGTH or
        second_length_value < 0 or second_length_value > MAX_LIST_LENGTH) return -2;
    const first_length: usize = @intCast(first_length_value);
    const second_length: usize = @intCast(second_length_value);
    if (length != 2 + first_length + second_length) return -2;
    for (2..length) |index| {
        const value = input[index];
        if (value < 0 or value > 2147483647) return -2;
    }
    if (first_length == 0 or second_length == 0) return -1;

    var first_position: usize = 0;
    var second_position: usize = 0;
    var first_on_first_list = true;
    var second_on_first_list = false;
    for (0..first_length + second_length + 1) |_| {
        const first_base = if (first_on_first_list) 2 else 2 + first_length;
        const first_source_length = if (first_on_first_list) first_length else second_length;
        const second_base = if (second_on_first_list) 2 else 2 + first_length;
        const second_source_length = if (second_on_first_list) first_length else second_length;
        const first_node = input[first_base + first_position];
        const second_node = input[second_base + second_position];
        if (first_node == second_node) return first_node;
        first_position += 1;
        second_position += 1;
        const first_is_null = first_position == first_source_length;
        const second_is_null = second_position == second_source_length;
        if (first_is_null and second_is_null) return -1;
        if (first_is_null) {
            first_on_first_list = !first_on_first_list;
            first_position = 0;
        }
        if (second_is_null) {
            second_on_first_list = !second_on_first_list;
            second_position = 0;
        }
    }
    return -1;
}
