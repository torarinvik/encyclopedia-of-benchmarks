module suffix_array_dc3;

const usz MAX_TEXT_LENGTH = 16;
const usz MAX_INPUT_LENGTH = 18;

fn long symbol_at(long* symbols, usz length, usz position) {
    return position < length ? symbols[position] : 0;
}

fn long sample_rank(long* ranks, usz length, usz position) {
    return position < length ? ranks[position] : -1;
}

fn int triple_compare(long* symbols, usz length, usz left, usz right) {
    for (usz offset = 0; offset < 3; offset++) {
        long a = symbol_at(symbols, length, left + offset);
        long b = symbol_at(symbols, length, right + offset);
        if (a != b) return a < b ? -1 : 1;
    }
    return 0;
}

fn int suffix_compare(long* symbols, usz length, usz left, usz right) {
    while (left < length && right < length) {
        if (symbols[left] != symbols[right]) return symbols[left] < symbols[right] ? -1 : 1;
        left++;
        right++;
    }
    if (left == length && right == length) return 0;
    return left == length ? -1 : 1;
}

fn int zero_pair_compare(long* symbols, long* ranks, usz length, usz left, usz right) {
    long a = symbol_at(symbols, length, left);
    long b = symbol_at(symbols, length, right);
    if (a != b) return a < b ? -1 : 1;
    a = sample_rank(ranks, length, left + 1);
    b = sample_rank(ranks, length, right + 1);
    if (a != b) return a < b ? -1 : 1;
    return 0;
}

fn int merge_compare(long* symbols, long* ranks, usz length, usz zero, usz sample) {
    long a = symbol_at(symbols, length, zero);
    long b = symbol_at(symbols, length, sample);
    if (a != b) return a < b ? -1 : 1;
    if (sample % 3 == 1) {
        a = sample_rank(ranks, length, zero + 1);
        b = sample_rank(ranks, length, sample + 1);
        if (a != b) return a < b ? -1 : 1;
    } else {
        a = symbol_at(symbols, length, zero + 1);
        b = symbol_at(symbols, length, sample + 1);
        if (a != b) return a < b ? -1 : 1;
        a = sample_rank(ranks, length, zero + 2);
        b = sample_rank(ranks, length, sample + 2);
        if (a != b) return a < b ? -1 : 1;
    }
    return 0;
}

fn void dc3(long* symbols, usz length, usz* suffixes) {
    if (length == 0) return;
    if (length <= 3) {
        for (usz i = 0; i < length; i++) suffixes[i] = i;
        for (usz i = 1; i < length; i++) {
            usz key = suffixes[i];
            usz position = i;
            while (position > 0 && suffix_compare(symbols, length, key, suffixes[position - 1]) < 0) {
                suffixes[position] = suffixes[position - 1];
                position--;
            }
            suffixes[position] = key;
        }
        return;
    }

    usz[MAX_TEXT_LENGTH] sample_positions = zeroed;
    usz sample_count = 0;
    for (usz i = 1; i < length; i++) {
        if (i % 3 != 0) { sample_positions[sample_count] = i; sample_count++; }
    }
    for (usz i = 1; i < sample_count; i++) {
        usz key = sample_positions[i];
        usz position = i;
        while (position > 0 && triple_compare(symbols, length, key, sample_positions[position - 1]) < 0) {
            sample_positions[position] = sample_positions[position - 1];
            position--;
        }
        sample_positions[position] = key;
    }

    long[MAX_TEXT_LENGTH] triple_ranks = zeroed;
    long next_rank = 0;
    for (usz i = 0; i < sample_count; i++) {
        if (i == 0 || triple_compare(symbols, length, sample_positions[i - 1], sample_positions[i]) != 0)
            next_rank++;
        triple_ranks[sample_positions[i]] = next_rank;
    }
    usz group_one_count = 0;
    for (usz i = 1; i < length; i += 3) group_one_count++;
    long[MAX_TEXT_LENGTH] reduced = zeroed;
    usz reduced_length = 0;
    for (usz i = 1; i < length; i += 3) { reduced[reduced_length] = triple_ranks[i]; reduced_length++; }
    reduced[reduced_length] = 0;
    reduced_length++;
    for (usz i = 2; i < length; i += 3) { reduced[reduced_length] = triple_ranks[i]; reduced_length++; }
    usz[MAX_TEXT_LENGTH] reduced_order = zeroed;
    dc3(&reduced[0], reduced_length, &reduced_order[0]);

    usz[MAX_TEXT_LENGTH] sample_order = zeroed;
    long[MAX_TEXT_LENGTH] ranks = zeroed;
    for (usz i = 0; i < length; i++) ranks[i] = -1;
    usz sample_order_count = 0;
    for (usz i = 0; i < reduced_length; i++) {
        usz reduced_position = reduced_order[i];
        if (reduced_position == group_one_count) continue;
        usz source_position = reduced_position < group_one_count
            ? 1 + 3 * reduced_position
            : 2 + 3 * (reduced_position - group_one_count - 1);
        sample_order[sample_order_count] = source_position;
        ranks[source_position] = (long)sample_order_count;
        sample_order_count++;
    }

    usz[MAX_TEXT_LENGTH] zero_positions = zeroed;
    usz zero_count = 0;
    for (usz i = 0; i < length; i += 3) { zero_positions[zero_count] = i; zero_count++; }
    for (usz i = 1; i < zero_count; i++) {
        usz key = zero_positions[i];
        usz position = i;
        while (position > 0 && zero_pair_compare(symbols, &ranks[0], length, key, zero_positions[position - 1]) < 0) {
            zero_positions[position] = zero_positions[position - 1];
            position--;
        }
        zero_positions[position] = key;
    }

    usz zi = 0, si = 0, oi = 0;
    while (zi < zero_count && si < sample_order_count) {
        usz zero = zero_positions[zi];
        usz sample = sample_order[si];
        if (merge_compare(symbols, &ranks[0], length, zero, sample) < 0) {
            suffixes[oi] = zero_positions[zi]; zi++;
        } else {
            suffixes[oi] = sample_order[si]; si++;
        }
        oi++;
    }
    while (zi < zero_count) { suffixes[oi] = zero_positions[zi]; zi++; oi++; }
    while (si < sample_order_count) { suffixes[oi] = sample_order[si]; si++; oi++; }
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long suffix_array_dc3(long* values, usz length, char* output, usz capacity)
        @export("suffix_array_dc3") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = values[0];
    if (count_value < 0 || count_value > 16) return -1;
    usz count = (usz)count_value;
    if (length != count + 1) return -1;
    for (usz i = 0; i < count; i++) if (values[i + 1] < 0 || values[i + 1] > 255) return -1;
    usz output_bytes = count * 8;
    if (output == null || capacity < output_bytes) return -2;
    if (count == 0) return 0;
    long[MAX_TEXT_LENGTH] symbols = zeroed;
    for (usz i = 0; i < count; i++) symbols[i] = values[i + 1] + 1;
    usz[MAX_TEXT_LENGTH] suffixes = zeroed;
    dc3(&symbols[0], count, &suffixes[0]);
    for (usz i = 0; i < count; i++) store_i64_le(output, i * 8, (long)suffixes[i]);
    return (long)output_bytes;
}
