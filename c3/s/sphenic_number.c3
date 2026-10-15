module sphenic_number;

fn bool source_sieve_flag(long value) {
    if (value < 2) return true;
    for (long divisor = 2; divisor <= value / divisor; divisor++) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn long sphenic_number(long value) @export("sphenic_number") {
    if (value < 0 || value > 1000) return -1;
    long[3] first;
    long count = 0;
    for (long divisor = 1; divisor <= value; divisor++) {
        if (value % divisor == 0 && count < 9) {
            if (count < 3) first[(usz)count] = divisor;
            count++;
        }
    }
    if (count == 8 && source_sieve_flag(first[0])
        && source_sieve_flag(first[1]) && source_sieve_flag(first[2])) return 1;
    return 0;
}
