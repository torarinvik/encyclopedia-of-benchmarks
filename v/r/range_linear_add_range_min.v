module range_linear_add_range_min

const max_length = 64
const max_operations = 64
const max_input = 387
const block_width = 8
const max_blocks = 8
const checksum_offset = i64(8_000_000)

struct State {
mut:
	data [max_length]i64
	hull_x [max_length]i64
	hull_y [max_length]i64
	hull_count [max_blocks]int
	lazy_slope [max_blocks]i64
	lazy_intercept [max_blocks]i64
	n int
}

fn block_end(state &State, block int) int {
	return min((block + 1) * block_width, state.n)
}

fn rebuild(mut state State, block int) {
	base := block * block_width
	mut size := 0
	for x := base; x < block_end(state, block); x++ {
		for size >= 2 {
			p := base + size - 2
			q := base + size - 1
			cross := (state.hull_x[q] - state.hull_x[p]) * (state.data[x] - state.hull_y[p]) -
				(state.hull_y[q] - state.hull_y[p]) * (i64(x) - state.hull_x[p])
			if cross > 0 { break }
			size--
		}
		state.hull_x[base + size] = i64(x)
		state.hull_y[base + size] = state.data[x]
		size++
	}
	state.hull_count[block] = size
}

fn push_block(mut state State, block int) {
	start := block * block_width
	for i := start; i < block_end(state, block); i++ {
		state.data[i] += state.lazy_slope[block] * i64(i) + state.lazy_intercept[block]
	}
	state.lazy_slope[block] = 0
	state.lazy_intercept[block] = 0
}

fn block_min(state &State, block int) i64 {
	base := block * block_width
	mut low := 0
	mut high := state.hull_count[block] - 1
	for low < high {
		middle := low + (high - low) / 2
		left := state.hull_y[base + middle] + state.lazy_slope[block] * state.hull_x[base + middle]
		right := state.hull_y[base + middle + 1] + state.lazy_slope[block] * state.hull_x[base + middle + 1]
		if left <= right { high = middle } else { low = middle + 1 }
	}
	return state.hull_y[base + low] + state.lazy_slope[block] * state.hull_x[base + low] + state.lazy_intercept[block]
}

fn update(mut state State, left int, right int, slope i64, intercept i64) {
	mut position := left
	for position < right {
		block := position / block_width
		start := block * block_width
		finish := block_end(state, block)
		if position == start && finish <= right {
			state.lazy_slope[block] += slope
			state.lazy_intercept[block] += intercept
			position = finish
		} else {
			push_block(mut state, block)
			stop := min(finish, right)
			for i := position; i < stop; i++ { state.data[i] += slope * i64(i) + intercept }
			rebuild(mut state, block)
			position = stop
		}
	}
}

fn query(state &State, left int, right int) i64 {
	mut position := left
	mut minimum := i64(9223372036854775807)
	for position < right {
		block := position / block_width
		start := block * block_width
		finish := block_end(state, block)
		if position == start && finish <= right {
			minimum = min(minimum, block_min(state, block))
			position = finish
		} else {
			stop := min(finish, right)
			for i := position; i < stop; i++ {
				minimum = min(minimum, state.data[i] + state.lazy_slope[block] * i64(i) + state.lazy_intercept[block])
			}
			position = stop
		}
	}
	return minimum
}

@[export: 'range_linear_add_range_min_benchmark']
pub fn range_linear_add_range_min_benchmark(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		if input[0] < 1 || input[0] > max_length || input[1] < 1 || input[1] > max_operations { return -1 }
		n := int(input[0])
		q := int(input[1])
		if length < usize(n + 2) { return -1 }
		mut state := State{n: n}
		for i in 0 .. n {
			if input[i + 2] < -1_000_000 || input[i + 2] > 1_000_000 { return -1 }
			state.data[i] = input[i + 2]
		}
		for block in 0 .. (n + block_width - 1) / block_width { rebuild(mut state, block) }
		mut cursor := n + 2
		mut checksum := i64(0)
		for operation in 0 .. q {
			if cursor >= int(length) { return -1 }
			opcode := input[cursor]
			cursor++
			if opcode == 0 {
				if cursor + 4 > int(length) { return -1 }
				left, right := input[cursor], input[cursor + 1]
				slope, intercept := input[cursor + 2], input[cursor + 3]
				cursor += 4
				if left < 0 || left >= right || right > i64(n) || slope < -99 || slope > 99 || intercept < -100_000 || intercept > 100_000 { return -1 }
				update(mut state, int(left), int(right), slope, intercept)
			} else if opcode == 1 {
				if cursor + 2 > int(length) { return -1 }
				left, right := input[cursor], input[cursor + 1]
				cursor += 2
				if left < 0 || left >= right || right > i64(n) { return -1 }
				checksum += i64(operation + 1) * (query(state, int(left), int(right)) + checksum_offset)
			} else { return -1 }
		}
		if cursor == int(length) { return checksum }
		return -1
	}
}
