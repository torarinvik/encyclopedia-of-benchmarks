module fermat_factorization;

fn long integer_sqrt_i64(long value, long upper) {
    long low = 0;
    long high = upper + 1;
    while (low + 1 < high) {
        long middle = low + (high - low) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

fn long fermat_factorization(long* input, usz length) @export("fermat_factorization") {
    if (input == null || length != 2) return -1;
    long number = input[0], max_steps = input[1];
    if (number < 3 || number > 1000000000000 || number % 2 == 0 || max_steps < 0 || max_steps > 4096) return -1;
    long candidate = integer_sqrt_i64(number, 1000000);
    if (candidate * candidate < number) candidate++;
    for (long step = 0; step < max_steps; step++) {
        long difference = candidate * candidate - number;
        long root = integer_sqrt_i64(difference, candidate);
        if (root * root == difference) {
            long factor = candidate - root;
            if (factor > 1 && factor < number) return factor;
        }
        candidate++;
    }
    return 0;
}
