module check_even;

// Return 1 for even and 0 for odd signed 64-bit integers.
fn long check_even(long value) @export("check_even") {
    if (value % 2 == 0) return 1;
    return 0;
}
