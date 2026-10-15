const MorseCode = [26]u8{ 1,8,10,4,0,2,6,0,0,7,5,4,3,2,7,6,13,2,0,1,1,1,3,9,11,12 };
const MorseLength = [26]usize{ 2,4,4,3,1,4,3,4,2,4,3,4,2,2,3,4,4,3,3,1,3,4,3,4,4,4 };
const MorseSymbols = [3]u8{ '.', '-', 'x' };

fn makeKeyedAlphabet(input: [*c]const i64, key_start: usize, key_length: usize) [26]u8 {
    var keyed: [26]u8 = undefined;
    var seen: [26]bool = @splat(false);
    var count: usize = 0;
    for (0..key_length) |index| {
        var value = input[key_start + index];
        if (value >= 'a' and value <= 'z') value -= 32;
        const letter: usize = @intCast(value - 'A');
        if (!seen[letter]) { seen[letter] = true; keyed[count] = @intCast(value); count += 1; }
    }
    for (0..26) |letter| {
        if (!seen[letter]) { keyed[count] = @intCast('A' + letter); count += 1; }
    }
    return keyed;
}

fn morseLetter(morse: []const u8) ?u8 {
    if (morse.len == 0 or morse.len > 4) return null;
    var code: u8 = 0;
    for (morse) |symbol| code = code * 2 + @as(u8, @intFromBool(symbol == '-'));
    for (0..26) |letter| {
        if (MorseLength[letter] == morse.len and MorseCode[letter] == code) return @intCast('A' + letter);
    }
    return null;
}

export fn fractionated_morse_cipher(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > 323) return -1;
    const mode = input[0];
    const text_value = input[1];
    const key_value = input[2];
    if ((mode != 0 and mode != 1) or text_value < 0 or text_value > 256 or key_value < 0 or key_value > 64) return -1;
    const text_length: usize = @intCast(text_value);
    const key_length: usize = @intCast(key_value);
    if (length != 3 + text_length + key_length) return -1;
    const key_start = 3 + text_length;
    for (0..key_length) |index| {
        const value = input[key_start + index];
        if (!((value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z'))) return -1;
    }
    for (0..text_length) |index| {
        const value = input[3 + index];
        if (mode == 0) {
            if (value != ' ' and !((value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z'))) return -1;
        } else if (value < 'A' or value > 'Z') return -1;
    }
    const keyed = makeKeyedAlphabet(input, key_start, key_length);
    var result: [800]u8 = undefined;
    var result_length: usize = 0;
    if (mode == 0) {
        var morse: [1300]u8 = undefined;
        var morse_length: usize = 0;
        for (0..text_length) |index| {
            if (index != 0) { morse[morse_length] = 'x'; morse_length += 1; }
            var value = input[3 + index];
            if (value == ' ') continue;
            if (value >= 'a' and value <= 'z') value -= 32;
            const letter: usize = @intCast(value - 'A');
            for (0..MorseLength[letter]) |bit| {
                const mask: u8 = @as(u8, 1) << @intCast(MorseLength[letter] - bit - 1);
                morse[morse_length] = if ((MorseCode[letter] & mask) != 0) '-' else '.';
                morse_length += 1;
            }
        }
        const padding = 3 - morse_length % 3;
        for (0..padding) |_| { morse[morse_length] = 'x'; morse_length += 1; }
        for (0..morse_length / 3) |chunk| {
            var trigram: usize = 0;
            for (0..3) |offset| {
                const symbol = morse[chunk * 3 + offset];
                trigram = trigram * 3 + (if (symbol == '.') @as(usize, 0) else if (symbol == '-') 1 else 2);
            }
            if (trigram < 26) { result[result_length] = keyed[trigram]; result_length += 1; }
        }
    } else {
        var morse: [1300]u8 = undefined;
        var morse_length: usize = 0;
        for (0..text_length) |index| {
            var trigram: usize = 0;
            while (trigram < 26 and @as(i64, @intCast(keyed[trigram])) != input[3 + index]) : (trigram += 1) {}
            if (trigram == 26) return -1;
            morse[morse_length] = MorseSymbols[trigram / 9];
            morse[morse_length + 1] = MorseSymbols[(trigram / 3) % 3];
            morse[morse_length + 2] = MorseSymbols[trigram % 3];
            morse_length += 3;
        }
        var segment_start: usize = 0;
        for (0..morse_length + 1) |index| {
            if (index != morse_length and morse[index] != 'x') continue;
            const segment_length = index - segment_start;
            if (segment_length == 0) { result[result_length] = ' '; result_length += 1; }
            else if (morseLetter(morse[segment_start..index])) |letter| { result[result_length] = letter; result_length += 1; }
            else return -1;
            segment_start = index + 1;
        }
        var first: usize = 0;
        while (first < result_length and result[first] == ' ') : (first += 1) {}
        while (result_length > first and result[result_length - 1] == ' ') result_length -= 1;
        if (first > 0) {
            for (0..result_length - first) |offset| result[offset] = result[first + offset];
            result_length -= first;
        }
    }
    if (output_capacity < result_length or (result_length != 0 and output == null)) return -2;
    for (0..result_length) |index| output[index] = result[index];
    return @intCast(result_length);
}
