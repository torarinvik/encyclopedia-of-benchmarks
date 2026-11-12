package range_linear_add_range_min

import "core:c"

MAX_LENGTH :: 64
MAX_OPERATIONS :: 64
MAX_INPUT :: c.size_t(387)
BLOCK_WIDTH :: 8
MAX_BLOCKS :: 8
CHECKSUM_OFFSET :: i64(8_000_000)

State :: struct {
	data: [MAX_LENGTH]i64,
	hull_x: [MAX_LENGTH]i64,
	hull_y: [MAX_LENGTH]i64,
	hull_count: [MAX_BLOCKS]int,
	lazy_slope: [MAX_BLOCKS]i64,
	lazy_intercept: [MAX_BLOCKS]i64,
	n: int,
}

block_end :: proc "contextless" (state: ^State, block: int) -> int {
	return min((block+1)*BLOCK_WIDTH, state.n)
}

rebuild :: proc "contextless" (state: ^State, block: int) {
	base := block*BLOCK_WIDTH
	size := 0
	for x := base; x < block_end(state, block); x += 1 {
		for size >= 2 {
			p := base+size-2
			q := base+size-1
			cross := (state.hull_x[q]-state.hull_x[p])*(state.data[x]-state.hull_y[p]) -
				(state.hull_y[q]-state.hull_y[p])*(i64(x)-state.hull_x[p])
			if cross > 0 do break
			size -= 1
		}
		state.hull_x[base+size] = i64(x)
		state.hull_y[base+size] = state.data[x]
		size += 1
	}
	state.hull_count[block] = size
}

push_block :: proc "contextless" (state: ^State, block: int) {
	start := block*BLOCK_WIDTH
	for i := start; i < block_end(state, block); i += 1 {
		state.data[i] += state.lazy_slope[block]*i64(i)+state.lazy_intercept[block]
	}
	state.lazy_slope[block] = 0
	state.lazy_intercept[block] = 0
}

block_min :: proc "contextless" (state: ^State, block: int) -> i64 {
	base := block*BLOCK_WIDTH
	low := 0
	high := state.hull_count[block]-1
	for low < high {
		middle := low+(high-low)/2
		left := state.hull_y[base+middle]+state.lazy_slope[block]*state.hull_x[base+middle]
		right := state.hull_y[base+middle+1]+state.lazy_slope[block]*state.hull_x[base+middle+1]
		if left <= right { high = middle } else { low = middle+1 }
	}
	return state.hull_y[base+low]+state.lazy_slope[block]*state.hull_x[base+low]+state.lazy_intercept[block]
}

update :: proc "contextless" (state: ^State, left, right: int, slope, intercept: i64) {
	position := left
	for position < right {
		block := position/BLOCK_WIDTH
		start := block*BLOCK_WIDTH
		finish := block_end(state, block)
		if position == start && finish <= right {
			state.lazy_slope[block] += slope
			state.lazy_intercept[block] += intercept
			position = finish
		} else {
			push_block(state, block)
			stop := min(finish, right)
			for i := position; i < stop; i += 1 { state.data[i] += slope*i64(i)+intercept }
			rebuild(state, block)
			position = stop
		}
	}
}

query :: proc "contextless" (state: ^State, left, right: int) -> i64 {
	position := left
	minimum := i64(9223372036854775807)
	for position < right {
		block := position/BLOCK_WIDTH
		start := block*BLOCK_WIDTH
		finish := block_end(state, block)
		if position == start && finish <= right {
			minimum = min(minimum, block_min(state, block))
			position = finish
		} else {
			stop := min(finish, right)
			for i := position; i < stop; i += 1 {
				minimum = min(minimum, state.data[i]+state.lazy_slope[block]*i64(i)+state.lazy_intercept[block])
			}
			position = stop
		}
	}
	return minimum
}

@(export)
range_linear_add_range_min_benchmark :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	if input[0] < 1 || input[0] > i64(MAX_LENGTH) || input[1] < 1 || input[1] > i64(MAX_OPERATIONS) do return -1
	n := int(input[0])
	q := int(input[1])
	if length < c.size_t(n+2) do return -1
	mut state: State
	state.n = n
	for i in 0..<n {
		if input[i+2] < -1_000_000 || input[i+2] > 1_000_000 do return -1
		state.data[i] = input[i+2]
	}
	blocks := (n+BLOCK_WIDTH-1)/BLOCK_WIDTH
	for block in 0..<blocks { rebuild(&state, block) }
	cursor := n+2
	checksum := i64(0)
	for operation in 0..<q {
		if cursor >= int(length) do return -1
		opcode := input[cursor]
		cursor += 1
		if opcode == 0 {
			if cursor+4 > int(length) do return -1
			left, right := input[cursor], input[cursor+1]
			slope, intercept := input[cursor+2], input[cursor+3]
			cursor += 4
			if left < 0 || left >= right || right > i64(n) || slope < -99 || slope > 99 || intercept < -100_000 || intercept > 100_000 do return -1
			update(&state, int(left), int(right), slope, intercept)
		} else if opcode == 1 {
			if cursor+2 > int(length) do return -1
			left, right := input[cursor], input[cursor+1]
			cursor += 2
			if left < 0 || left >= right || right > i64(n) do return -1
			checksum += i64(operation+1)*(query(&state, int(left), int(right))+CHECKSUM_OFFSET)
		} else { return -1 }
	}
	if cursor == int(length) do return checksum
	return -1
}
