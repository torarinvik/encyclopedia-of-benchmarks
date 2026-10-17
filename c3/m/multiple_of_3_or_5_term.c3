module multiple_of_3_or_5_term;

long multiple_of_3_or_5_term(long n) @export("multiple_of_3_or_5_term") {
    if (n < 0 || n > 1000000000) return -1;
    return n % 3 == 0 || n % 5 == 0 ? n : 0;
}
