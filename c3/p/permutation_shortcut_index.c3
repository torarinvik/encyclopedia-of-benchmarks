module permutation_shortcut_index;

const usz MAX_N = 16;
const usz MAX_QUERIES = 16;
const usz MAX_INPUT = 52;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn bool marked(ulong bitmap, usz vertex) {
    return (bitmap & (1ul << vertex)) != 0;
}

fn long shortcut_inverse(usz target, usz n, usz* successor, ulong bitmap, usz* shortcuts) {
    usz marker = target;
    usz steps = 0;
    while (steps < n && !marked(bitmap, marker)) { marker = successor[marker]; steps += 1; }
    if (!marked(bitmap, marker)) {
        usz previous = target;
        usz current = successor[target];
        while (current != target) { previous = current; current = successor[current]; }
        return (long)previous;
    }
    usz rank = 0;
    for (usz vertex = 0; vertex < marker; vertex += 1) if (marked(bitmap, vertex)) rank += 1;
    usz current = shortcuts[rank];
    usz previous = current;
    current = successor[current];
    steps = 0;
    while (steps < n) {
        if (current == target) return (long)previous;
        previous = current;
        current = successor[current];
        steps += 1;
    }
    return -1;
}

fn long permutation_shortcut_index(long* input, usz length, char* output, usz capacity) @export("permutation_shortcut_index") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long n_raw = input[0], stride_raw = input[1];
    if (n_raw < 1 || n_raw > (long)MAX_N || stride_raw < 1 || stride_raw > (long)MAX_N) return -1;
    usz n = (usz)n_raw, stride = (usz)stride_raw;
    usz query_at = 2 + n;
    if (length <= query_at) return -1;
    long query_raw = input[query_at];
    if (query_raw < 0 || query_raw > (long)MAX_QUERIES || length != query_at + 1 + 2 * (usz)query_raw) return -1;
    usz query_count = (usz)query_raw;
    usz[16] successor = zeroed;
    bool[16] seen = zeroed;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        long value = input[2 + vertex];
        if (value < 1 || value > n_raw || seen[(usz)(value - 1)]) return -1;
        seen[(usz)(value - 1)] = true;
        successor[vertex] = (usz)(value - 1);
    }
    for (usz query = 0; query < query_count; query += 1) {
        long op = input[query_at + 1 + 2 * query];
        long index = input[query_at + 2 + 2 * query];
        if ((op != 0 && op != 1) || index < 1 || index > n_raw) return -1;
    }
    bool[16] visited = zeroed;
    usz[16] back_pointer = zeroed;
    ulong bitmap = 0;
    for (usz start = 0; start < n; start += 1) {
        if (visited[start]) continue;
        usz[16] cycle = zeroed;
        usz cycle_length = 0;
        usz current = start;
        while (!visited[current]) {
            visited[current] = true;
            cycle[cycle_length] = current;
            cycle_length += 1;
            current = successor[current];
        }
        if (cycle_length >= stride) {
            usz offset = 0;
            while (offset < cycle_length) {
                usz vertex = cycle[offset];
                bitmap |= 1ul << vertex;
                long back_offset = ((long)offset - (long)stride) % (long)cycle_length;
                if (back_offset < 0) back_offset += (long)cycle_length;
                back_pointer[vertex] = cycle[(usz)back_offset];
                offset += stride;
            }
        }
    }
    usz[16] shortcuts = zeroed;
    usz shortcut_count = 0;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        if (marked(bitmap, vertex)) { shortcuts[shortcut_count] = back_pointer[vertex]; shortcut_count += 1; }
    }
    long[16] answers = zeroed;
    for (usz query = 0; query < query_count; query += 1) {
        long op = input[query_at + 1 + 2 * query];
        usz target = (usz)(input[query_at + 2 + 2 * query] - 1);
        long answer = op == 0 ? (long)successor[target] : shortcut_inverse(target, n, &successor[0], bitmap, &shortcuts[0]);
        if (answer < 0) return -1;
        answers[query] = answer + 1;
    }
    usz bytes = query_count * 8;
    if (output == null || capacity < bytes) return -2;
    for (usz query = 0; query < query_count; query += 1) store_i64_le(output, query * 8, answers[query]);
    return (long)bytes;
}
