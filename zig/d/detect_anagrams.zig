const MAX_STRING_LENGTH: usize = 16;
const MAX_CANDIDATES: usize = 16;
const MAX_INPUT_LENGTH: usize = 290;

fn isAsciiLetter(value: i64) bool {
    return (value >= 65 and value <= 90) or (value >= 97 and value <= 122);
}

fn lowerAscii(value: i64) i64 {
    return if (value >= 65 and value <= 90) value + 32 else value;
}

export fn detect_anagrams(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const subject_length_value = values[0];
    if (subject_length_value < 0 or subject_length_value > MAX_STRING_LENGTH) return -1;
    const subject_length: usize = @intCast(subject_length_value);
    var position: usize = 1;
    var subject_counts: [26]usize = @splat(0);
    for (0..subject_length) |index| {
        const value = values[position + index];
        if (!isAsciiLetter(value)) return -1;
        const letter: usize = @intCast(lowerAscii(value) - 97);
        subject_counts[letter] += 1;
    }
    position += subject_length;
    if (position >= length) return -1;
    const candidate_count_value = values[position];
    if (candidate_count_value < 0 or candidate_count_value > MAX_CANDIDATES) return -1;
    const candidate_count: usize = @intCast(candidate_count_value);
    position += 1;

    var candidate_starts: [MAX_CANDIDATES]usize = undefined;
    var candidate_lengths: [MAX_CANDIDATES]usize = undefined;
    var selected: [MAX_CANDIDATES]bool = @splat(false);
    var match_count: usize = 0;
    var output_length: usize = 0;
    for (0..candidate_count) |candidate| {
        if (position >= length) return -1;
        const candidate_length_value = values[position];
        if (candidate_length_value < 0 or candidate_length_value > MAX_STRING_LENGTH) return -1;
        const candidate_length: usize = @intCast(candidate_length_value);
        position += 1;
        if (candidate_length > length - position) return -1;
        candidate_starts[candidate] = position;
        candidate_lengths[candidate] = candidate_length;
        var candidate_counts: [26]usize = @splat(0);
        var same_identity = candidate_length == subject_length;
        for (0..candidate_length) |index| {
            const value = values[position + index];
            if (!isAsciiLetter(value)) return -1;
            const letter: usize = @intCast(lowerAscii(value) - 97);
            candidate_counts[letter] += 1;
            if (same_identity and lowerAscii(value) != lowerAscii(values[1 + index])) same_identity = false;
        }
        var same_signature = true;
        for (0..26) |letter| {
            if (candidate_counts[letter] != subject_counts[letter]) same_signature = false;
        }
        if (same_signature and !same_identity) {
            selected[candidate] = true;
            match_count += 1;
            output_length += candidate_length + 1;
        }
        position += candidate_length;
    }
    if (position != length) return -1;
    const required = output_length + 1;
    if (output == null or capacity < required) return -2;
    const result = output.?[0..capacity];
    var written: usize = 0;
    for (0..candidate_count) |candidate| {
        if (selected[candidate]) {
            for (0..candidate_lengths[candidate]) |index| {
                result[written] = @intCast(values[candidate_starts[candidate] + index]);
                written += 1;
            }
            result[written] = '\n';
            written += 1;
        }
    }
    result[written] = 0;
    return @intCast(match_count);
}
