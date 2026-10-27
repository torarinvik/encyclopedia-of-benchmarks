module timestamp_list_update;

const usz MAX_N = 8;
const usz MAX_REQUESTS = 32;
const usz MAX_INPUT = 42;
const usz MAX_OUTPUT_BYTES = 328;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long timestamp_list_update(long* input, usz length, char* output, usz capacity)
        @export("timestamp_list_update") {
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
    int[MAX_REQUESTS] request_ids = zeroed;
    for (usz i = 0; i < requests; i += 1) {
        long item = input[2 + n + i];
        if (item < 0 || item >= n_raw) return -1;
        request_ids[i] = item.int();
    }
    int[MAX_N] last_request;
    for (usz i = 0; i < n; i += 1) last_request[i] = -1;
    long[MAX_REQUESTS] positions = zeroed;
    long total_cost = 0;
    for (usz time = 0; time < requests; time += 1) {
        int item = request_ids[time];
        usz position = 0;
        while (position < n && order[position] != item) position += 1;
        if (position == n) return -1;
        positions[time] = (position + 1).long();
        total_cost += (position + 1).long();
        if (last_request[item.usz()] >= 0) {
            for (usz target = 0; target < position; target += 1) {
                int candidate = order[target];
                usz occurrences = 0;
                for (usz t = last_request[item.usz()].usz() + 1; t < time; t += 1)
                    if (request_ids[t] == candidate) occurrences += 1;
                if (occurrences <= 1) {
                    for (usz shift = position; shift > target; shift -= 1) order[shift] = order[shift - 1];
                    order[target] = item;
                    break;
                }
            }
        }
        last_request[item.usz()] = time.int();
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
