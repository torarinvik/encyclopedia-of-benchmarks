module mo_2d_rectangle_frequency_square;

const usz MAX_N = 8;
const usz MAX_Q = 32;
const usz MAX_INPUT_LENGTH = 195;

fn bool query_before(usz a, usz b, usz* tops, usz* lefts, usz* bottoms,
                     usz* rights, usz* indices, usz block_size) {
    usz[4] a_blocks = {tops[a] / block_size, lefts[a] / block_size,
                       bottoms[a] / block_size, rights[a] / block_size};
    usz[4] b_blocks = {tops[b] / block_size, lefts[b] / block_size,
                       bottoms[b] / block_size, rights[b] / block_size};
    for (usz coordinate = 0; coordinate < 4; coordinate++) {
        if (a_blocks[coordinate] != b_blocks[coordinate])
            return a_blocks[coordinate] < b_blocks[coordinate];
    }
    usz[5] a_coordinates = {tops[a], lefts[a], bottoms[a], rights[a], indices[a]};
    usz[5] b_coordinates = {tops[b], lefts[b], bottoms[b], rights[b], indices[b]};
    for (usz coordinate = 0; coordinate < 5; coordinate++) {
        if (a_coordinates[coordinate] != b_coordinates[coordinate])
            return a_coordinates[coordinate] < b_coordinates[coordinate];
    }
    return false;
}

fn long add_value(long value, long* frequency, long sum_squares) {
    sum_squares += 2 * frequency[value] + 1;
    frequency[value] += 1;
    return sum_squares;
}

fn long remove_value(long value, long* frequency, long sum_squares) {
    sum_squares += 1 - 2 * frequency[value];
    frequency[value] -= 1;
    return sum_squares;
}

fn long mo_2d_rectangle_frequency_square(long* input, usz length)
    @export("mo_2d_rectangle_frequency_square") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    long q_value = input[1];
    if (n_value < 1 || n_value > MAX_N.long() || q_value < 0 || q_value > MAX_Q.long())
        return -1;

    usz n = n_value.usz();
    usz q = q_value.usz();
    usz matrix_length = n * n;
    if (length != 2 + matrix_length + 4 * q) return -1;

    long[64] matrix = zeroed;
    for (usz cell = 0; cell < matrix_length; cell++) {
        long value = input[2 + cell];
        if (value < 0 || value > 7) return -1;
        matrix[cell] = value;
    }

    usz[32] tops = zeroed;
    usz[32] lefts = zeroed;
    usz[32] bottoms = zeroed;
    usz[32] rights = zeroed;
    usz[32] indices = zeroed;
    usz[32] order = zeroed;
    usz query_offset = 2 + matrix_length;
    for (usz query = 0; query < q; query++) {
        long top_value = input[query_offset + 4 * query];
        long left_value = input[query_offset + 4 * query + 1];
        long bottom_value = input[query_offset + 4 * query + 2];
        long right_value = input[query_offset + 4 * query + 3];
        if (top_value < 0 || left_value < 0 || bottom_value < top_value ||
            right_value < left_value || bottom_value >= n_value || right_value >= n_value)
            return -1;
        tops[query] = top_value.usz();
        lefts[query] = left_value.usz();
        bottoms[query] = bottom_value.usz();
        rights[query] = right_value.usz();
        indices[query] = query;
        order[query] = query;
    }

    usz block_size = 0;
    usz n_fourth = n * n * n * n;
    for (usz candidate = 1; candidate <= n; candidate++) {
        usz candidate_fourth = candidate * candidate * candidate * candidate;
        if (q * candidate_fourth <= n_fourth) block_size = candidate;
    }
    if (block_size == 0) block_size = 1;

    for (usz query = 1; query < q; query++) {
        usz current = order[query];
        usz position = query;
        while (position > 0 && query_before(current, order[position - 1], &tops[0], &lefts[0],
                                              &bottoms[0], &rights[0], &indices[0], block_size)) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = current;
    }
    if (q == 0) return 0;

    long[8] frequency = zeroed;
    long sum_squares = 0;
    usz first = order[0];
    usz current_top = tops[first], current_left = lefts[first];
    usz current_bottom = bottoms[first], current_right = rights[first];
    for (usz row = current_top; row <= current_bottom; row++) {
        for (usz column = current_left; column <= current_right; column++)
            sum_squares = add_value(matrix[row * n + column], &frequency[0], sum_squares);
    }

    long[32] answers = zeroed;
    answers[indices[first]] = sum_squares;
    for (usz sorted = 1; sorted < q; sorted++) {
        usz target = order[sorted];
        while (current_top > tops[target]) {
            current_top -= 1;
            for (usz column = current_left; column <= current_right; column++)
                sum_squares = add_value(matrix[current_top * n + column], &frequency[0], sum_squares);
        }
        while (current_bottom < bottoms[target]) {
            current_bottom += 1;
            for (usz column = current_left; column <= current_right; column++)
                sum_squares = add_value(matrix[current_bottom * n + column], &frequency[0], sum_squares);
        }
        while (current_left > lefts[target]) {
            current_left -= 1;
            for (usz row = current_top; row <= current_bottom; row++)
                sum_squares = add_value(matrix[row * n + current_left], &frequency[0], sum_squares);
        }
        while (current_right < rights[target]) {
            current_right += 1;
            for (usz row = current_top; row <= current_bottom; row++)
                sum_squares = add_value(matrix[row * n + current_right], &frequency[0], sum_squares);
        }
        while (current_top < tops[target]) {
            for (usz column = current_left; column <= current_right; column++)
                sum_squares = remove_value(matrix[current_top * n + column], &frequency[0], sum_squares);
            current_top += 1;
        }
        while (current_bottom > bottoms[target]) {
            for (usz column = current_left; column <= current_right; column++)
                sum_squares = remove_value(matrix[current_bottom * n + column], &frequency[0], sum_squares);
            current_bottom -= 1;
        }
        while (current_left < lefts[target]) {
            for (usz row = current_top; row <= current_bottom; row++)
                sum_squares = remove_value(matrix[row * n + current_left], &frequency[0], sum_squares);
            current_left += 1;
        }
        while (current_right > rights[target]) {
            for (usz row = current_top; row <= current_bottom; row++)
                sum_squares = remove_value(matrix[row * n + current_right], &frequency[0], sum_squares);
            current_right -= 1;
        }
        answers[indices[target]] = sum_squares;
    }

    long result = 0;
    for (usz query = 0; query < q; query++) result += (query + 1).long() * answers[query];
    return result;
}
