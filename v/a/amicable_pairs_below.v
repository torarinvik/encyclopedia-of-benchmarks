module amicable_pairs_below

const max_limit = 8000

fn write_u32_le(output &u8, position_value usize, value i64) usize {
	mut position := position_value
	mut encoded := u32(value)
	for _ in 0 .. 4 {
		unsafe { output[position] = u8(encoded & u32(255)) }
		encoded >>= 8
		position++
	}
	return position
}

// Enumerate amicable pairs below an exclusive upper limit using a divisor-sum sieve.
@[export: 'amicable_pairs_below']
pub fn amicable_pairs_below(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length != 1 { return -1 }
	limit_value := unsafe { values[0] }
	if limit_value < 1 || limit_value > max_limit { return -1 }
	limit := int(limit_value)
	mut divisor_sums := [max_limit]i64{init: 0}
	for divisor := 1; divisor < limit; divisor++ {
		mut multiple := divisor * 2
		for multiple < limit {
			divisor_sums[multiple] += i64(divisor)
			multiple += divisor
		}
	}

	mut pair_count := 0
	for smaller := 2; smaller < limit; smaller++ {
		larger := divisor_sums[smaller]
		if larger > i64(smaller) && larger < i64(limit) && divisor_sums[int(larger)] == i64(smaller) {
			pair_count++
		}
	}
	required := usize(pair_count * 8)
	if output_capacity < required { return -2 }

	mut position := usize(0)
	for smaller := 2; smaller < limit; smaller++ {
		larger := divisor_sums[smaller]
		if larger > i64(smaller) && larger < i64(limit) && divisor_sums[int(larger)] == i64(smaller) {
			position = write_u32_le(output, position, i64(smaller))
			position = write_u32_le(output, position, larger)
		}
	}
	return i64(pair_count)
}
