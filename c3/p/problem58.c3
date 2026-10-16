module problem58;

fn bool is_prime(long value) {
    if (value < 2) return false;
    if (value < 4) return true;
    if (value % 2 == 0 || value % 3 == 0) return false;
    for (long divisor = 5; divisor <= value / divisor; divisor += 6) {
        if (value % divisor == 0 || value % (divisor + 2) == 0) return false;
    }
    return true;
}

fn double problem58(double ratio) @export("problem58") {
    if (!(ratio >= 0.1 && ratio <= 0.6)) return -1.0;
    long side = 3;
    long prime_count = 3;
    while ((double)prime_count / (double)(2 * side - 1) >= ratio) {
        long square = side * side;
        long step = side + 1;
        if (is_prime(square + step)) prime_count++;
        if (is_prime(square + 2 * step)) prime_count++;
        if (is_prime(square + 3 * step)) prime_count++;
        side += 2;
    }
    return (double)side;
}
