module figurate_number;

fn bool is_triangular(long n) {
    for (long i = 0; i <= n; i++) {
        long term = i * (i + 1) / 2;
        if (term == n) return true;
        if (term > n) return false;
    }
    return false;
}

fn bool is_tetrahedral(long n) {
    for (long i = 1; i <= n; i++) {
        long term = i * (i + 1) * (i + 2) / 6;
        if (term == n) return true;
        if (term > n) return false;
    }
    return false;
}

fn bool is_pentatope(long n) {
    for (long i = 1; i <= n; i++) {
        long term = i * (i + 1) * (i + 2) * (i + 3) / 24;
        if (term == n) return true;
        if (term > n) return false;
    }
    return false;
}

fn long figurate_number(long n) @export("figurate_number") {
    if (n < 0 || n > 1000000) return -1;
    return (is_triangular(n) ? 1 : 0)
        + (is_tetrahedral(n) ? 2 : 0)
        + (is_pentatope(n) ? 4 : 0);
}
