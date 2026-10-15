module xor_swap_two_integers

@[export: 'xor_swap_two_integers']
pub fn xor_swap_two_integers(first i64, second i64) i64 {
	if first < -32768 || first > 32767 || second < -32768 || second > 32767 { return -1 }
	mut a := first
	mut b := second
	if a < 0 { a += 65536 }
	if b < 0 { b += 65536 }
	a ^= b
	b ^= a
	a ^= b
	swapped_first := if a >= 32768 { a - 65536 } else { a }
	swapped_second := if b >= 32768 { b - 65536 } else { b }
	return (swapped_first + 32768) * 65536 + (swapped_second + 32768)
}
