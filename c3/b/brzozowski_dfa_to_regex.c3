module brzozowski_dfa_to_regex;

const usz MAX_STATES = 3;
const usz MAX_TEXT = 512;

fn usz text_length(char* text) {
    usz length = 0;
    while (text[length] != 0) length++;
    return length;
}

fn bool text_copy(char* output, char* source) {
    usz length = text_length(source);
    if (length >= MAX_TEXT) return false;
    for (usz i = 0; i <= length; i++) output[i] = source[i];
    return true;
}

fn int text_compare(char* left, char* right) {
    usz i = 0;
    while (left[i] != 0 && right[i] != 0) {
        if (left[i] < right[i]) return -1;
        if (left[i] > right[i]) return 1;
        i++;
    }
    if (left[i] == right[i]) return 0;
    return left[i] == 0 ? -1 : 1;
}

fn bool regex_union(char* output, char* left, char* right) {
    if (left[0] == '#' && left[1] == 0) return text_copy(output, right);
    if ((right[0] == '#' && right[1] == 0) || text_compare(left, right) == 0)
        return text_copy(output, left);
    char[MAX_TEXT] temporary;
    char* first = text_compare(left, right) < 0 ? left : right;
    char* second = first == left ? right : left;
    usz position = 0;
    temporary[position++] = '(';
    for (usz i = 0; i < text_length(first); i++) temporary[position++] = first[i];
    temporary[position++] = '|';
    for (usz i = 0; i < text_length(second); i++) temporary[position++] = second[i];
    temporary[position++] = ')';
    temporary[position] = 0;
    return text_copy(output, &temporary[0]);
}

fn bool regex_concat(char* output, char* left, char* right) {
    if ((left[0] == '#' && left[1] == 0) || (right[0] == '#' && right[1] == 0)) {
        char[2] empty = {'#', 0};
        return text_copy(output, &empty[0]);
    }
    if (left[0] == '@' && left[1] == 0) return text_copy(output, right);
    if (right[0] == '@' && right[1] == 0) return text_copy(output, left);
    char[MAX_TEXT] temporary;
    usz position = 0;
    temporary[position++] = '(';
    for (usz i = 0; i < text_length(left); i++) temporary[position++] = left[i];
    temporary[position++] = '.';
    for (usz i = 0; i < text_length(right); i++) temporary[position++] = right[i];
    temporary[position++] = ')';
    temporary[position] = 0;
    return text_copy(output, &temporary[0]);
}

fn bool regex_star(char* output, char* value) {
    if ((value[0] == '#' && value[1] == 0) || (value[0] == '@' && value[1] == 0)) {
        char[2] epsilon = {'@', 0};
        return text_copy(output, &epsilon[0]);
    }
    char[MAX_TEXT] temporary;
    usz position = 0;
    temporary[position++] = '(';
    for (usz i = 0; i < text_length(value); i++) temporary[position++] = value[i];
    temporary[position++] = ')';
    temporary[position++] = '*';
    temporary[position] = 0;
    return text_copy(output, &temporary[0]);
}

fn long brzozowski_dfa_to_regex(long* input, usz length, char* output,
                                  usz output_capacity) @export("brzozowski_dfa_to_regex") {
    if (input == null || length < 3 || length > 10) return -1;
    long n_value = input[0], start_value = input[1], accepting = input[2];
    if (n_value < 1 || n_value > (long)MAX_STATES || start_value < 0 || start_value >= n_value
        || accepting < 0 || accepting >= (1L << n_value) || length != 3 + 2 * (usz)n_value)
        return -1;
    usz n = (usz)n_value, start = (usz)start_value;
    char[MAX_STATES][MAX_STATES][MAX_TEXT] coefficient;
    char[MAX_STATES][MAX_TEXT] constant;
    for (usz state = 0; state < n; state++) {
        char[2] initial = {(accepting & (1L << state)) != 0 ? '@' : '#', 0};
        if (!text_copy(&constant[state][0], &initial[0])) return -1;
        for (usz target = 0; target < n; target++) {
            char[2] empty = {'#', 0};
            if (!text_copy(&coefficient[state][target][0], &empty[0])) return -1;
        }
        for (usz symbol = 0; symbol < 2; symbol++) {
            long next_value = input[3 + 2 * state + symbol];
            if (next_value < 0 || next_value >= n_value) return -1;
            usz next = (usz)next_value;
            char[2] label = {(char)('0' + symbol), 0};
            if (!regex_union(&coefficient[state][next][0], &coefficient[state][next][0], &label[0]))
                return -1;
        }
    }
    for (usz pivot = 0; pivot < n; pivot++) {
        if (pivot == start) continue;
        char[MAX_TEXT] loop;
        if (!regex_star(&loop[0], &coefficient[pivot][pivot][0])) return -1;
        for (usz source = 0; source < n; source++) {
            if (source == pivot) continue;
            char[MAX_TEXT] prefix;
            if (!regex_concat(&prefix[0], &coefficient[source][pivot][0], &loop[0])) return -1;
            for (usz target = 0; target < n; target++) {
                if (target == pivot) continue;
                char[MAX_TEXT] through;
                if (!regex_concat(&through[0], &prefix[0], &coefficient[pivot][target][0])
                    || !regex_union(&coefficient[source][target][0],
                                    &coefficient[source][target][0], &through[0])) return -1;
            }
            char[MAX_TEXT] through_constant;
            if (!regex_concat(&through_constant[0], &prefix[0], &constant[pivot][0])
                || !regex_union(&constant[source][0], &constant[source][0], &through_constant[0]))
                return -1;
        }
    }
    char[MAX_TEXT] loop, answer;
    if (!regex_star(&loop[0], &coefficient[start][start][0])
        || !regex_concat(&answer[0], &loop[0], &constant[start][0])) return -1;
    usz result_length = text_length(&answer[0]);
    if (result_length > 270) return -1;
    if (output == null || output_capacity < result_length) return -2;
    for (usz i = 0; i < result_length; i++) output[i] = answer[i];
    return (long)result_length;
}
