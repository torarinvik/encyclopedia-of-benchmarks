module bit_swap;

// Swap two 0-based bits in a signed 32-bit value.
fn long bit_swap(long* values, usz length) @export("bit_swap") {
    if (values == null || length != 3) return -2147483649;
    long data = values[0];
    long pos_a = values[1];
    long pos_b = values[2];
    if (data < -2147483648 || data > 2147483647 || pos_a < 0 || pos_a >= 32 || pos_b < 0 || pos_b >= 32)
        return -2147483649;
    long bits = data & 4294967295;
    long mask_a = (long)1 << (usz)pos_a;
    long mask_b = (long)1 << (usz)pos_b;
    long bit_a = (bits >> (usz)pos_a) & 1;
    long bit_b = (bits >> (usz)pos_b) & 1;
    if (bit_a != bit_b) bits = bits ^ mask_a ^ mask_b;
    if (bits >= 2147483648) return bits - 4294967296;
    return bits;
}
