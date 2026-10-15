module list_intersection;

const usz MAX_LIST_LENGTH = 1024;
const usz MAX_INPUT_LENGTH = 2050;

// Find the first shared node identity by switching traversal heads.
fn long intersection_of_two_linked_lists(long* input, usz length) @export("intersection_of_two_linked_lists") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) { return -2; }
    long first_length_value = input[0];
    long second_length_value = input[1];
    if (first_length_value < 0 || first_length_value > 1024 || second_length_value < 0 || second_length_value > 1024) { return -2; }
    usz first_length = (usz)first_length_value;
    usz second_length = (usz)second_length_value;
    if (length != 2 + first_length + second_length) { return -2; }
    for (usz index = 2; index < length; index++) {
        if (input[index] < 0 || input[index] > 2147483647L) { return -2; }
    }
    if (first_length == 0 || second_length == 0) { return -1; }

    usz first_position = 0;
    usz second_position = 0;
    bool first_on_first_list = true;
    bool second_on_first_list = false;
    for (usz step = 0; step <= first_length + second_length; step++) {
        usz first_base = 2;
        usz first_source_length = first_length;
        if (!first_on_first_list) { first_base = 2 + first_length; first_source_length = second_length; }
        usz second_base = 2 + first_length;
        usz second_source_length = second_length;
        if (second_on_first_list) { second_base = 2; second_source_length = first_length; }
        long first_node = input[first_base + first_position];
        long second_node = input[second_base + second_position];
        if (first_node == second_node) { return first_node; }

        first_position++;
        second_position++;
        bool first_is_null = first_position == first_source_length;
        bool second_is_null = second_position == second_source_length;
        if (first_is_null && second_is_null) { return -1; }
        if (first_is_null) { first_on_first_list = !first_on_first_list; first_position = 0; }
        if (second_is_null) { second_on_first_list = !second_on_first_list; second_position = 0; }
    }
    return -1;
}
