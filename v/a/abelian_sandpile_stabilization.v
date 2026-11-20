module abelian_sandpile_stabilization

const max_length = 19
const max_topples = 1488

@[export: 'abelian_sandpile_stabilization']
pub fn abelian_sandpile_stabilization(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_length { return -1 }
		rows_word := input[0]
		cols_word := input[1]
		if rows_word < 1 || rows_word > 4 || cols_word < 1 || cols_word > 4 { return -1 }
		rows := int(rows_word)
		cols := int(cols_word)
		cells := rows * cols
		if length != usize(2 + cells) { return -1 }

		mut board := [16]i64{}
		for site in 0 .. cells {
			height := input[2 + site]
			if height < 0 || height > 31 { return -1 }
			board[site] = height
		}

		mut queue := [16]int{}
		mut queued := [16]bool{}
		mut head := 0
		mut tail := 0
		mut queue_count := 0
		for site in 0 .. cells {
			if board[site] >= 4 {
				queue[tail] = site
				tail = (tail + 1) % cells
				queue_count++
				queued[site] = true
			}
		}

		mut topples := 0
		for queue_count > 0 {
			site := queue[head]
			head = (head + 1) % cells
			queue_count--
			queued[site] = false
			if board[site] < 4 { continue }
			row := site / cols
			col := site % cols
			board[site] -= 4
			topples++
			if topples > max_topples { return -1 }

			if row > 0 {
				next := site - cols
				board[next]++
				if board[next] >= 4 && !queued[next] {
					queue[tail] = next; tail = (tail + 1) % cells; queue_count++; queued[next] = true
				}
			}
			if col + 1 < cols {
				next := site + 1
				board[next]++
				if board[next] >= 4 && !queued[next] {
					queue[tail] = next; tail = (tail + 1) % cells; queue_count++; queued[next] = true
				}
			}
			if row + 1 < rows {
				next := site + cols
				board[next]++
				if board[next] >= 4 && !queued[next] {
					queue[tail] = next; tail = (tail + 1) % cells; queue_count++; queued[next] = true
				}
			}
			if col > 0 {
				next := site - 1
				board[next]++
				if board[next] >= 4 && !queued[next] {
					queue[tail] = next; tail = (tail + 1) % cells; queue_count++; queued[next] = true
				}
			}
			if board[site] >= 4 && !queued[site] {
				queue[tail] = site; tail = (tail + 1) % cells; queue_count++; queued[site] = true
			}
		}

		mut result := i64(0)
		mut place := i64(1)
		for site in 0 .. cells {
			result += board[site] * place
			place *= 4
		}
		return result
	}
}
