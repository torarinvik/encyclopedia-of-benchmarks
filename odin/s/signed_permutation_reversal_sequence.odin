package signed_permutation_reversal_sequence

import "core:c"

MAX_N :: 5
MAX_STATES :: 3840
MAX_MOVES :: 10
MAX_OUTPUT_BYTES :: 168

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

encode :: proc(permutation: [^]i64, n: int) -> int {
	rank := 0
	signs := 0
	for i := 0; i < n; i += 1 {
		value := int(if permutation[i] < 0 do -permutation[i] else permutation[i])
		smaller := 0
		for j := i+1; j < n; j += 1 {
			other := int(if permutation[j] < 0 do -permutation[j] else permutation[j])
			if other < value do smaller += 1
		}
		rank = rank*(n-i)+smaller
		if permutation[i] < 0 do signs |= 1 << (value-1)
	}
	return rank*(1<<n)+signs
}

decode_state :: proc(state, n: int, factorials: [^]int, permutation: [^]i64) {
	sign_count := 1 << n
	rank := state/sign_count
	signs := state%sign_count
	available: [MAX_N]int = {}
	for i := 0; i < n; i += 1 { available[i] = i+1 }
	remaining := n
	for i := 0; i < n; i += 1 {
		factor := factorials[n-i-1]
		digit := rank/factor
		rank %= factor
		value := available[digit]
		for j := digit; j+1 < remaining; j += 1 { available[j] = available[j+1] }
		remaining -= 1
		permutation[i] = i64(value)
		if signs&(1<<(value-1)) != 0 do permutation[i] = -permutation[i]
	}
}

reverse_signed :: proc(permutation: [^]i64, left_start, right_start: int) {
	left, right := left_start, right_start
	for left < right {
		a, b := permutation[left], permutation[right]
		permutation[left], permutation[right] = -b, -a
		left += 1; right -= 1
	}
	if left == right do permutation[left] = -permutation[left]
}

@(export)
signed_permutation_reversal_sequence :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_N+1 do return -1
	raw_n := input[0]
	if raw_n < 2 || raw_n > MAX_N || length != c.size_t(raw_n+1) do return -1
	n := int(raw_n)
	seen := 0
	permutation: [MAX_N]i64 = {}
	for i := 0; i < n; i += 1 {
		value := input[i+1]
		if value == 0 || value < -raw_n || value > raw_n do return -1
		absolute := int(if value < 0 do -value else value)
		bit := 1 << (absolute-1)
		if seen&bit != 0 do return -1
		seen |= bit
		permutation[i] = value
	}
	if seen != (1<<n)-1 do return -1
	if output == nil do return -2

	factorials: [MAX_N+1]int = {1, 1, 2, 6, 24, 120}
	state_count := factorials[n]*(1<<n)
	parent: [MAX_STATES]i32 = {}
	queue: [MAX_STATES]i32 = {}
	move_left: [MAX_STATES]i8 = {}
	move_right: [MAX_STATES]i8 = {}
	for state := 0; state < state_count; state += 1 { parent[state] = -2 }
	start := encode(&permutation[0], n)
	head, tail := 0, 0
	parent[start] = -1; queue[tail] = i32(start); tail += 1
	for head < tail && parent[0] == -2 {
		current := int(queue[head]); head += 1
		current_permutation: [MAX_N]i64 = {}
		decode_state(current, n, &factorials[0], &current_permutation[0])
		for left := 0; left < n && parent[0] == -2; left += 1 {
			for right := left; right < n; right += 1 {
				neighbor := current_permutation
				reverse_signed(&neighbor[0], left, right)
				next := encode(&neighbor[0], n)
				if parent[next] != -2 do continue
				parent[next] = i32(current)
				move_left[next] = i8(left+1); move_right[next] = i8(right+1)
				queue[tail] = i32(next); tail += 1
				if next == 0 do break
			}
		}
	}
	if parent[0] == -2 do return -1
	reverse_moves: [MAX_MOVES][2]i64 = {}
	move_count, current := 0, 0
	for parent[current] >= 0 {
		if move_count == MAX_MOVES do return -1
		reverse_moves[move_count][0] = i64(move_left[current])
		reverse_moves[move_count][1] = i64(move_right[current])
		move_count += 1; current = int(parent[current])
	}
	output_bytes := 8*(1+2*move_count)
	if capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8 = {}
	store_i64_le(&staged[0], 0, i64(move_count))
	for i := 0; i < move_count; i += 1 {
		reverse_index := move_count-1-i
		store_i64_le(&staged[0], 8*(1+2*i), reverse_moves[reverse_index][0])
		store_i64_le(&staged[0], 8*(2+2*i), reverse_moves[reverse_index][1])
	}
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
