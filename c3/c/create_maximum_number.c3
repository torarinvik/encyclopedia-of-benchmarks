module create_maximum_number;

const usz MAX_SOURCE_LENGTH = 6;
const usz MAX_INPUT_LENGTH = 16;
const usz MAX_OUTPUT_LENGTH = 12;

struct Sequence {
    char[MAX_OUTPUT_LENGTH] values;
    usz length;
}

fn Sequence maximum_subsequence(long* source, usz length, usz requested) {
    char[MAX_SOURCE_LENGTH] stack;
    usz stack_length = 0;
    usz deletions = length - requested;
    for (usz i = 0; i < length; ++i) {
        char digit = (char)source[i];
        while (deletions > 0 && stack_length > 0 && stack[stack_length - 1] < digit) {
            --stack_length;
            --deletions;
        }
        stack[stack_length++] = digit;
    }
    stack_length -= deletions;
    Sequence selected;
    selected.length = stack_length;
    for (usz i = 0; i < stack_length; ++i) selected.values[i] = stack[i];
    return selected;
}

fn int compare_suffix(Sequence* first, usz i, Sequence* second, usz j) {
    while (i < first.length && j < second.length) {
        if (first.values[i] != second.values[j])
            return first.values[i] > second.values[j] ? 1 : -1;
        ++i;
        ++j;
    }
    if (i == first.length && j == second.length) return 0;
    return i == first.length ? -1 : 1;
}

fn Sequence merge_sequences(Sequence* first, Sequence* second) {
    Sequence merged;
    merged.length = 0;
    usz i = 0;
    usz j = 0;
    while (i < first.length || j < second.length) {
        int order = compare_suffix(first, i, second, j);
        if (j == second.length || (i < first.length && order >= 0))
            merged.values[merged.length++] = first.values[i++];
        else
            merged.values[merged.length++] = second.values[j++];
    }
    return merged;
}

fn bool greater(Sequence* left, Sequence* right) {
    for (usz i = 0; i < left.length; ++i) {
        if (left.values[i] != right.values[i]) return left.values[i] > right.values[i];
    }
    return false;
}

fn long create_maximum_number(long* input, usz length, char* output, usz capacity)
        @export("create_maximum_number") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_SOURCE_LENGTH
        || input[1] < 0 || input[1] > (long)MAX_SOURCE_LENGTH) return -1;
    usz first_length = (usz)input[0];
    usz second_length = (usz)input[1];
    if (input[2] < 0 || input[2] > (long)(first_length + second_length)) return -1;
    usz requested = (usz)input[2];
    if (length != 3 + first_length + second_length) return -1;
    for (usz i = 0; i < first_length + second_length; ++i)
        if (input[3 + i] < 0 || input[3 + i] > 9) return -1;
    if (output == null || capacity < requested) return -2;

    long* first_source = &input[3];
    long* second_source = &input[3 + first_length];
    usz minimum_first = requested > second_length ? requested - second_length : 0;
    usz maximum_first = requested < first_length ? requested : first_length;
    Sequence best;
    best.length = 0;
    bool have_best = false;
    for (usz take_first = minimum_first; take_first <= maximum_first; ++take_first) {
        Sequence first = maximum_subsequence(first_source, first_length, take_first);
        Sequence second = maximum_subsequence(second_source, second_length, requested - take_first);
        Sequence candidate = merge_sequences(&first, &second);
        if (!have_best || greater(&candidate, &best)) {
            best = candidate;
            have_best = true;
        }
    }
    for (usz i = 0; i < requested; ++i) output[i] = best.values[i];
    return (long)requested;
}
