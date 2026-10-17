module reverse_k_group;

const usz MAX_N = 256;
const usz MAX_INPUT_LENGTH = 258;

fn void store_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long reverse_k_group(long* input, usz length, char* output, usz capacity) @export("reverse_k_group") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0], k_value = input[1];
    if (n_value < 0 || n_value > (long)MAX_N || k_value < 1 || k_value > (long)MAX_N) return -1;
    usz n = (usz)n_value, k = (usz)k_value;
    if (length != n + 2) return -1;
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;

    long[MAX_N] nodes;
    long[MAX_N + 1] next;
    long head = -1;
    for (usz i = 0; i < n; i++) {
        nodes[i] = input[i + 2];
        next[i] = -1;
        if (head < 0) head = (long)i;
        else {
            long tail = head;
            while (next[(usz)tail] >= 0) tail = next[(usz)tail];
            next[(usz)tail] = (long)i;
        }
    }
    usz remaining = 0;
    for (long node = head; node >= 0; node = next[(usz)node]) remaining++;
    usz dummy = MAX_N;
    next[dummy] = head;
    long previous = (long)dummy;
    while (remaining >= k) {
        long current = next[(usz)previous];
        long moved = next[(usz)current];
        for (usz step = 1; step < k; step++) {
            next[(usz)current] = next[(usz)moved];
            next[(usz)moved] = next[(usz)previous];
            next[(usz)previous] = moved;
            moved = next[(usz)current];
        }
        previous = current;
        remaining -= k;
    }

    long[MAX_N] result;
    usz index = 0;
    for (long node = next[dummy]; node >= 0; node = next[(usz)node]) result[index++] = nodes[(usz)node];
    for (usz i = 0; i < n; i++) store_i64_le(result[i], output, i * 8);
    return (long)output_bytes;
}
