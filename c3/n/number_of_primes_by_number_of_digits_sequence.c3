module number_of_primes_by_number_of_digits_sequence;

fn bool is_prime(long value) {
    if (value < 2) return false;
    for (long factor = 2; factor <= value / factor; factor += 1) {
        if (value % factor == 0) return false;
    }
    return true;
}

fn long number_of_primes_by_number_of_digits_sequence(long index)
    @export("number_of_primes_by_number_of_digits_sequence")
{
    if (index < 0 || index > 3) return -1;
    if (index == 0) return 0;
    long lower = 1;
    for (long i = 1; i < index; i += 1) lower *= 10;
    long upper = lower * 10;
    long count = 0;
    for (long value = lower + 1; value <= upper; value += 1) {
        if (is_prime(value)) count += 1;
    }
    return count;
}
