module problem138;

fn long problem138(long count) @export("problem138") {
    if (count > 14) return -1;
    if (count <= 0) return 0;
    long m = 2;
    long l = 1;
    long total = 0;
    for (long i = 0; i < count; i++) {
        long next_m = 9 * m + 20 * l;
        long next_l = 4 * m + 9 * l;
        m = next_m;
        l = next_l;
        total += l;
    }
    return total;
}
