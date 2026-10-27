module signed_permutation_reversal_sequence

const max_n = 5
const max_states = 3840
const max_moves = 10
const max_output_bytes = 168

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

fn encode(permutation [max_n]i64, n int) int {
	mut rank := 0
	mut signs := 0
	for i in 0 .. n {
		value := int(if permutation[i] < 0 { -permutation[i] } else { permutation[i] })
		mut smaller := 0
		for j in (i + 1) .. n {
			other := int(if permutation[j] < 0 { -permutation[j] } else { permutation[j] })
			if other < value { smaller++ }
		}
		rank = rank * (n - i) + smaller
		if permutation[i] < 0 { signs |= 1 << (value - 1) }
	}
	rank * (1 << n) + signs
}

fn decode_state(state int, n int, factorials [max_n + 1]int, mut permutation [max_n]i64) {
	sign_count := 1 << n
	mut rank := state / sign_count
	signs := state % sign_count
	mut available := [max_n]int{init: 0}
	for i in 0 .. n { available[i] = i + 1 }
	mut remaining := n
	for i in 0 .. n {
		factor := factorials[n - i - 1]
		digit := rank / factor
		rank %= factor
		value := available[digit]
		for j in digit .. (remaining - 1) { available[j] = available[j + 1] }
		remaining--
		permutation[i] = i64(value)
		if (signs & (1 << (value - 1))) != 0 { permutation[i] = -permutation[i] }
	}
}

fn reverse_signed(mut permutation [max_n]i64, left_start int, right_start int) {
	mut left := left_start
	mut right := right_start
	for left < right {
		a := permutation[left]
		b := permutation[right]
		permutation[left] = -b
		permutation[right] = -a
		left++
		right--
	}
	if left == right { permutation[left] = -permutation[left] }
}

@[export: 'signed_permutation_reversal_sequence']
pub fn signed_permutation_reversal_sequence(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_n + 1 { return -1 }
		raw_n := input[0]
		if raw_n < 2 || raw_n > max_n || length != usize(raw_n + 1) { return -1 }
		n := int(raw_n)
		mut seen := 0
		mut permutation := [max_n]i64{init: 0}
		for i in 0 .. n {
			value := input[i + 1]
			if value == 0 || value < -raw_n || value > raw_n { return -1 }
			absolute := int(if value < 0 { -value } else { value })
			bit := 1 << (absolute - 1)
			if (seen & bit) != 0 { return -1 }
			seen |= bit
			permutation[i] = value
		}
		if seen != (1 << n) - 1 { return -1 }
		if output == nil { return -2 }

		factorials := [max_n + 1]int{init: 1}
		factorials[0] = 1
		for i in 1 .. max_n + 1 { factorials[i] = factorials[i - 1] * i }
		state_count := factorials[n] * (1 << n)
		mut parent := [max_states]i32{init: 0}
		mut queue := [max_states]i32{init: 0}
		mut move_left := [max_states]i8{init: 0}
		mut move_right := [max_states]i8{init: 0}
		for state in 0 .. state_count { parent[state] = -2 }
		start := encode(permutation, n)
		mut head := 0
		mut tail := 0
		parent[start] = -1
		queue[tail] = i32(start)
		tail++
		for head < tail && parent[0] == -2 {
			current := int(queue[head])
			head++
			mut current_permutation := [max_n]i64{init: 0}
			decode_state(current, n, factorials, mut current_permutation)
			for left in 0 .. n {
				if parent[0] != -2 { break }
				for right in left .. n {
					mut neighbor := current_permutation
					reverse_signed(mut neighbor, left, right)
					next := encode(neighbor, n)
					if parent[next] != -2 { continue }
					parent[next] = i32(current)
					move_left[next] = i8(left + 1)
					move_right[next] = i8(right + 1)
					queue[tail] = i32(next)
					tail++
					if next == 0 { break }
				}
			}
		}
		if parent[0] == -2 { return -1 }
		mut reverse_moves := [max_moves][2]i64{init: 0}
		mut move_count := 0
		mut current := 0
		for parent[current] >= 0 {
			if move_count == max_moves { return -1 }
			reverse_moves[move_count][0] = i64(move_left[current])
			reverse_moves[move_count][1] = i64(move_right[current])
			move_count++
			current = int(parent[current])
		}
		output_bytes := 8 * (1 + 2 * move_count)
		if capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{init: 0}
		store_i64_le(mut staged[..], 0, i64(move_count))
		for i in 0 .. move_count {
			reverse_index := move_count - 1 - i
			store_i64_le(mut staged[..], 8 * (1 + 2 * i), reverse_moves[reverse_index][0])
			store_i64_le(mut staged[..], 8 * (2 + 2 * i), reverse_moves[reverse_index][1])
		}
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
