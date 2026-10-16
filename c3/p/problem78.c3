module problem78;

const long MAX_MODULUS = 1000000;
const long MAX_INDEX = 55374;

fn long positive_mod(long value, long modulus) {
    value %= modulus;
    return value < 0 ? value + modulus : value;
}

fn long problem78(long modulus) @export("problem78") {
    if (modulus < 1 || modulus > MAX_MODULUS) return -1;
    u32[MAX_INDEX + 1] partitions = {1};
    for (long n = 1; n <= MAX_INDEX; ++n) {
        long value = 0;
        for (long j = 1;; ++j) {
            long first = (3 * j * j - j) / 2;
            if (first > n) break;
            long sign = j % 2 == 0 ? -1 : 1;
            value = positive_mod(value + sign * (long)partitions[(usz)(n - first)], modulus);
            long second = first + j;
            if (second > n) break;
            value = positive_mod(value + sign * (long)partitions[(usz)(n - second)], modulus);
        }
        if (value == 0) return n;
        partitions[(usz)n] = (u32)value;
    }
    return -1;
}
