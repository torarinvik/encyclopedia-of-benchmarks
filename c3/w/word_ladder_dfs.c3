module word_ladder_dfs;

const long MAX_WORDS = 8;
const long MAX_PATH_WORDS = MAX_WORDS + 1;
const long MAX_INPUT_LENGTH = 4 + MAX_WORDS;
const long MAX_OUTPUT_FIELDS = MAX_PATH_WORDS + MAX_WORDS + 2;

fn long power_of_26(usz exponent) {
    long result = 1;
    for (usz index = 0; index < exponent; index++) result *= 26;
    return result;
}

fn usz find_active_word(long* words, char* active, usz count, long candidate) {
    for (usz index = 0; index < count; index++) if (active[index] != 0 && words[index] == candidate) return index;
    return count;
}

fn bool backtrack(long current, long end, usz width, long* words, usz count,
                 char* active, long* path, usz* path_length) {
    if (current == end) return true;
    for (usz position = 0; position < width; position++) {
        long factor = power_of_26(width - position - 1);
        long digit = (current / factor) % 26;
        for (long replacement = 0; replacement < 26; replacement++) {
            long candidate = current + (replacement - digit) * factor;
            usz index = find_active_word(words, active, count, candidate);
            if (index == count) continue;
            active[index] = 0;
            path[(*path_length)++] = candidate;
            if (backtrack(candidate, end, width, words, count, active, path, path_length)) return true;
            (*path_length)--;
            active[index] = 1;
        }
    }
    return false;
}

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long word_ladder_dfs(long* input, usz length, char* output, usz capacity) @export("word_ladder_dfs") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long width_value = input[0], begin = input[1], end = input[2], count_value = input[3];
    if (width_value < 1 || width_value > 5 || count_value < 0 || count_value > MAX_WORDS ||
        length != 4 + (usz)count_value) return -1;
    usz width = (usz)width_value, count = (usz)count_value;
    long limit = power_of_26(width);
    if (begin < 0 || begin >= limit || end < 0 || end >= limit) return -1;
    long* words = &input[4];
    for (usz index = 0; index < count; index++) {
        if (words[index] < 0 || words[index] >= limit || (index > 0 && words[index - 1] >= words[index])) return -1;
    }
    char[MAX_WORDS] active;
    for (usz index = 0; index < count; index++) active[index] = 1;
    long[MAX_PATH_WORDS] path;
    usz path_length = 1;
    path[0] = begin;
    if (find_active_word(words, &active[0], count, end) != count) {
        if (!backtrack(begin, end, width, words, count, &active[0], &path[0], &path_length))
            path_length = 0;
    } else path_length = 0;

    long[MAX_OUTPUT_FIELDS] fields;
    usz field_count = 0;
    fields[field_count++] = (long)path_length;
    for (usz index = 0; index < path_length; index++) fields[field_count++] = path[index];
    usz remaining = 0;
    for (usz index = 0; index < count; index++) if (active[index] != 0) remaining++;
    fields[field_count++] = (long)remaining;
    for (usz index = 0; index < count; index++) if (active[index] != 0) fields[field_count++] = words[index];
    usz required = field_count * 8;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < field_count; index++) write_i64_le(output, index * 8, fields[index]);
    return (long)required;
}
