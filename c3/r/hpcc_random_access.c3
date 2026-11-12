module hpcc_random_access;

const long MAX_TABLE_SIZE = 256;
const ulong DIGEST_MASK = 0x7ffffffffffffffful;

fn long hpcc_random_access(long* input, usz length) @export("hpcc_random_access") {
    if (input == null || length != 1) return -1;
    long size_value = input[0];
    if (size_value < 2 || size_value > MAX_TABLE_SIZE ||
        (size_value & (size_value - 1)) != 0) return -1;

    usz size = (usz)size_value;
    ulong[256] table;
    for (usz index = 0; index < size; index++) table[index] = (ulong)index;

    ulong ran = 1ul;
    for (usz update = 0; update < 4 * size; update++) {
        ulong feedback = (ran >> 63) != 0 ? 7ul : 0ul;
        // Clearing the outgoing bit makes the fixed-width shift exact without
        // relying on signed overflow behavior.
        ran = ((ran & DIGEST_MASK) << 1) ^ feedback;
        table[(usz)(ran & (ulong)(size - 1))] ^= ran;
    }

    // C3 unsigned ulong arithmetic wraps modulo 2^64, as the digest requires.
    ulong digest = 0ul;
    for (usz index = 0; index < size; index++) {
        digest += (ulong)(index + 1) * table[index];
    }
    return (long)(digest & DIGEST_MASK);
}
