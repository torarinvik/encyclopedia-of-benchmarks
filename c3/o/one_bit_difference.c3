module one_bit_difference;

fn long one_bit_difference(long* input, usz length) @export("one_bit_difference")
{
    if (input == null || length != 2) return -1;
    long left = input[0];
    long right = input[1];
    if (left < -2147483648 || left > 2147483647 || right < -2147483648 || right > 2147483647) return -1;
    uint difference = (uint)left ^ (uint)right;
    return difference != 0 && (difference & (difference - 1)) == 0 ? 1 : 0;
}
