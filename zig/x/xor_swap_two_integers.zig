/// XOR-swap a bounded signed pair and pack the returned values into i64.
export fn xor_swap_two_integers(first: i64, second: i64) i64 {
    if (first < -32768 or first > 32767 or second < -32768 or second > 32767) return -1;
    var a = if (first < 0) first + 65536 else first;
    var b = if (second < 0) second + 65536 else second;
    a ^= b;
    b ^= a;
    a ^= b;
    const swapped_first = if (a >= 32768) a - 65536 else a;
    const swapped_second = if (b >= 32768) b - 65536 else b;
    return (swapped_first + 32768) * 65536 + (swapped_second + 32768);
}
