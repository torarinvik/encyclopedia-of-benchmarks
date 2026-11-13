module seidel_unweighted_apsp;

fn void distances(long* adjacency, usz n, long* result) {
    long[64] squared = zeroed, expanded = zeroed, coarse = zeroed;
    long[8] degree = zeroed;
    bool complete = true;
    for (usz i = 0; i < n; i++) {
        for (usz j = 0; j < n; j++) {
            degree[i] += adjacency[8 * i + j];
            if (i != j && adjacency[8 * i + j] == 0) complete = false;
            for (usz k = 0; k < n; k++)
                squared[8 * i + j] += adjacency[8 * i + k] * adjacency[8 * k + j];
        }
    }
    if (complete) {
        for (usz i = 0; i < n; i++)
            for (usz j = 0; j < n; j++) result[8 * i + j] = i != j ? 1 : 0;
        return;
    }
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j < n; j++)
            if (i != j && (adjacency[8 * i + j] != 0 || squared[8 * i + j] != 0)) expanded[8 * i + j] = 1;
    distances(&expanded[0], n, &coarse[0]);
    for (usz i = 0; i < n; i++) {
        for (usz j = 0; j < n; j++) {
            if (i == j) { result[8 * i + j] = 0; continue; }
            long neighbor_sum = 0;
            for (usz k = 0; k < n; k++) neighbor_sum += coarse[8 * i + k] * adjacency[8 * k + j];
            result[8 * i + j] = 2 * coarse[8 * i + j];
            if (neighbor_sum < coarse[8 * i + j] * degree[j]) result[8 * i + j]--;
        }
    }
}

fn long seidel_unweighted_apsp(long* input, usz length, uint8* output, usz capacity)
    @export("seidel_unweighted_apsp") {
    if (input == null || length < 2 || length > 66) return -1;
    if (input[0] < 1 || input[0] > 8) return -1;
    usz n = (usz)input[0];
    if (length != 1 + n * n) return -1;
    long[64] adjacency = zeroed, result = zeroed;
    for (usz i = 0; i < n; i++) {
        for (usz j = 0; j < n; j++) {
            long value = input[1 + i * n + j];
            if (value < 0 || value > 1 || (i == j && value != 0)) return -1;
            adjacency[8 * i + j] = value;
        }
    }
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j < i; j++) if (adjacency[8 * i + j] != adjacency[8 * j + i]) return -1;
    bool[8] seen = zeroed;
    usz[8] queue = zeroed;
    seen[0] = true;
    usz head = 0, tail = 1;
    while (head < tail) {
        usz vertex = queue[head++];
        for (usz other = 0; other < n; other++) {
            if (adjacency[8 * vertex + other] != 0 && !seen[other]) {
                seen[other] = true;
                queue[tail++] = other;
            }
        }
    }
    if (tail != n) return -1;
    usz bytes = 8 * n * n;
    if (output == null || capacity < bytes) return -2;
    distances(&adjacency[0], n, &result[0]);
    for (usz i = 0; i < n; i++) {
        for (usz j = 0; j < n; j++) {
            ulong bits = (ulong)result[8 * i + j];
            for (usz byte = 0; byte < 8; byte++) {
                output[8 * (i * n + j) + byte] = (uint8)(bits & 255ul);
                bits >>= 8;
            }
        }
    }
    return (long)bytes;
}
