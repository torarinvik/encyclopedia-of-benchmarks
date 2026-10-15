/// Baconian cipher with explicit Java, Python, and Rust source dialects.
const max_payload = 1024;

fn pythonCodeForLetter(upper: i64) i64 {
    if (upper >= 65 and upper <= 73) return upper - 65;
    if (upper == 74) return 28;
    if (upper >= 75 and upper <= 85) return upper - 66;
    if (upper == 86) return 29;
    if (upper >= 87 and upper <= 90) return upper - 67;
    return -1;
}

fn pythonLetterForCode(code: i64) i64 {
    if (code >= 0 and code <= 8) return 97 + code;
    if (code == 28) return 106;
    if (code == 29) return 118;
    if (code >= 9 and code <= 19) return 97 + code + 1;
    if (code >= 20 and code <= 23) return 97 + code + 2;
    return -1;
}

fn decodeCode(values: [*]const i64, start: usize) i64 {
    var code: i64 = 0;
    for (0..5) |bit| code = (code << 1) | @as(i64, if (values[start + bit] == 'B') 1 else 0);
    return code;
}

fn writeCode(output: [*]u8, position: usize, code: i64) usize {
    var write = position;
    for (0..5) |offset| {
        const bit = 4 - offset;
        output[write] = if ((code >> @intCast(bit)) & 1 != 0) 'B' else 'A';
        write += 1;
    }
    return write;
}

fn pythonDecodeLength(values: [*]const i64, n: usize) ?usize {
    var words: usize = 0;
    var letters: usize = 0;
    var used: usize = 0;
    var code: i64 = 0;
    var in_word = false;
    for (0..n) |i| {
        const value = values[2 + i];
        if (value == ' ') {
            if (used != 0) return null;
            if (in_word) { words += 1; in_word = false; }
        } else {
            if (value != 'A' and value != 'B') return null;
            in_word = true;
            code = (code << 1) | @as(i64, if (value == 'B') 1 else 0);
            used += 1;
            if (used == 5) {
                if (pythonLetterForCode(code) < 0) return null;
                letters += 1;
                used = 0;
                code = 0;
            }
        }
    }
    if (used != 0) return null;
    if (in_word) words += 1;
    return letters + (if (words == 0) 0 else words - 1);
}

export fn baconian_cipher(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > max_payload + 2) return -1;
    const mode = values[0];
    const dialect = values[1];
    if ((mode != 0 and mode != 1) or dialect < 0 or dialect > 2) return -1;
    const n = length - 2;
    for (0..n) |i| if (values[2 + i] < 0 or values[2 + i] > 127) return -1;

    if (mode == 0) {
        for (0..n) |i| {
            const value = values[2 + i];
            const upper = if (value >= 97 and value <= 122) value - 32 else value;
            const is_letter = upper >= 65 and upper <= 90;
            if (dialect == 1 and value != ' ' and !is_letter) return -1;
            if (dialect == 2 and is_letter and upper > 88) return -1;
        }
    }

    var output_length: usize = 0;
    if (mode == 0) {
        for (0..n) |i| {
            const value = values[2 + i];
            const upper = if (value >= 97 and value <= 122) value - 32 else value;
            const is_letter = upper >= 65 and upper <= 90;
            if (dialect == 0) { if (is_letter) output_length += 5; }
            else if (dialect == 1) { if (value == ' ') output_length += 1 else if (is_letter) output_length += 5; }
            else { if (is_letter) output_length += 5 else output_length += 1; }
        }
    } else if (dialect == 0) {
        if (n % 5 != 0) return -1;
        for (0..n) |i| if (values[2 + i] != 'A' and values[2 + i] != 'B') return -1;
        for (0..(n / 5)) |group| if (decodeCode(values, 2 + 5 * group) > 25) return -1;
        output_length = n / 5;
    } else if (dialect == 1) {
        output_length = pythonDecodeLength(values, n) orelse return -1;
    } else output_length = (n + 4) / 5;
    if (output_capacity < output_length) return -2;

    var write: usize = 0;
    if (mode == 0) {
        for (0..n) |i| {
            const value = values[2 + i];
            const upper = if (value >= 97 and value <= 122) value - 32 else value;
            if (dialect == 0) {
                if (upper >= 65 and upper <= 90) write = writeCode(output, write, if (upper == 73) 9 else upper - 65);
            } else if (dialect == 1) {
                if (value == ' ') { output[write] = ' '; write += 1; }
                else write = writeCode(output, write, pythonCodeForLetter(upper));
            } else {
                if (upper >= 65 and upper <= 90) write = writeCode(output, write, upper - 65)
                else { output[write] = @intCast(value); write += 1; }
            }
        }
    } else if (dialect == 0) {
        for (0..(n / 5)) |group| {
            const code = decodeCode(values, 2 + 5 * group);
            output[write] = if (code == 8 or code == 9) 'I' else @intCast(65 + code);
            write += 1;
        }
    } else if (dialect == 1) {
        var i: usize = 0;
        var first_word = true;
        while (i < n) {
            while (i < n and values[2 + i] == ' ') i += 1;
            if (i == n) break;
            if (!first_word) { output[write] = ' '; write += 1; }
            first_word = false;
            while (i < n and values[2 + i] != ' ') {
                output[write] = @intCast(pythonLetterForCode(decodeCode(values, 2 + i)));
                write += 1;
                i += 5;
            }
        }
    } else {
        var i: usize = 0;
        while (i < n) {
            if (n - i < 5) { output[write] = ' '; write += 1; break; }
            var code: i64 = 0;
            var valid = true;
            for (0..5) |bit| {
                const value = values[2 + i + bit];
                if (value != 'A' and value != 'B') valid = false;
                code = (code << 1) | @as(i64, if (value == 'B') 1 else 0);
            }
            output[write] = if (valid and code < 24) @intCast(65 + code) else ' ';
            write += 1;
            i += 5;
        }
    }
    return @intCast(output_length);
}
