module online_list_update_transpose;

const usz MAX_N = 8;
const usz MAX_REQUESTS = 32;
const usz MAX_INPUT = 42;
const usz MAX_OUTPUT_BYTES = 328;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long online_list_update_transpose(long* input, usz length, char* output, usz capacity)
        @export("online_list_update_transpose") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_raw = input[0], requests_raw = input[1];
    if (n_raw < 1 || n_raw > MAX_N.long() || requests_raw < 0 || requests_raw > MAX_REQUESTS.long()) return -1;
    usz n = n_raw.usz(), requests = requests_raw.usz();
    if (length != 2 + n + requests) return -1;
    int[MAX_N] order = zeroed;
    bool[MAX_N] seen = zeroed;
    for (usz i = 0; i < n; i += 1) {
        long item = input[2 + i];
        if (item < 0 || item >= n_raw || seen[item.usz()]) return -1;
        order[i] = item.int(); seen[item.usz()] = true;
    }
    long[MAX_REQUESTS] positions = zeroed;
    long total_cost = 0;
    for (usz request = 0; request < requests; request += 1) {
        long item_raw = input[2 + n + request];
        if (item_raw < 0 || item_raw >= n_raw) return -1;
        usz position = 0;
        while (position < n && order[position] != item_raw.int()) position += 1;
        if (position == n) return -1;
        positions[request] = (position + 1).long();
        total_cost += (position + 1).long();
        if (position > 0) {
            int previous = order[position - 1];
            order[position - 1] = order[position]; order[position] = previous;
            total_cost += 1;
        }
    }
    long[1 + MAX_N + MAX_REQUESTS] words = zeroed;
    words[0] = total_cost;
    for (usz i = 0; i < n; i += 1) words[1 + i] = order[i].long();
    for (usz i = 0; i < requests; i += 1) words[1 + n + i] = positions[i];
    usz output_bytes = 8 * (1 + n + requests);
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    for (usz word = 0; word < 1 + n + requests; word += 1) store_i64_le(&staged[0], 8 * word, words[word]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return output_bytes.long();
}
