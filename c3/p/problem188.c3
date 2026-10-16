module problem188;

fn long modexpt(long base, long exponent, long modulus) {
    if (exponent == 1) return base;
    if (exponent % 2 == 0) {
        long half = modexpt(base, exponent / 2, modulus) % modulus;
        return (half * half) % modulus;
    }
    return (base * modexpt(base, exponent - 1, modulus)) % modulus;
}

fn long problem188(long base, long height, long digits) @export("problem188") {
    if (base < 1 || base > 1000000000 || base % 10 == 0
        || height < 1 || height > 10000 || digits < 1 || digits > 8) return -1;
    long modulus = 1;
    for (long index = 0; index < digits; index++) modulus *= 10;
    long result = base;
    for (long level = 1; level < height; level++) result = modexpt(base, result, modulus);
    return result;
}
