module suffix_array;

const usz MAX_TEXT_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 65;

fn bool pair_less(usz left, usz right, long* rank, usz length, usz step) {
    if (rank[left] != rank[right]) return rank[left] < rank[right];
    long left_second = if (left + step < length) then rank[left + step] else -1;
    long right_second = if (right + step < length) then rank[right + step] else -1;
    return left_second < right_second;
}

fn long suffix_array(long* values, usz length, char* output, usz output_capacity)
    @export("suffix_array") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = values[0];
    if (count_value < 0 || count_value > (long)MAX_TEXT_LENGTH) return -1;
    usz count = (usz)count_value;
    if (length != 1 + count) return -1;
    for (usz i = 0; i < count; i += 1)
        if (values[1 + i] < 0 || values[1 + i] > 127) return -1;

    usz output_bytes = count * 8;
    if (output == null || output_capacity < output_bytes) return -2;
    if (count == 0) return 0;

    usz[MAX_TEXT_LENGTH] suffixes;
    long[MAX_TEXT_LENGTH] rank;
    long[MAX_TEXT_LENGTH] next_rank;
    for (usz i = 0; i < count; i += 1) {
        suffixes[i] = i;
        rank[i] = values[1 + i];
    }

    for (usz step = 1; step < count; step *= 2) {
        for (usz i = 1; i < count; i += 1) {
            usz key = suffixes[i];
            usz position = i;
            while (position > 0 && pair_less(key, suffixes[position - 1], &rank[0], count, step)) {
                suffixes[position] = suffixes[position - 1];
                position -= 1;
            }
            suffixes[position] = key;
        }
        next_rank[suffixes[0]] = 0;
        for (usz i = 1; i < count; i += 1) {
            usz previous = suffixes[i - 1];
            usz current = suffixes[i];
            long previous_second = if (previous + step < count) then rank[previous + step] else -1;
            long current_second = if (current + step < count) then rank[current + step] else -1;
            long rank_increment = if (rank[previous] == rank[current] && previous_second == current_second) then 0 else 1;
            next_rank[current] = next_rank[previous] + rank_increment;
        }
        for (usz i = 0; i < count; i += 1) rank[i] = next_rank[i];
        if (rank[suffixes[count - 1]] == (long)count - 1) break;
    }

    for (usz i = 0; i < count; i += 1) {
        ulong bits = (ulong)suffixes[i];
        for (usz byte = 0; byte < 8; byte += 1)
            output[i * 8 + byte] = (char)((bits >> (byte * 8)) & 255);
    }
    return (long)output_bytes;
}
