module xor_swap_two_integers;

fn long xor_swap_two_integers(long first, long second) @export("xor_swap_two_integers") {
    if (first < -32768 || first > 32767 || second < -32768 || second > 32767) return -1;
    long a = first < 0 ? first + 65536 : first;
    long b = second < 0 ? second + 65536 : second;
    a = a ^ b;
    b = a ^ b;
    a = a ^ b;
    long swapped_first = a >= 32768 ? a - 65536 : a;
    long swapped_second = b >= 32768 ? b - 65536 : b;
    return (swapped_first + 32768) * 65536 + (swapped_second + 32768);
}
