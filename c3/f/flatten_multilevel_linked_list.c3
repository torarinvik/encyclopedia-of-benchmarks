module flatten_multilevel_linked_list;

const MAX_LISTS: usz = 8;
const MAX_CHAIN_LENGTH: usz = 8;
const MAX_TOTAL_VALUES: usz = MAX_LISTS * MAX_CHAIN_LENGTH;
const MAX_INPUT_LENGTH: usz = 1 + MAX_LISTS * (1 + MAX_CHAIN_LENGTH);

fn usz merge_recursive(const long* left, usz left_length, usz left_index,
        const long* right, usz right_length, usz right_index,
        long* output, usz output_index) {
    if (left_index == left_length) {
        usz remaining = right_length - right_index;
        for (usz i = 0; i < remaining; i++) output[output_index + i] = right[right_index + i];
        return output_index + remaining;
    }
    if (right_index == right_length) {
        usz remaining = left_length - left_index;
        for (usz i = 0; i < remaining; i++) output[output_index + i] = left[left_index + i];
        return output_index + remaining;
    }
    if (left[left_index] < right[right_index]) {
        output[output_index] = left[left_index];
        return merge_recursive(left, left_length, left_index + 1, right, right_length,
            right_index, output, output_index + 1);
    }
    output[output_index] = right[right_index];
    return merge_recursive(left, left_length, left_index, right, right_length,
        right_index + 1, output, output_index + 1);
}

fn usz flatten_suffix(const long* lists, const usz* lengths, usz count, usz index, long* output) {
    usz row = index * MAX_CHAIN_LENGTH;
    if (index + 1 == count) {
        for (usz i = 0; i < lengths[index]; i++) output[i] = lists[row + i];
        return lengths[index];
    }
    long[MAX_TOTAL_VALUES] suffix;
    usz suffix_length = flatten_suffix(lists, lengths, count, index + 1, &suffix[0]);
    return merge_recursive(&lists[row], lengths[index], 0, &suffix[0], suffix_length, 0, output, 0);
}

fn void store_i64(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long flatten_multilevel_linked_list(long* values, usz length, char* output,
        usz output_capacity) @export("flatten_multilevel_linked_list") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 0 || values[0] > (long)MAX_LISTS) return -1;
    usz count = (usz)values[0];
    if (count == 0) return length == 1 ? 0 : -1;

    long[MAX_LISTS * MAX_CHAIN_LENGTH] lists;
    usz[MAX_LISTS] lengths;
    usz total = 0;
    usz cursor = 1;
    for (usz list = 0; list < count; list++) {
        if (cursor >= length || values[cursor] < 1 ||
                values[cursor] > (long)MAX_CHAIN_LENGTH) return -1;
        usz chain_length = (usz)values[cursor];
        cursor++;
        if (chain_length > length - cursor) return -1;
        lengths[list] = chain_length;
        usz row = list * MAX_CHAIN_LENGTH;
        for (usz item = 0; item < chain_length; item++) {
            long value = values[cursor];
            cursor++;
            if (value < -1000 || value > 1000 ||
                    (item > 0 && value < lists[row + item - 1])) return -1;
            lists[row + item] = value;
        }
        total += chain_length;
    }
    if (cursor != length) return -1;
    usz required = total * 8;
    if (output == null || output_capacity < required) return -2;

    long[MAX_TOTAL_VALUES] flattened;
    flatten_suffix(&lists[0], &lengths[0], count, 0, &flattened[0]);
    for (usz i = 0; i < total; i++) store_i64(flattened[i], output, 8 * i);
    return (long)total;
}
