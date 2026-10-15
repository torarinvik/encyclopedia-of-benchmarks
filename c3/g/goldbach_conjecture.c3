module goldbach_conjecture;

fn bool is_prime(long value) {
    if (value == 2) return true;
    if (value < 2 || value % 2 == 0) return false;
    for (long divisor = 3; divisor <= value / divisor; divisor += 2)
        if (value % divisor == 0) return false;
    return true;
}

fn long goldbach_conjecture(long number, char* output, usz output_capacity)
    @export("goldbach_conjecture")
{
    if (number < 4 || number > 4096 || number % 2 != 0) return -1;
    if (output == null || output_capacity < 8) return -2;
    for (long first = 0; first <= number / 2; first++) {
        long second = number - first;
        if (is_prime(first) && is_prime(second)) {
            ulong pair[2] = {(ulong)first, (ulong)second};
            for (usz j = 0; j < 2; j++)
                for (usz b = 0; b < 4; b++)
                    output[4 * j + b] = (char)((pair[j] >> (8 * b)) & 0xff);
            return 8;
        }
    }
    return -1;
}
