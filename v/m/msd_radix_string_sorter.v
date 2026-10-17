module msd_radix_string_sorter

const max_strings = 256
const max_length = 32
const max_input = 1 + max_strings * (1 + max_length) + 1
const fnv_offset = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)
const mask_63 = u64(0x7fff_ffff_ffff_ffff)

struct EncodedString {
	mut:
	bytes [max_length]u8
	length int
}

fn bucket(value &EncodedString, digit int) int {
	if digit >= value.length { return 0 }
	return int(value.bytes[digit]) + 1
}

fn msd_sort(mut values [max_strings]EncodedString, mut auxiliary [max_strings]EncodedString, low int, high int, digit int) {
	if high - low < 2 || digit >= max_length { return }
	mut counts := [257]int{}
	for i in low .. high { counts[bucket(values[i], digit)]++ }
	mut starts := [257]int{}
	mut next := [257]int{}
	mut position := low
	for b in 0 .. 257 { starts[b] = position; next[b] = position; position += counts[b] }
	for i in low .. high { b := bucket(values[i], digit); auxiliary[next[b]] = values[i]; next[b]++ }
	for i in low .. high { values[i] = auxiliary[i] }
	for b in 1 .. 257 { first := starts[b]; last := first + counts[b]; if last - first > 1 { msd_sort(mut values, mut auxiliary, first, last, digit + 1) } }
}

@[export: 'msd_radix_string_sorter']
pub fn msd_radix_string_sorter(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length == 0 || length > usize(max_input) { return -1 }
		if input[0] < 0 || input[0] > max_strings { return -1 }
		count := int(input[0])
		mut values := [max_strings]EncodedString{}
		mut auxiliary := [max_strings]EncodedString{}
		mut position := 1
		for i in 0 .. count {
			if position >= int(length) || input[position] < 0 || input[position] > max_length { return -1 }
			n := int(input[position]); position++
			if n > int(length) - position { return -1 }
			values[i].length = n
			for digit in 0 .. n { if input[position] < 0 || input[position] > 255 { return -1 }; values[i].bytes[digit] = u8(input[position]); position++ }
		}
		if position != int(length) { return -1 }
		if count > 1 { msd_sort(mut values, mut auxiliary, 0, count, 0) }
		mut hash := fnv_offset
		hash = (hash ^ u64(count & 255)) * fnv_prime
		hash = (hash ^ u64((count >> 8) & 255)) * fnv_prime
		for i in 0 .. count { hash = (hash ^ u64(values[i].length)) * fnv_prime; for digit in 0 .. values[i].length { hash = (hash ^ u64(values[i].bytes[digit])) * fnv_prime } }
		return i64(hash & mask_63)
	}
}
