module palindrome_prime;

fn bool is_prime(u32 value) {
    if (value < 2) return false;
    for (u32 divisor = 2; divisor <= value / divisor; divisor++)
        if (value % divisor == 0) return false;
    return true;
}

fn u32 reverse_decimal(u32 value) {
    u32 reversed = 0;
    while (value > 0) {
        reversed = reversed * 10 + value % 10;
        value /= 10;
    }
    return reversed;
}

fn void write_u32_le(char* output, usz position, u32 value) {
    output[position] = (char)value;
    output[position + 1] = (char)(value >> 8);
    output[position + 2] = (char)(value >> 16);
    output[position + 3] = (char)(value >> 24);
}

// Encode the first n palindrome primes as little-endian u32 values.
fn long palindrome_prime(long n, char* output, usz output_capacity) @export("palindrome_prime") {
    if (n > 16) return -1;
    if (n <= 0) return 0;
    usz required = (usz)n * 4;
    if (output == null || output_capacity < required) return -2;
    write_u32_le(output, 0, 2);
    usz count = 1;
    for (u32 candidate = 3; count < (usz)n; candidate += 2) {
        if (candidate == reverse_decimal(candidate) && is_prime(candidate)) {
            write_u32_le(output, count * 4, candidate);
            count++;
        }
    }
    return (long)required;
}
