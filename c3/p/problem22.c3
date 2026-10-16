module problem22;

const usz MAX_NAMES = 6000;
const usz MAX_NAME_LENGTH = 19;
const usz MAX_INPUT_LENGTH = 100001;

fn int compare_names(long* input, usz* offsets, usz* name_lengths, usz first, usz second) {
    usz first_length = name_lengths[first];
    usz second_length = name_lengths[second];
    usz shared_length = first_length < second_length ? first_length : second_length;
    for (usz index = 0; index < shared_length; index++) {
        long first_letter = input[offsets[first] + index];
        long second_letter = input[offsets[second] + index];
        if (first_letter < second_letter) return -1;
        if (first_letter > second_letter) return 1;
    }
    if (first_length < second_length) return -1;
    if (first_length > second_length) return 1;
    return 0;
}

fn long problem22(long* input, usz length) @export("problem22") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long raw_count = input[0];
    if (raw_count < 0 || raw_count > (long)MAX_NAMES) return -1;
    usz count = (usz)raw_count;
    usz[MAX_NAMES] offsets = {0};
    usz[MAX_NAMES] name_lengths = {0};
    usz[MAX_NAMES] order = {0};
    usz cursor = 1;
    for (usz name = 0; name < count; name++) {
        if (cursor >= length) return -1;
        long raw_name_length = input[cursor];
        cursor++;
        if (raw_name_length < 1 || raw_name_length > (long)MAX_NAME_LENGTH) return -1;
        usz name_length = (usz)raw_name_length;
        if (name_length > length - cursor) return -1;
        offsets[name] = cursor;
        name_lengths[name] = name_length;
        for (usz letter = 0; letter < name_length; letter++) {
            long value = input[cursor + letter];
            if (value < 1 || value > 26) return -1;
        }
        cursor += name_length;
        order[name] = name;
    }
    if (cursor != length) return -1;

    usz[8] gaps = {701, 301, 132, 57, 23, 10, 4, 1};
    for (usz gap_index = 0; gap_index < 8; gap_index++) {
        usz gap = gaps[gap_index];
        if (gap >= count) continue;
        for (usz index = gap; index < count; index++) {
            usz key = order[index];
            usz position = index;
            while (position >= gap && compare_names(input, &offsets[0], &name_lengths[0], order[position - gap], key) > 0) {
                order[position] = order[position - gap];
                position -= gap;
            }
            order[position] = key;
        }
    }

    long total = 0;
    for (usz position = 0; position < count; position++) {
        usz name = order[position];
        long score = 0;
        for (usz letter = 0; letter < name_lengths[name]; letter++) {
            score += input[offsets[name] + letter];
        }
        total += (long)(position + 1) * score;
    }
    return total;
}
