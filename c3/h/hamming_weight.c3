module hamming_weight;

// Count set bits in an unsigned 32-bit integer.
fn long hamming_weight(long value) @export("hamming_weight") {
    if (value < 0 || value > 4294967295) return -1;
    long count = 0;
    for (uint bit = 0; bit < 32; bit++) {
        count += (value >> bit) & 1L;
    }
    return count;
}
