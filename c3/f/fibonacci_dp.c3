module fibonacci_dp;

// Tabulated Fibonacci for the bounded signed 64-bit benchmark contract.
fn long fibonacci_dp(long n) @export("fibonacci_dp")
{
    if (n < 0 || n > 46) return -1;

    long[47] table;
    table[0] = 0;
    table[1] = 1;
    long index = 2;
    while (index <= n) {
        table[index] = table[index - 1] + table[index - 2];
        index++;
    }
    return table[n];
}
