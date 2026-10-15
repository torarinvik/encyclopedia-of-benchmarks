module square_free_factor_list;

// Check that an integer factor list has no repeated values.
fn long square_free_factor_list(long* values, usz length) @export("square_free_factor_list")
{
    if (length > 256 || (length != 0 && values == null)) return -1;
    for (usz i = 0; i < length; i++) {
        if (values[i] < -2147483648 || values[i] > 2147483647) return -1;
        for (usz j = 0; j < i; j++) {
            if (values[i] == values[j]) return 0;
        }
    }
    return 1;
}
