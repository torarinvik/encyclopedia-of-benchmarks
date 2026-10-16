const MAX_NAMES: usize = 6000;
const MAX_NAME_LENGTH: i64 = 19;
const MAX_INPUT_LENGTH: usize = 100001;

fn compare_names(
    input: [*]const i64,
    offsets: *const [MAX_NAMES]usize,
    name_lengths: *const [MAX_NAMES]usize,
    first: usize,
    second: usize,
) i32 {
    const first_length = name_lengths.*[first];
    const second_length = name_lengths.*[second];
    const shared_length = @min(first_length, second_length);
    for (0..shared_length) |index| {
        const first_letter = input[offsets.*[first] + index];
        const second_letter = input[offsets.*[second] + index];
        if (first_letter < second_letter) return -1;
        if (first_letter > second_letter) return 1;
    }
    if (first_length < second_length) return -1;
    if (first_length > second_length) return 1;
    return 0;
}

export fn problem22(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const raw_count = input[0];
    if (raw_count < 0 or raw_count > @as(i64, MAX_NAMES)) return -1;
    const count: usize = @intCast(raw_count);
    var offsets = [_]usize{0} ** MAX_NAMES;
    var name_lengths = [_]usize{0} ** MAX_NAMES;
    var order = [_]usize{0} ** MAX_NAMES;
    var cursor: usize = 1;
    for (0..count) |name| {
        if (cursor >= length) return -1;
        const raw_name_length = input[cursor];
        cursor += 1;
        if (raw_name_length < 1 or raw_name_length > MAX_NAME_LENGTH) return -1;
        const name_length: usize = @intCast(raw_name_length);
        if (name_length > length - cursor) return -1;
        offsets[name] = cursor;
        name_lengths[name] = name_length;
        for (0..name_length) |letter| {
            const value = input[cursor + letter];
            if (value < 1 or value > 26) return -1;
        }
        cursor += name_length;
        order[name] = name;
    }
    if (cursor != length) return -1;

    const gaps = [_]usize{701, 301, 132, 57, 23, 10, 4, 1};
    for (gaps) |gap| {
        if (gap >= count) continue;
        for (gap..count) |index| {
            const key = order[index];
            var position = index;
            while (position >= gap and
                compare_names(input, &offsets, &name_lengths, order[position - gap], key) > 0)
            {
                order[position] = order[position - gap];
                position -= gap;
            }
            order[position] = key;
        }
    }

    var total: i64 = 0;
    for (0..count) |position| {
        const name = order[position];
        var score: i64 = 0;
        for (0..name_lengths[name]) |letter| {
            score += input[offsets[name] + letter];
        }
        total += @as(i64, @intCast(position + 1)) * score;
    }
    return total;
}
