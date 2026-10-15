module hamming_weight;

// Count set bits in an unsigned 32-bit integer.
fn long hamming_weight(long value) @export("hamming_weight") {
    if (value < 0 || value > 4294967295) return -1;
    long remaining = value;
    long count = 0;
    while (remaining != 0) {
        remaining &= remaining - 1;
        count++;
    }
    return count;
}
