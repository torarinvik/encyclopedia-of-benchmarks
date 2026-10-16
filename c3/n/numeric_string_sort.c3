module numeric_string_sort;

const MAX_ITEMS = 64;
const MAX_TOKEN_LENGTH = 32;
const MAX_INPUT_LENGTH = 2113;
const MAX_OUTPUT_LENGTH = 2111;

fn bool token_less(long* values, usz left_start, usz left_length,
                   usz right_start, usz right_length) {
    if (left_length != right_length) return left_length < right_length;
    for (usz i = 0; i < left_length; i++) {
        long a = values[left_start + i];
        long b = values[right_start + i];
        if (a != b) return a < b;
    }
    return false;
}

fn long numeric_string_sort(long* values, usz length, u8* output, usz output_capacity)
    @export("numeric_string_sort")
{
    if (values == null || length == 0 || length > MAX_INPUT_LENGTH + 1) return -1;
    if (values[0] < 0 || values[0] > MAX_ITEMS) return -1;
    usz count = (usz)values[0];
    usz starts[MAX_ITEMS];
    usz lengths[MAX_ITEMS];
    usz normalized_starts[MAX_ITEMS];
    usz normalized_lengths[MAX_ITEMS];
    usz order[MAX_ITEMS];
    usz cursor = 1;
    usz output_length = count == 0 ? 0 : count - 1;

    for (usz i = 0; i < count; i++) {
        if (cursor >= length) return -1;
        long raw_length = values[cursor];
        cursor++;
        if (raw_length < 1 || raw_length > MAX_TOKEN_LENGTH || (usz)raw_length > length - cursor) return -1;
        usz token_length = (usz)raw_length;
        usz start = cursor;
        for (usz j = 0; j < token_length; j++) {
            if (values[start + j] < '0' || values[start + j] > '9') return -1;
        }
        usz zeros = 0;
        while (zeros < token_length && values[start + zeros] == '0') zeros++;
        starts[i] = start;
        lengths[i] = token_length;
        normalized_starts[i] = start + zeros;
        normalized_lengths[i] = token_length - zeros;
        for (usz j = 0; j < i; j++) {
            if (normalized_lengths[j] != normalized_lengths[i]) continue;
            usz k = 0;
            while (k < normalized_lengths[i] && values[normalized_starts[j] + k] == values[normalized_starts[i] + k]) k++;
            if (k == normalized_lengths[i]) {
                if (lengths[j] != token_length) return -1;
                usz raw = 0;
                while (raw < token_length && values[starts[j] + raw] == values[start + raw]) raw++;
                if (raw != token_length) return -1;
            }
        }
        output_length += token_length;
        cursor += token_length;
        order[i] = i;
    }
    if (cursor != length || output_length > MAX_OUTPUT_LENGTH) return -1;

    for (usz i = 1; i < count; i++) {
        usz key = order[i];
        usz position = i;
        while (position > 0 && token_less(values, normalized_starts[key], normalized_lengths[key],
                                           normalized_starts[order[position - 1]], normalized_lengths[order[position - 1]])) {
            order[position] = order[position - 1];
            position--;
        }
        order[position] = key;
    }
    if ((output == null && output_length != 0) || output_capacity < output_length) return -2;
    usz written = 0;
    for (usz i = 0; i < count; i++) {
        if (i != 0) output[written++] = ' ';
        usz item = order[i];
        for (usz j = 0; j < lengths[item]; j++) output[written++] = (u8)values[starts[item] + j];
    }
    return (long)output_length;
}
