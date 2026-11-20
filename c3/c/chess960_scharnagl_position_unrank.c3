module chess960_scharnagl_position_unrank;

const usz MAX_POSITIONS = 960;
const usz MAX_INPUT_WORDS = 962;
const uint8[10] KNIGHT_FIRST = { 0, 0, 0, 0, 1, 1, 1, 2, 2, 3 };
const uint8[10] KNIGHT_SECOND = { 1, 2, 3, 4, 2, 3, 4, 3, 4, 4 };

fn void unrank_position(long identifier, uint8* board) {
	ulong remainder = (ulong)identifier;
	usz odd_bishop = (usz)(remainder % 4) * 2 + 1;
	remainder /= 4;
	usz even_bishop = (usz)(remainder % 4) * 2;
	remainder /= 4;
	usz queen_ordinal = (usz)(remainder % 6);
	usz knight_ordinal = (usz)(remainder / 6);
	for (usz file = 0; file < 8; file += 1) board[file] = 0;
	board[odd_bishop] = (uint8)'B';
	board[even_bishop] = (uint8)'B';
	usz[8] open_files;
	usz open_count = 0;
	for (usz file = 0; file < 8; file += 1) if (board[file] == 0) { open_files[open_count] = file; open_count += 1; }
	board[open_files[queen_ordinal]] = (uint8)'Q';
	open_count = 0;
	for (usz file = 0; file < 8; file += 1) if (board[file] == 0) { open_files[open_count] = file; open_count += 1; }
	board[open_files[KNIGHT_FIRST[knight_ordinal]]] = (uint8)'N';
	board[open_files[KNIGHT_SECOND[knight_ordinal]]] = (uint8)'N';
	uint8[3] final_pieces = { (uint8)'R', (uint8)'K', (uint8)'R' };
	usz next_piece = 0;
	for (usz file = 0; file < 8; file += 1) if (board[file] == 0) { board[file] = final_pieces[next_piece]; next_piece += 1; }
}

fn long chess960_scharnagl_position_unrank(long* input, usz length, uint8* output, usz capacity)
	@export("chess960_scharnagl_position_unrank") {
	if (input == null || length < 1 || length > MAX_INPUT_WORDS) return -1;
	long count_word = input[0];
	if (count_word < 0 || count_word > (long)MAX_POSITIONS || length != (usz)count_word + 1) return -1;
	usz count = (usz)count_word;
	for (usz item = 0; item < count; item += 1)
		if (input[item + 1] < 0 || input[item + 1] >= (long)MAX_POSITIONS) return -1;
	usz bytes = count * 8;
	if (bytes > 0 && (output == null || capacity < bytes)) return -2;
	for (usz item = 0; item < count; item += 1) {
		uint8[8] board;
		unrank_position(input[item + 1], &board[0]);
		for (usz file = 0; file < 8; file += 1) output[item * 8 + file] = board[file];
	}
	return (long)bytes;
}
