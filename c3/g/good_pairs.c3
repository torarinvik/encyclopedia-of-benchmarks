module good_pairs;

const long MAX_N = 256;
const long VALUE_LIMIT = 1000000;

fn long good_pairs(long* packed, usz length) @export("good_pairs") {
    if (packed == null || length == 0 || length > 257) return -1;
    long n = packed[0];
    if (n < 0 || n > MAX_N || length != (usz)n + 1) return -1;
    for (long i = 0; i < n; i++)
        if (packed[i + 1] < -VALUE_LIMIT || packed[i + 1] > VALUE_LIMIT) return -1;
    long count = 0;
    for (long i = 0; i < n; i++)
        for (long j = i + 1; j < n; j++)
            if (packed[i + 1] == packed[j + 1]) count++;
    return count;
}
