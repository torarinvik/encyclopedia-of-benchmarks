module josephus_batched_small_k;

const long MAX_FRAMES = 1024;

long josephus_batched_small_k(long* values, usz length) @export("josephus_batched_small_k") {
    if (values == null || length != 2) return -1;
    long n0 = values[0], k = values[1];
    if (n0 < 1 || n0 > 1000000 || k < 1 || k > 32) return -1;
    if (n0 == 1) return 0;
    if (k == 1) return n0 - 1;
    long frames[1024];
    usz depth = 0;
    long n = n0;
    while (n > 1) {
        if (depth == 1024) return -1;
        frames[depth] = n; depth++;
        if (n < k) n--;
        else n -= n / k;
    }
    long survivor = 0;
    while (depth > 0) {
        depth--;
        long m = frames[depth];
        if (m < k) survivor = (survivor + k) % m;
        else {
            survivor -= m % k;
            if (survivor < 0) survivor += m;
            else survivor += survivor / (k - 1);
        }
    }
    return survivor;
}
