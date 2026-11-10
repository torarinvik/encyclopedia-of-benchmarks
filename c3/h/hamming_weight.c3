module hamming_weight;

import std::bits;

// Count set bits in an unsigned 32-bit integer.
fn long hamming_weight(long value) @export("hamming_weight") {
    if (value < 0 || value > 4294967295) return -1;
    uint number = (uint)value;
    return (long)number.popcount();
}
