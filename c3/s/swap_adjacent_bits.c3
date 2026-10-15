module swap_adjacent_bits;

fn long swap_adjacent_bits(long input) @export("swap_adjacent_bits") {
    if (input < 0 || input > 1073741823) return -1;
    return ((input & 0xAAAAAAAA) >> 1) | ((input & 0x55555555) << 1);
}
