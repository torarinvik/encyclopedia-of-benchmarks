module nsieve_bits;

const long MAX_LIMIT = 1000000;
const usz MAX_WORDS = 15626;

fn long count_primes(long limit) {
    u64[MAX_WORDS] bits;
    for (usz word = 0; word < MAX_WORDS; word++) bits[word] = 0xFFFFFFFFFFFFFFFFu64;
    long count = 0;
    for (long value = 2; value <= limit; value++) {
        usz word = (usz)(value / 64);
        u64 mask = (u64)1 << (value % 64);
        if ((bits[word] & mask) != 0) {
            count++;
            for (long multiple = value + value; multiple <= limit; multiple += value) {
                usz multiple_word = (usz)(multiple / 64);
                u64 multiple_mask = (u64)1 << (multiple % 64);
                if ((bits[multiple_word] & multiple_mask) != 0) bits[multiple_word] ^= multiple_mask;
            }
        }
    }
    return count;
}

fn void put_u64_le(char* output, usz offset, u64 value) {
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(value >> (8 * byte));
}

fn long benchmarkgame_nsieve_bits(long* input, usz length, char* output, usz capacity) @export("benchmarkgame_nsieve_bits") {
    if (input == null || length != 1 || input[0] < 0 || input[0] > MAX_LIMIT) return -1;
    if (output == null || capacity < 24) return -2;
    for (usz pass = 0; pass < 3; pass++) put_u64_le(output, pass * 8, (u64)count_primes(input[0] >> (long)pass));
    return 24;
}
