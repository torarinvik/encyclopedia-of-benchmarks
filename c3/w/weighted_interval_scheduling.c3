module weighted_interval_scheduling;

const usz MAX_INTERVALS = 64;
const usz MAX_INPUT_LENGTH = 193;

fn long start_at(long* input, usz index) { return input[1 + index * 3]; }
fn long end_at(long* input, usz index) { return input[2 + index * 3]; }
fn long weight_at(long* input, usz index) { return input[3 + index * 3]; }

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}
fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long weighted_interval_scheduling(long* input, usz length, char* output, usz capacity)
    @export("weighted_interval_scheduling") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH || input[0] < 0 || input[0] > (long)MAX_INTERVALS) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 3 * n) return -1;
    for (usz i = 0; i < n; i++) {
        long start = start_at(input, i), end = end_at(input, i), weight = weight_at(input, i);
        if (start < -100000 || start > 100000 || end < -100000 || end > 100000 || start >= end || weight < 0 || weight > 1000000) return -1;
    }
    usz[64] order, predecessors, selected;
    long[65] dp = zeroed;
    for (usz i = 0; i < n; i++) order[i] = i;
    for (usz i = 1; i < n; i++) {
        usz key = order[i], j = i;
        while (j > 0 && end_at(input, order[j - 1]) > end_at(input, key)) { order[j] = order[j - 1]; j--; }
        order[j] = key;
    }
    for (usz j = 0; j < n; j++) {
        usz low = 0, high = n;
        while (low < high) {
            usz mid = low + (high - low) / 2;
            if (end_at(input, order[mid]) <= start_at(input, order[j])) low = mid + 1;
            else high = mid;
        }
        predecessors[j] = low;
        long include = weight_at(input, order[j]) + dp[low];
        dp[j + 1] = include > dp[j] ? include : dp[j];
    }
    usz selected_count = 0, current = n;
    while (current > 0) {
        usz j = current - 1;
        long include = weight_at(input, order[j]) + dp[predecessors[j]];
        if (include > dp[current - 1]) { selected[selected_count++] = order[j]; current = predecessors[j]; }
        else current--;
    }
    for (usz i = 0; i < selected_count / 2; i++) {
        usz temp = selected[i]; selected[i] = selected[selected_count - 1 - i]; selected[selected_count - 1 - i] = temp;
    }
    usz needed = 16 + 4 * selected_count;
    if (output == null || capacity < needed) return -2;
    put_i64_le(output, 0, dp[n]);
    put_i64_le(output, 8, (long)selected_count);
    for (usz i = 0; i < selected_count; i++) put_i32_le(output, 16 + 4 * i, (int)selected[i]);
    return (long)needed;
}
