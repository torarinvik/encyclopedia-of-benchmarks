module max_consecutive_ones;

// Return the longest run of ones in a binary array.
fn long max_consecutive_ones(long* values, usz length) @export("max_consecutive_ones") {
    if (length > 4096) return -1;
    usz best = 0;
    usz run = 0;
    for (usz index = 0; index < length; index++) {
        if (values[index] != 0 && values[index] != 1) return -1;
        if (values[index] == 1) {
            run++;
            if (run > best) best = run;
        } else {
            run = 0;
        }
    }
    return (long)best;
}
