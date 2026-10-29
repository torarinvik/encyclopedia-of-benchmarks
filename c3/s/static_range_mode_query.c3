module static_range_mode_query;

const usz MAX_N = 32;
const usz MAX_Q = 16;
const usz MAX_BLOCKS = 6;
const usz MAX_INPUT_LENGTH = 66;

fn usz lower_bound_i64(long* values, usz count, long target) {
    usz begin = 0, end = count;
    while (begin < end) {
        usz middle = begin + (end - begin) / 2;
        if (values[middle] < target) begin = middle + 1;
        else end = middle;
    }
    return begin;
}

fn usz lower_bound_usz(usz* values, usz begin, usz end, usz target) {
    while (begin < end) {
        usz middle = begin + (end - begin) / 2;
        if (values[middle] < target) begin = middle + 1;
        else end = middle;
    }
    return begin;
}

fn usz range_frequency(usz* occurrences, usz* offsets, usz id, usz left, usz right) {
    usz begin = offsets[id], end = offsets[id + 1];
    return lower_bound_usz(occurrences, begin, end, right) -
           lower_bound_usz(occurrences, begin, end, left);
}

fn void write_i64(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (uint8)(bits >> (8 * byte));
}

fn long static_range_mode_query(long* input, usz length, uint8* output, usz output_capacity)
        @export("static_range_mode_query") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > 32 || q_value < 1 || q_value > 16) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 2 + n + 2 * q) return -1;
    for (usz index = 0; index < n; index++)
        if (input[2 + index] < 0 || input[2 + index] > 1000000000) return -1;
    for (usz query = 0; query < q; query++) {
        long left = input[2 + n + 2 * query], right = input[3 + n + 2 * query];
        if (left < 0 || right <= left || right > n_value) return -1;
    }
    if (output == null || output_capacity < 16 * q) return -2;

    long[MAX_N] sorted;
    long[MAX_N] unique_values;
    usz[MAX_N] compressed;
    usz[MAX_N] frequencies = zeroed;
    usz[MAX_N + 1] offsets = zeroed;
    usz[MAX_N] cursor = zeroed;
    usz[MAX_N] occurrences;
    usz[MAX_BLOCKS * MAX_BLOCKS] block_mode;
    for (usz index = 0; index < n; index++) {
        long value = input[2 + index];
        usz position = index;
        while (position > 0 && sorted[position - 1] > value) {
            sorted[position] = sorted[position - 1];
            position--;
        }
        sorted[position] = value;
    }
    usz distinct = 0;
    for (usz index = 0; index < n; index++) {
        if (distinct == 0 || sorted[index] != unique_values[distinct - 1])
            unique_values[distinct++] = sorted[index];
    }
    for (usz index = 0; index < n; index++) {
        usz id = lower_bound_i64(&unique_values[0], distinct, input[2 + index]);
        compressed[index] = id;
        frequencies[id]++;
    }
    for (usz id = 0; id < distinct; id++) offsets[id + 1] = offsets[id] + frequencies[id];
    for (usz id = 0; id < distinct; id++) cursor[id] = offsets[id];
    for (usz index = 0; index < n; index++) occurrences[cursor[compressed[index]]++] = index;

    usz block_size = 1;
    while (block_size * block_size < n) block_size++;
    usz block_count = (n + block_size - 1) / block_size;
    usz[MAX_N] frequency = zeroed;
    for (usz first = 0; first < block_count; first++) {
        for (usz id = 0; id < distinct; id++) frequency[id] = 0;
        usz best_id = 0, best_count = 0;
        for (usz last = first; last < block_count; last++) {
            usz begin = last * block_size, end = begin + block_size;
            if (end > n) end = n;
            for (usz index = begin; index < end; index++) {
                usz id = compressed[index];
                usz count = ++frequency[id];
                if (count > best_count || (count == best_count && id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
            block_mode[first * MAX_BLOCKS + last] = best_id;
        }
    }
    for (usz query = 0; query < q; query++) {
        usz left = (usz)input[2 + n + 2 * query];
        usz right = (usz)input[3 + n + 2 * query];
        usz first_full = (left + block_size - 1) / block_size;
        usz after_full = right / block_size;
        usz best_id = 0, best_count = 0;
        if (first_full < after_full) {
            best_id = block_mode[first_full * MAX_BLOCKS + after_full - 1];
            best_count = range_frequency(&occurrences[0], &offsets[0], best_id, left, right);
            usz span_start = first_full * block_size, span_end = after_full * block_size;
            for (usz index = left; index < span_start; index++) {
                usz id = compressed[index];
                usz count = range_frequency(&occurrences[0], &offsets[0], id, left, right);
                if (count > best_count || (count == best_count && id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
            for (usz index = span_end; index < right; index++) {
                usz id = compressed[index];
                usz count = range_frequency(&occurrences[0], &offsets[0], id, left, right);
                if (count > best_count || (count == best_count && id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
        } else {
            for (usz index = left; index < right; index++) {
                usz id = compressed[index];
                usz count = range_frequency(&occurrences[0], &offsets[0], id, left, right);
                if (count > best_count || (count == best_count && id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
        }
        write_i64(output, 16 * query, unique_values[best_id]);
        write_i64(output, 16 * query + 8, (long)best_count);
    }
    return (long)(16 * q);
}
