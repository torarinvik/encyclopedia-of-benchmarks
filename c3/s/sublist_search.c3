module sublist_search;

const usz MAX_LIST_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 130;
const long MAX_VALUE = 2147483647;

fn long sublist_search(long* values, usz length) @export("sublist_search") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long main_count_value = values[0];
    long pattern_count_value = values[1];
    if (main_count_value < 0 || main_count_value > (long)MAX_LIST_LENGTH ||
        pattern_count_value < 0 || pattern_count_value > (long)MAX_LIST_LENGTH) return -1;
    usz main_count = (usz)main_count_value;
    usz pattern_count = (usz)pattern_count_value;
    if (length != 2 + main_count + pattern_count) return -1;
    for (usz i = 0; i < main_count + pattern_count; i += 1)
        if (values[2 + i] < 0 || values[2 + i] > MAX_VALUE) return -1;

    if (main_count == 0 || pattern_count == 0 || pattern_count > main_count) return 0;
    usz pattern_offset = 2 + main_count;
    for (usz start = 0; start + pattern_count <= main_count; start += 1) {
        usz matched = 0;
        while (matched < pattern_count && values[2 + start + matched] == values[pattern_offset + matched])
            matched += 1;
        if (matched == pattern_count) return 1;
    }
    return 0;
}
