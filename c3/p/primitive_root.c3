module primitive_root;

// Search in ascending order for a full period of distinct residues.
fn long primitive_root(long* input, usz length) @export("primitive_root") {
    if (input == null || length != 1 || input[0] < 2 || input[0] > 127) return -1;
    long modulus = input[0];
    for (long candidate = 1; candidate < modulus; candidate++) {
        bool[127] seen = {};
        long power = 1;
        bool distinct = true;
        for (long exponent = 0; exponent < modulus - 1; exponent++) {
            if (seen[power]) { distinct = false; break; }
            seen[power] = true;
            power = (power * candidate) % modulus;
        }
        if (distinct) return candidate;
    }
    return 0;
}
