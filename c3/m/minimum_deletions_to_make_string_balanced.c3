module minimum_deletions_balanced;

// Minimum deletions to leave all a values before all b values.
fn long minimum_deletions_to_make_string_balanced(long* values, usz length) @export("minimum_deletions_to_make_string_balanced") {
    if (length > 256 || (length != 0 && values == null)) return -1;
    long a_state = 0;
    long b_state = 0;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value < 0 || value > 1) return -1;
        long next_a = a_state + (value == 1 ? 1 : 0);
        long b_with_a = b_state + (value == 0 ? 1 : 0);
        long next_b = a_state < b_with_a ? a_state : b_with_a;
        a_state = next_a;
        b_state = next_b;
    }
    return a_state < b_state ? a_state : b_state;
}
