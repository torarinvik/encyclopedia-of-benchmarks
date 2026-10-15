module reverse_bits;

// Reverse the bit order of an unsigned 32-bit word.
fn long reverse_bits(long value) @export("reverse_bits") {
    if (value < 0 || value > 4294967295) return -1;
    uint remaining = (uint)value;
    uint reversed = 0;
    for (uint bit = 0; bit < 32; bit++) {
        reversed = (reversed << 1) | (remaining & 1);
        remaining = remaining >> 1;
    }
    return (long)reversed;
}
