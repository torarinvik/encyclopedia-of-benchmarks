package chess960_scharnagl_position_unrank

import "core:c"

KNIGHT_FIRST :: [10]int{0, 0, 0, 0, 1, 1, 1, 2, 2, 3}
KNIGHT_SECOND :: [10]int{1, 2, 3, 4, 2, 3, 4, 3, 4, 4}

unrank_position :: proc(identifier: i64) -> [8]u8 {
	remainder := u64(identifier)
	odd_bishop := int(remainder % 4) * 2 + 1
	remainder /= 4
	even_bishop := int(remainder % 4) * 2
	remainder /= 4
	queen_ordinal := int(remainder % 6)
	knight_ordinal := int(remainder / 6)
	board: [8]u8 = [8]u8{}
	board[odd_bishop] = u8('B')
	board[even_bishop] = u8('B')
	open_files: [8]int
	open_count := 0
	for file := 0; file < 8; file += 1 do if board[file] == 0 do { open_files[open_count] = file; open_count += 1 }
	board[open_files[queen_ordinal]] = u8('Q')
	open_count = 0
	for file := 0; file < 8; file += 1 do if board[file] == 0 do { open_files[open_count] = file; open_count += 1 }
	board[open_files[KNIGHT_FIRST[knight_ordinal]]] = u8('N')
	board[open_files[KNIGHT_SECOND[knight_ordinal]]] = u8('N')
	final_pieces := [3]u8{u8('R'), u8('K'), u8('R')}
	next_piece := 0
	for file := 0; file < 8; file += 1 do if board[file] == 0 do { board[file] = final_pieces[next_piece]; next_piece += 1 }
	return board
}

@(export)
chess960_scharnagl_position_unrank :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 962 do return -1
	count_word := input[0]
	if count_word < 0 || count_word > 960 || length != c.size_t(count_word + 1) do return -1
	count := int(count_word)
	for item := 0; item < count; item += 1 do
		if input[item + 1] < 0 || input[item + 1] >= 960 do return -1
	bytes := count * 8
	if bytes > 0 && (output == nil || capacity < c.size_t(bytes)) do return -2
	for item := 0; item < count; item += 1 {
		board := unrank_position(input[item + 1])
		for file := 0; file < 8; file += 1 do output[item * 8 + file] = board[file]
	}
	return i64(bytes)
}
