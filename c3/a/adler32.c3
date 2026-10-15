module adler32;

const MAX_LENGTH = 100001;
const MOD_ADLER = 65521;

// Compute Adler-32 over byte values without modifying the input.
fn long adler32(long* values, usz length) @export("adler32") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -1;
    long a = 1;
    long b = 0;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value < 0 || value > 255) return -1;
        a = (a + value) % MOD_ADLER;
        b = (b + a) % MOD_ADLER;
    }
    return (b << 16) | a;
}
