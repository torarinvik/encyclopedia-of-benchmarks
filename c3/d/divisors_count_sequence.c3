module divisors_count_sequence;

const long MAX_INDEX = 9999L;

fn long divisors_count_sequence(long index) @export("divisors_count_sequence") {
    if (index < 0 || index > MAX_INDEX) return -1;
    long n = index + 1;
    if (n == 1) return 1;
    long count = 2;
    for (long k = 2; k < n; k += 1) {
        if (n % k == 0) count += 1;
    }
    return count;
}
