package abelian_sandpile_stabilization

import "core:c"

MAX_LENGTH :: 19
MAX_TOPPLES :: 1488

@(export)
abelian_sandpile_stabilization :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_LENGTH) do return -1
	rows_word := input[0]
	cols_word := input[1]
	if rows_word < 1 || rows_word > 4 || cols_word < 1 || cols_word > 4 do return -1
	rows := int(rows_word)
	cols := int(cols_word)
	cells := rows * cols
	if length != c.size_t(2 + cells) do return -1

	board: [16]i64 = {}
	for site in 0..<cells {
		height := input[2 + site]
		if height < 0 || height > 31 do return -1
		board[site] = height
	}

	queue: [16]int = {}
	queued: [16]bool = {}
	head := 0
	tail := 0
	queue_count := 0
	for site in 0..<cells {
		if board[site] >= 4 {
			queue[tail] = site
			tail = (tail + 1) % cells
			queue_count += 1
			queued[site] = true
		}
	}

	topples := 0
	for queue_count > 0 {
		site := queue[head]
		head = (head + 1) % cells
		queue_count -= 1
		queued[site] = false
		if board[site] < 4 do continue
		row := site / cols
		col := site % cols
		board[site] -= 4
		topples += 1
		if topples > MAX_TOPPLES do return -1

		if row > 0 {
			next := site - cols
			board[next] += 1
			if board[next] >= 4 && !queued[next] {
				queue[tail] = next; tail = (tail + 1) % cells; queue_count += 1; queued[next] = true
			}
		}
		if col + 1 < cols {
			next := site + 1
			board[next] += 1
			if board[next] >= 4 && !queued[next] {
				queue[tail] = next; tail = (tail + 1) % cells; queue_count += 1; queued[next] = true
			}
		}
		if row + 1 < rows {
			next := site + cols
			board[next] += 1
			if board[next] >= 4 && !queued[next] {
				queue[tail] = next; tail = (tail + 1) % cells; queue_count += 1; queued[next] = true
			}
		}
		if col > 0 {
			next := site - 1
			board[next] += 1
			if board[next] >= 4 && !queued[next] {
				queue[tail] = next; tail = (tail + 1) % cells; queue_count += 1; queued[next] = true
			}
		}
		if board[site] >= 4 && !queued[site] {
			queue[tail] = site; tail = (tail + 1) % cells; queue_count += 1; queued[site] = true
		}
	}

	result: i64 = 0
	place: i64 = 1
	for site in 0..<cells {
		result += board[site] * place
		place *= 4
	}
	return result
}
