module crossword_puzzle_solver

fn search(mut grid &i64, rows int, cols int, words &i64, lengths &int, order &int, depth int, word_count int) bool {
	if depth == word_count { return true }
	word := unsafe { order[depth] }
	n := unsafe { lengths[word] }
	for row in 0 .. rows {
		for col in 0 .. cols {
			for direction in 0 .. 2 {
				vertical := direction == 0
				if (vertical && row + n > rows) || (!vertical && col + n > cols) { continue }
				mut cells := [8]int{}
				mut added := [8]bool{}
				mut valid := true
				for i in 0 .. n {
					cell := if vertical { (row + i) * cols + col } else { row * cols + col + i }
					cells[i] = cell
					letter := unsafe { words[word * 8 + i] }
					value := unsafe { grid[cell] }
					if value != 0 && value != letter { valid = false }
				}
				if !valid { continue }
				for i in 0 .. n {
					unsafe {
						added[i] = grid[cells[i]] == 0
						grid[cells[i]] = words[word * 8 + i]
					}
				}
				if search(mut grid, rows, cols, words, lengths, order, depth + 1, word_count) { return true }
				for i in 0 .. n { if added[i] { unsafe { grid[cells[i]] = 0 } } }
			}
		}
	}
	return false
}

@[export: 'crossword_puzzle_solver']
pub fn crossword_puzzle_solver(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 3 { return -1 }
	unsafe {
		rv, cv, nv := input[0], input[1], input[2]
		if rv < 1 || rv > 8 || cv < 1 || cv > 8 || nv < 0 || nv > 8 { return -1 }
		rows, cols, word_count := int(rv), int(cv), int(nv)
		if length < usize(3 + rows * cols) { return -1 }
		mut grid := [64]i64{}
		for i in 0 .. rows * cols {
			value := input[3 + i]
			if value != 0 && value != -1 && (value < 65 || value > 90) { return -1 }
			grid[i] = value
		}
		mut words := [64]i64{}
		mut lengths := [8]int{}
		mut order := [8]int{}
		mut pos := 3 + rows * cols
		for w in 0 .. word_count {
			if usize(pos) >= length || input[pos] < 1 || input[pos] > 8 { return -1 }
			lengths[w] = int(input[pos])
			pos++
			if usize(lengths[w]) > length - usize(pos) { return -1 }
			for i in 0 .. lengths[w] {
				letter := input[pos]
				pos++
				if letter < 65 || letter > 90 { return -1 }
				words[w * 8 + i] = letter
			}
		}
		if usize(pos) != length { return -1 }
		for i in 0 .. word_count { order[i] = i }
		for i in 1 .. word_count {
			value := order[i]
			mut j := i
			for j > 0 && lengths[order[j - 1]] < lengths[value] { order[j] = order[j - 1]; j-- }
			order[j] = value
		}
		solved := search(mut grid[0], rows, cols, words[0], lengths[0], order[0], 0, word_count)
		required := (1 + rows * cols) * 8
		if output == nil || output_capacity < usize(required) { return -2 }
		for i in 0 .. 1 + rows * cols {
			mut value := i64(0)
			if i > 0 { value = grid[i - 1] }
			if i == 0 && solved { value = 1 }
			bits := u64(value)
			for b in 0 .. 8 { output[i * 8 + b] = u8((bits >> (b * 8)) & 255) }
		}
		return i64(required)
	}
}
