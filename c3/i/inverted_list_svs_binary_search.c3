module inverted_list_svs_binary_search;

const MIN_LISTS: usz = 2;
const MAX_LISTS: usz = 8;
const MAX_LIST_LENGTH: usz = 32;
const MAX_INPUT_LENGTH: usz = 266;
const BYTES_PER_VALUE: usz = 4;

fn void store_i32_le(char* output, usz position, long value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < BYTES_PER_VALUE; byte++)
        output[position + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long inverted_list_svs_binary_search(long* input, usz length, char* output, usz output_capacity)
    @export("inverted_list_svs_binary_search") {
    if (input == null || length < MIN_LISTS + 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < (long)MIN_LISTS || input[0] > (long)MAX_LISTS) return -1;
    usz count = (usz)input[0];
    usz[MAX_LISTS] starts, sizes, order;
    usz position = 1;
    for (usz list = 0; list < count; list++) {
        if (position >= length || input[position] < 0 || input[position] > (long)MAX_LIST_LENGTH) return -1;
        usz size = (usz)input[position++];
        if (size > length - position) return -1;
        starts[list] = position; sizes[list] = size; order[list] = list;
        for (usz i = 0; i < size; i++) {
            long value = input[position + i];
            if (value < -2147483648L || value > 2147483647L) return -1;
            if (i > 0 && input[position + i - 1] >= value) return -1;
        }
        position += size;
    }
    if (position != length) return -1;
    for (usz i = 1; i < count; i++) {
        usz key = order[i]; usz j = i;
        while (j > 0 && sizes[order[j - 1]] > sizes[key]) { order[j] = order[j - 1]; j--; }
        order[j] = key;
    }
    usz maximum_result = sizes[order[0]];
    if (output_capacity < maximum_result * BYTES_PER_VALUE || (maximum_result > 0 && output == null)) return -2;
    long[MAX_LIST_LENGTH] candidates;
    usz candidate_count = maximum_result;
    for (usz i = 0; i < candidate_count; i++) candidates[i] = input[starts[order[0]] + i];
    for (usz rank = 1; rank < count; rank++) {
        if (candidate_count == 0) break;
        usz list = order[rank], start = starts[list], size = sizes[list];
        usz cursor = 0, kept = 0;
        for (usz i = 0; i < candidate_count; i++) {
            long candidate = candidates[i]; usz low = cursor, high = size;
            while (low < high) {
                usz middle = low + (high - low) / 2;
                if (input[start + middle] < candidate) low = middle + 1;
                else high = middle;
            }
            if (low < size && input[start + low] == candidate) {
                candidates[kept++] = candidate; cursor = low + 1;
            } else cursor = low;
        }
        candidate_count = kept;
    }
    for (usz i = 0; i < candidate_count; i++) store_i32_le(output, i * BYTES_PER_VALUE, candidates[i]);
    return (long)candidate_count;
}
