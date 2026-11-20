module baum_sweet_sequence;

fn long baum_sweet_term(long number) {
    if (number == 0) return 0;
    long mask = 1;
    while (mask <= number / 2) mask *= 2;
    bool odd_zero_run = false;
    while (mask > 0) {
        if ((number & mask) != 0) {
            if (odd_zero_run) return 0;
            odd_zero_run = false;
        } else {
            odd_zero_run = !odd_zero_run;
        }
        mask /= 2;
    }
    return odd_zero_run ? 0 : 1;
}

fn long baum_sweet_sequence(long* input, usz length) @export("baum_sweet_sequence") {
    if (input == null || length != 1) return -1;
    long count = input[0];
    if (count < 0 || count > 63) return -1;
    long packed = 0;
    long bit = 1;
    for (long index = 0; index < count; index++) {
        if (baum_sweet_term(index) != 0) packed += bit;
        if (index + 1 < count) bit *= 2;
    }
    return packed;
}
