module solution42;

const usz MAX_INPUT_LENGTH = 16384;

fn bool is_triangular_score(long score) {
    for (long n = 1; n <= 100; n++) {
        if (score == n * (n + 1) / 2) return true;
    }
    return false;
}

fn long solution42(long* input, usz input_length) @export("solution42") {
    if (input_length > MAX_INPUT_LENGTH) return -1;
    if (input_length == 0) return 0;
    if (input == null) return -1;

    for (usz i = 0; i < input_length; i++) {
        if (input[i] < 0 || input[i] > 127) return -1;
    }

    usz first_line_length = 0;
    while (first_line_length < input_length && input[first_line_length] != 10 &&
           input[first_line_length] != 13) {
        first_line_length++;
    }

    long count = 0;
    usz token_start = 0;
    for (usz position = 0; position <= first_line_length; position++) {
        if (position == first_line_length || input[position] == ',') {
            usz start = token_start;
            usz end = position;
            while (start < end && input[start] == '"') start++;
            while (end > start && input[end - 1] == '"') end--;

            long score = 0;
            for (usz i = start; i < end; i++) score += input[i] - 64;
            if (is_triangular_score(score)) count++;
            token_start = position + 1;
        }
    }
    return count;
}
