module problem493;

fn long choose_ten(long n) {
    long result = 1;
    for (long i = 0; i < 10; i++) result = result * (n - i) / (i + 1);
    return result;
}

fn long problem493(long picks) @export("problem493") {
    if (picks < 0 || picks > 70) return -1;
    long denominator = choose_ten(70);
    long missing = picks > 60 ? 0 : choose_ten(70 - picks);
    long numerator = 7 * (denominator - missing);
    long whole = numerator / denominator;
    long remainder = numerator % denominator;
    long fraction = 0;
    for (int i = 0; i < 9; i++) { remainder *= 10; fraction = fraction * 10 + remainder / denominator; remainder %= denominator; }
    remainder *= 10;
    long guard = remainder / denominator;
    remainder %= denominator;
    long scaled = whole * 1000000000 + fraction;
    if (guard > 5 || (guard == 5 && (remainder > 0 || scaled % 2 != 0))) scaled++;
    return scaled;
}
