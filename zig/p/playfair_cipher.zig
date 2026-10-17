const MIN_PARSEABLE_INPUT_LENGTH: usize = 3;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 157;
const MAX_KEY_LENGTH: i64 = 25;
const MAX_TEXT_LENGTH: i64 = 128;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const LOW63_MASK: u64 = 0x7fffffffffffffff;
const ALPHABET = "ABCDEFGHIKLMNOPQRSTUVWXYZ";

export fn playfair_cipher(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < MIN_PARSEABLE_INPUT_LENGTH or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;

    const operation = input[0];
    const key_length_value = input[1];
    if (operation < 0 or operation > 1 or key_length_value < 0 or key_length_value > MAX_KEY_LENGTH) return -1;
    const key_length: usize = @intCast(key_length_value);
    const text_length_index = 2 + key_length;
    if (length <= text_length_index) return -1;
    const text_length_value = input[text_length_index];
    if (text_length_value < 0 or text_length_value > MAX_TEXT_LENGTH or @mod(text_length_value, 2) != 0) return -1;
    const text_length: usize = @intCast(text_length_value);
    const text_start = text_length_index + 1;
    if (length != text_start + text_length) return -1;

    var seen = [_]bool{false} ** 26;
    var square = [_]u8{0} ** 25;
    var square_length: usize = 0;
    for (0..key_length) |index| {
        const value = input[2 + index];
        if (value < 65 or value > 90 or value == 74) return -1;
        const letter: u8 = @intCast(value);
        const slot: usize = @intCast(letter - 'A');
        if (!seen[slot]) {
            seen[slot] = true;
            square[square_length] = letter;
            square_length += 1;
        }
    }
    for (ALPHABET) |letter| {
        const slot: usize = @intCast(letter - 'A');
        if (!seen[slot]) {
            seen[slot] = true;
            square[square_length] = letter;
            square_length += 1;
        }
    }

    var positions = [_]u8{0} ** 26;
    for (square, 0..) |letter, index| positions[@intCast(letter - 'A')] = @intCast(index);

    var previous: u8 = 0;
    for (0..text_length) |index| {
        const value = input[text_start + index];
        if (value < 65 or value > 90 or value == 74) return -1;
        const letter: u8 = @intCast(value);
        if (operation == 0 and index > 0 and letter == previous) return -1;
        previous = letter;
    }

    var hash: u64 = FNV_OFFSET_BASIS;
    const shift: i32 = if (operation == 0) 1 else -1;
    var index: usize = 0;
    while (index < text_length) : (index += 2) {
        const first: u8 = @intCast(input[text_start + index]);
        const second: u8 = @intCast(input[text_start + index + 1]);
        const position1: usize = positions[@intCast(first - 'A')];
        const position2: usize = positions[@intCast(second - 'A')];
        const row1 = position1 / 5;
        const column1 = position1 % 5;
        const row2 = position2 / 5;
        const column2 = position2 % 5;
        var result1: u8 = undefined;
        var result2: u8 = undefined;
        if (row1 == row2) {
            const next1: usize = @intCast(@mod(@as(i32, @intCast(column1)) + shift + 5, 5));
            const next2: usize = @intCast(@mod(@as(i32, @intCast(column2)) + shift + 5, 5));
            result1 = square[row1 * 5 + next1];
            result2 = square[row2 * 5 + next2];
        } else if (column1 == column2) {
            const next1: usize = @intCast(@mod(@as(i32, @intCast(row1)) + shift + 5, 5));
            const next2: usize = @intCast(@mod(@as(i32, @intCast(row2)) + shift + 5, 5));
            result1 = square[next1 * 5 + column1];
            result2 = square[next2 * 5 + column2];
        } else {
            result1 = square[row1 * 5 + column2];
            result2 = square[row2 * 5 + column1];
        }
        hash = (hash ^ result1) *% FNV_PRIME;
        hash = (hash ^ result2) *% FNV_PRIME;
    }
    return @intCast(hash & LOW63_MASK);
}
