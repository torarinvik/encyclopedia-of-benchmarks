module alphabetic_anagrams;

const usz MAX_LENGTH = 8;
const usz ALPHABET_SIZE = 26;

fn long factorial(long value) {
    long result = 1;
    for (long factor = 2; factor <= value; factor++) result *= factor;
    return result;
}

fn long alphabetic_anagrams(long* input, usz length) @export("alphabetic_anagrams") {
    if (input == null || length < 1 || length > 10) return -1;
    long n = input[0];
    if (n < 0 || n > (long)MAX_LENGTH || length != (usz)n + 1) return -1;
    long[ALPHABET_SIZE] frequency;
    for (usz symbol = 0; symbol < ALPHABET_SIZE; symbol++) frequency[symbol] = 0;
    for (long position = 0; position < n; position++) {
        long symbol = input[position + 1];
        if (symbol < 0 || symbol > 25) return -1;
        frequency[symbol]++;
    }

    long denominator = 1;
    for (usz symbol = 0; symbol < ALPHABET_SIZE; symbol++) denominator *= factorial(frequency[symbol]);
    long ways = factorial(n) / denominator;
    long rank = 1, remaining = n;
    for (long position = 0; position < n; position++) {
        long actual = input[position + 1];
        for (long smaller = 0; smaller < actual; smaller++) {
            if (frequency[smaller] > 0) rank += ways * frequency[smaller] / remaining;
        }
        ways = ways * frequency[actual] / remaining;
        frequency[actual]--;
        remaining--;
    }
    return rank;
}
