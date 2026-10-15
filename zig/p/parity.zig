/// Return the parity of the set-bit count using Kernighan's bit clearing.
export fn parity(number: i64) i64 {
    if (number < 0) return -1;
    var current = number;
    var result: i64 = 0;
    while (current != 0) {
        result ^= 1;
        current &= current - 1;
    }
    return result;
}
