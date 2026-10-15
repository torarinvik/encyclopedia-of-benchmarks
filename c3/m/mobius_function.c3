module mobius_function;

fn long mobius_function(long n) @export("mobius_function") {
    if (n < 1 || n > 10000) return -9223372036854775807 - 1;
    long remaining = n;
    long distinct_factor_count = 0;
    for (long factor = 2; factor * factor <= remaining; factor++) {
        if (remaining % factor == 0) {
            remaining /= factor;
            if (remaining % factor == 0) return 0;
            distinct_factor_count++;
        }
    }
    if (remaining > 1) distinct_factor_count++;
    return distinct_factor_count % 2 == 0 ? 1 : -1;
}
