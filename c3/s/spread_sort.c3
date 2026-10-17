module spread_sort;

const MAX_LENGTH = 128;
const INSERTION_THRESHOLD = 16;
const MAX_BUCKETS = 8;
const BUCKET_STRIDE = 128;

fn void spread_sort_segment(int* values, usz length) {
    if (length < 2) return;
    if (length <= INSERTION_THRESHOLD) {
        for (usz index = 1; index < length; index++) {
            int key = values[index];
            usz position = index;
            while (position > 0 && values[position - 1] > key) {
                values[position] = values[position - 1];
                position--;
            }
            values[position] = key;
        }
        return;
    }

    int minimum = values[0];
    int maximum = values[0];
    for (usz index = 1; index < length; index++) {
        if (values[index] < minimum) minimum = values[index];
        if (values[index] > maximum) maximum = values[index];
    }
    if (minimum == maximum) return;

    usz bucket_count = length / INSERTION_THRESHOLD;
    if (bucket_count < 2) bucket_count = 2;
    usz middle_bucket = bucket_count / 2;
    int bucket_values[MAX_BUCKETS * BUCKET_STRIDE];
    usz bucket_sizes[MAX_BUCKETS];
    for (usz bucket = 0; bucket < MAX_BUCKETS; bucket++) bucket_sizes[bucket] = 0;

    for (usz index = 0; index < length; index++) {
        usz bucket = values[index] == minimum ? 0 : middle_bucket;
        bucket_values[bucket * BUCKET_STRIDE + bucket_sizes[bucket]] = values[index];
        bucket_sizes[bucket]++;
    }

    usz written = 0;
    for (usz bucket = 0; bucket < bucket_count; bucket++) {
        if (bucket_sizes[bucket] == 0) continue;
        spread_sort_segment(&bucket_values[bucket * BUCKET_STRIDE], bucket_sizes[bucket]);
        for (usz index = 0; index < bucket_sizes[bucket]; index++) {
            values[written] = bucket_values[bucket * BUCKET_STRIDE + index];
            written++;
        }
    }
}

fn long spread_sort(long* input, usz length, char* output, usz capacity) @export("spread_sort") {
    if (input == null || length > MAX_LENGTH) return -1;
    int values[MAX_LENGTH];
    for (usz index = 0; index < length; index++) {
        if (input[index] < -2147483648 || input[index] > 2147483647) return -1;
        values[index] = (int)input[index];
    }
    if (length == 0) return 0;

    usz output_bytes = length * 4;
    if (output == null || capacity < output_bytes) return -2;
    spread_sort_segment(values, length);
    for (usz index = 0; index < length; index++) {
        uint bits = (uint)values[index];
        for (usz byte = 0; byte < 4; byte++) {
            output[index * 4 + byte] = (char)(bits & 255);
            bits >>= 8;
        }
    }
    return (long)output_bytes;
}
