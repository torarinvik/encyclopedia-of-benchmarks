module monotonic_queue;

const ulong FNV_OFFSET = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;

fn ulong hash_i32(ulong hash, long value) {
    uint bits = (uint)(int)value;
    for (uint shift = 0; shift < 32; shift += 8) hash = (hash ^ (ulong)(uint8)(bits >> shift)) * FNV_PRIME;
    return hash;
}

fn long monotonic_queue(long* input, usz length) @export("monotonic_queue") {
    if (input == null || length < 2 || length > 4098) return -1;
    long n64 = input[0], window64 = input[1];
    if (n64 < 1 || n64 > 4096 || window64 < 1 || window64 > n64 || length != (usz)(n64 + 2)) return -1;
    usz n = (usz)n64, window = (usz)window64;
    for (usz i = 0; i < n; i++) if (input[2 + i] < -2147483648 || input[2 + i] > 2147483647) return -1;
    usz[4096] deque; usz head = 0, tail = 0; ulong hash = FNV_OFFSET;
    for (usz i = 0; i < n; i++) {
        while (head < tail && deque[head] + window <= i) head++;
        while (head < tail && input[2 + deque[tail - 1]] <= input[2 + i]) tail--;
        deque[tail++] = i;
        if (i + 1 >= window) hash = hash_i32(hash, input[2 + deque[head]]);
    }
    return (long)(hash & 0x7fffffffffffffff);
}
