module chess960_scharnagl_position_unrank

const knight_first = [10]int{0, 0, 0, 0, 1, 1, 1, 2, 2, 3}
const knight_second = [10]int{1, 2, 3, 4, 2, 3, 4, 3, 4, 4}

fn unrank_position(identifier i64) [8]u8 {
	mut remainder := u64(identifier)
	odd_bishop := int(remainder % 4) * 2 + 1
	remainder /= 4
	even_bishop := int(remainder % 4) * 2
	remainder /= 4
	queen_ordinal := int(remainder % 6)
	knight_ordinal := int(remainder / 6)
	mut board := [8]u8{}
	board[odd_bishop] = `B`
	board[even_bishop] = `B`
	mut open_files := [8]int{}
	mut open_count := 0
	for file in 0 .. 8 {
		if board[file] == 0 { open_files[open_count] = file; open_count++ }
	}
	board[open_files[queen_ordinal]] = `Q`
	open_count = 0
	for file in 0 .. 8 {
		if board[file] == 0 { open_files[open_count] = file; open_count++ }
	}
	board[open_files[knight_first[knight_ordinal]]] = `N`
	board[open_files[knight_second[knight_ordinal]]] = `N`
	final_pieces := [`R`, `K`, `R`]
	mut next_piece := 0
	for file in 0 .. 8 {
		if board[file] == 0 { board[file] = final_pieces[next_piece]; next_piece++ }
	}
	return board
}

@[export: 'chess960_scharnagl_position_unrank']
pub fn chess960_scharnagl_position_unrank(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 1 || length > 962 { return -1 }
	unsafe {
		count_word := input[0]
		if count_word < 0 || count_word > 960 || length != usize(count_word + 1) { return -1 }
		count := int(count_word)
		for item in 0 .. count { if input[item + 1] < 0 || input[item + 1] >= 960 { return -1 } }
		bytes := count * 8
		if bytes > 0 && (output == nil || capacity < usize(bytes)) { return -2 }
		for item in 0 .. count {
			board := unrank_position(input[item + 1])
			for file in 0 .. 8 { output[item * 8 + file] = board[file] }
		}
		return i64(bytes)
	}
}
