package xor_swap_two_integers

@(export)
xor_swap_two_integers :: proc "contextless" (first, second: i64) -> i64 {
	if first < -32768 || first > 32767 || second < -32768 || second > 32767 do return -1
	a := first
	b := second
	if a < 0 { a += 65536 }
	if b < 0 { b += 65536 }
	a = a ~ b
	b = a ~ b
	a = a ~ b
	swapped_first := a
	swapped_second := b
	if a >= 32768 { swapped_first -= 65536 }
	if b >= 32768 { swapped_second -= 65536 }
	return (swapped_first + 32768) * 65536 + (swapped_second + 32768)
}
