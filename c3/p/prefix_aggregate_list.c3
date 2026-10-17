module prefix_aggregate_list;

const usz MAX_INITIAL_VALUES = 64;
const usz MAX_OPERATIONS = 64;
const usz MAX_LIVE_VALUES = 128;
const usz MAX_INPUT_LENGTH = 258;
const usz MAX_PARSEABLE_INPUT_LENGTH = 260;
const usz MAX_OUTPUT_BYTES = 512;
const long MAX_VALUE = 1000000;

fn long prefix_aggregate_list(long* input, usz length, char* output, usz capacity)
        @export("prefix_aggregate_list") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long initial_count_value = input[0];
    if (initial_count_value < 1 || initial_count_value > (long)MAX_INITIAL_VALUES) return -1;
    usz initial_count = (usz)initial_count_value;
    if (length < initial_count + 2) return -1;

    long[MAX_LIVE_VALUES] prefix = zeroed;
    for (usz i = 0; i < initial_count; i++) {
        long value = input[1 + i];
        if (value < -MAX_VALUE || value > MAX_VALUE) return -1;
        prefix[i] = value + (i == 0 ? 0 : prefix[i - 1]);
    }

    long operation_count_value = input[1 + initial_count];
    if (operation_count_value < 0 || operation_count_value > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)operation_count_value;
    usz live_count = initial_count;
    usz cursor = initial_count + 2;
    usz query_count = 0;
    char[MAX_OUTPUT_BYTES] encoded = zeroed;

    for (usz operation_index = 0; operation_index < operation_count; operation_index++) {
        if (cursor >= length) return -1;
        long operation = input[cursor];
        cursor++;
        if (operation == 0) {
            if (cursor >= length || live_count >= MAX_LIVE_VALUES) return -1;
            long value = input[cursor];
            cursor++;
            if (value < -MAX_VALUE || value > MAX_VALUE) return -1;
            prefix[live_count] = prefix[live_count - 1] + value;
            live_count++;
        } else if (operation == 1) {
            if (live_count <= 1) return -1;
            live_count--;
        } else if (operation == 2) {
            if (cursor + 1 >= length) return -1;
            long range_from = input[cursor];
            long range_to = input[cursor + 1];
            cursor += 2;
            if (range_from < 1 || range_to < range_from || range_to > (long)live_count) return -1;
            usz from_index = (usz)range_from;
            usz to_index = (usz)range_to;
            long result = prefix[to_index - 1] - (from_index == 1 ? 0 : prefix[from_index - 2]);
            ulong bits = (ulong)result;
            for (usz byte = 0; byte < 8; byte++) {
                encoded[8 * query_count + byte] = (char)(bits & 255);
                bits >>= 8;
            }
            query_count++;
        } else {
            return -1;
        }
    }

    if (cursor != length) return -1;
    usz output_bytes = 8 * query_count;
    if (output == null || capacity < output_bytes) return -2;
    for (usz i = 0; i < output_bytes; i++) output[i] = encoded[i];
    return (long)output_bytes;
}
