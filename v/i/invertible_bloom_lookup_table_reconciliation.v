module invertible_bloom_lookup_table_reconciliation

const set_limit = 8
const key_limit = 63
const cell_count = 48
const max_peels = 16
const max_input = 18

fn checksum(key i64) i64 { return key * key + 3 * key + 7 }

fn location(key i64, part int) int {
	x := int(key)
	if part == 0 { return x % 16 }
	if part == 1 { return 16 + ((3 * x + 5) % 16) }
	return 32 + ((5 * x + 9) % 16)
}

fn write_i64_le(output &mut u8, word int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[word * 8 + byte] = u8(bits >> u64(8 * byte)) } }
}

@[export: 'invertible_bloom_lookup_table_reconciliation']
pub fn invertible_bloom_lookup_table_reconciliation(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input + 1 { return -1 }
		a_raw, b_raw := input[0], input[1]
		if a_raw < 0 || a_raw > set_limit || b_raw < 0 || b_raw > set_limit { return -1 }
		a_count, b_count := int(a_raw), int(b_raw)
		if length != usize(2 + a_count + b_count) { return -1 }
		for side in 0 .. 2 {
			count, start := a_count, 2
			if side == 1 { count, start = b_count, 2 + a_count }
			mut previous := i64(-1)
			for i in 0 .. count {
				key := input[start + i]
				if key < 0 || key > key_limit || key <= previous { return -1 }
				previous = key
			}
		}

		mut counts := [cell_count]i64{init: 0}
		mut sums := [cell_count]i64{init: 0}
		mut checks := [cell_count]i64{init: 0}
		for side in 0 .. 2 {
			count, start, sign := a_count, 2, i64(1)
			if side == 1 { count, start, sign = b_count, 2 + a_count, -1 }
			for i in 0 .. count {
				key := input[start + i]
				for part in 0 .. 3 {
					slot := location(key, part)
					counts[slot] += sign
					sums[slot] += sign * key
					checks[slot] += sign * checksum(key)
				}
			}
		}

		mut positive := [max_peels]i64{init: 0}
		mut negative := [max_peels]i64{init: 0}
		mut positive_count, mut negative_count := 0, 0
		mut repeated := false
		for _ in 0 .. max_peels {
			mut zero := true
			for i in 0 .. cell_count { if counts[i] != 0 || sums[i] != 0 || checks[i] != 0 { zero = false; break } }
			if zero { break }
			mut found := false
			mut selected_sign := i64(0)
			mut key := i64(0)
			for i in 0 .. cell_count {
				if counts[i] != 1 && counts[i] != -1 { continue }
				sign := counts[i]
				candidate := sign * sums[i]
				if candidate < 0 || candidate > key_limit || checks[i] != sign * checksum(candidate) { continue }
				selected_sign, key, found = sign, candidate, true
				break
			}
			if !found { break }
			for i in 0 .. positive_count { if positive[i] == key { repeated = true } }
			for i in 0 .. negative_count { if negative[i] == key { repeated = true } }
			if repeated { break }
			if selected_sign > 0 { positive[positive_count] = key; positive_count++ }
			else { negative[negative_count] = key; negative_count++ }
			for part in 0 .. 3 {
				slot := location(key, part)
				counts[slot] -= selected_sign
				sums[slot] -= selected_sign * key
				checks[slot] -= selected_sign * checksum(key)
			}
		}

		mut zero := true
		for i in 0 .. cell_count { if counts[i] != 0 || sums[i] != 0 || checks[i] != 0 { zero = false; break } }
		for i in 1 .. positive_count { value := positive[i]; mut j := i; for j > 0 && positive[j - 1] > value { positive[j] = positive[j - 1]; j-- }; positive[j] = value }
		for i in 1 .. negative_count { value := negative[i]; mut j := i; for j > 0 && negative[j - 1] > value { negative[j] = negative[j - 1]; j-- }; negative[j] = value }
		mut staged := [3 + 2 * max_peels]i64{init: 0}
		mut words := 0
		staged[words] = if !repeated && zero { 1 } else { 0 }
		words++
		staged[words] = i64(positive_count); words++
		staged[words] = i64(negative_count); words++
		for i in 0 .. positive_count { staged[words] = positive[i]; words++ }
		for i in 0 .. negative_count { staged[words] = negative[i]; words++ }
		required := words * 8
		if output == nil || capacity < usize(required) { return -2 }
		for i in 0 .. words { write_i64_le(mut output, i, staged[i]) }
		return i64(required)
	}
}
