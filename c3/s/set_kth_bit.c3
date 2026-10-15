module set_kth_bit;

fn long set_kth_bit(long* input, usz length) @export("set_kth_bit") {
    if (input == null || length != 2) return -1;
    long number = input[0], bit = input[1];
    if (number < 0 || number > 2147483647 || bit < 0 || bit > 30) return -1;
    return number | (1L << bit);
}
