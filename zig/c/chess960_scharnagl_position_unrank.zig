const MAX_POSITIONS: usize = 960;
const MAX_INPUT_WORDS: usize = 962;
const KNIGHT_FIRST = [_]usize{ 0, 0, 0, 0, 1, 1, 1, 2, 2, 3 };
const KNIGHT_SECOND = [_]usize{ 1, 2, 3, 4, 2, 3, 4, 3, 4, 4 };

fn unrankPosition(identifier: i64) [8]u8 {
    var remainder: u64 = @intCast(identifier);
    const odd_bishop: usize = @as(usize, @intCast(remainder % 4)) * 2 + 1;
    remainder /= 4;
    const even_bishop: usize = @as(usize, @intCast(remainder % 4)) * 2;
    remainder /= 4;
    const queen_ordinal: usize = @intCast(remainder % 6);
    const knight_ordinal: usize = @intCast(remainder / 6);
    var board: [8]u8 = @splat(0);
    board[odd_bishop] = 'B';
    board[even_bishop] = 'B';
    var open_files: [8]usize = @splat(0);
    var open_count: usize = 0;
    for (0..8) |file| {
        if (board[file] == 0) { open_files[open_count] = file; open_count += 1; }
    }
    board[open_files[queen_ordinal]] = 'Q';
    open_count = 0;
    for (0..8) |file| {
        if (board[file] == 0) { open_files[open_count] = file; open_count += 1; }
    }
    board[open_files[KNIGHT_FIRST[knight_ordinal]]] = 'N';
    board[open_files[KNIGHT_SECOND[knight_ordinal]]] = 'N';
    const final_pieces = [_]u8{ 'R', 'K', 'R' };
    var next_piece: usize = 0;
    for (0..8) |file| {
        if (board[file] == 0) { board[file] = final_pieces[next_piece]; next_piece += 1; }
    }
    return board;
}

export fn chess960_scharnagl_position_unrank(input_ptr: ?[*]const i64, length: usize,
    output_ptr: ?[*]u8, capacity: usize) i64 {
    if (input_ptr == null or length < 1 or length > MAX_INPUT_WORDS) return -1;
    const input = input_ptr.?[0..length];
    const count_word = input[0];
    if (count_word < 0 or count_word > 960 or length != @as(usize, @intCast(count_word)) + 1) return -1;
    const count: usize = @intCast(count_word);
    for (input[1..]) |identifier| if (identifier < 0 or identifier >= 960) return -1;
    const bytes = count * 8;
    if (bytes > 0 and (output_ptr == null or capacity < bytes)) return -2;
    if (bytes == 0) return 0;
    const output = output_ptr.?[0..bytes];
    for (0..count) |item| {
        const board = unrankPosition(input[item + 1]);
        for (0..8) |file| output[item * 8 + file] = board[file];
    }
    return @intCast(bytes);
}
