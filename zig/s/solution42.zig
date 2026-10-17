const MAX_INPUT_LENGTH: usize = 16_384;

fn isTriangleScore(score: i64) bool {
    for (1..101) |n| {
        const wide_n: i64 = @intCast(n);
        if (wide_n * (wide_n + 1) / 2 == score) return true;
    }
    return false;
}

fn countFirstLine(input: [*c]const i64, length: usize) i64 {
    var line_end = length;
    for (0..length) |index| {
        if (input[index] == 13 or input[index] == 10) {
            line_end = index;
            break;
        }
    }
    var count: i64 = 0;
    var token_start: usize = 0;
    var position: usize = 0;
    while (position <= line_end) {
        if (position != line_end and input[position] != ',') {
            position += 1;
            continue;
        }
        var start = token_start;
        var finish = position;
        while (start < finish and input[start] == '"') start += 1;
        while (start < finish and input[finish - 1] == '"') finish -= 1;
        var score: i64 = 0;
        for (start..finish) |index| score += input[index] - 64;
        if (isTriangleScore(score)) count += 1;
        token_start = position + 1;
        position += 1;
    }
    return count;
}

export fn solution42(input: [*c]const i64, length: usize) i64 {
    if (length > MAX_INPUT_LENGTH) return -1;
    if (input == null) return if (length == 0) 0 else -1;
    if (length == 0) return 0;
    for (0..length) |index| {
        if (input[index] < 0 or input[index] > 127) return -1;
    }
    return countFirstLine(input, length);
}
