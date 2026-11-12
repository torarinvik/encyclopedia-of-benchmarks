module stern_brocot_tree

const max_queries = 128
const max_runs = 64
const max_input_length = 16_384
const max_output_words = 32_768
const max_component = i64(1_000_000_000)

struct Run {
	direction i64
	count i64
}

struct Decoded {
	numerator i64
	denominator i64
	lower_num i64
	lower_den i64
	upper_num i64
	upper_den i64
}

fn sbt_gcd(a_value i64, b_value i64) i64 {
	mut a := a_value
	mut b := b_value
	for b != 0 {
		remainder := a % b
		a, b = b, remainder
	}
	return a
}

fn valid_fraction(numerator i64, denominator i64) bool {
	return numerator >= 1 && numerator <= max_component && denominator >= 1 &&
		denominator <= max_component && sbt_gcd(numerator, denominator) == 1
}

fn encode_path(numerator_value i64, denominator_value i64, mut runs [max_runs]Run) int {
	mut numerator := numerator_value
	mut denominator := denominator_value
	mut run_count := 0
	for numerator != denominator {
		if run_count >= max_runs { return -1 }
		if numerator < denominator {
			count := (denominator - 1) / numerator
			runs[run_count] = Run{direction: 0, count: count}
			denominator -= count * numerator
		} else {
			count := (numerator - 1) / denominator
			runs[run_count] = Run{direction: 1, count: count}
			numerator -= count * denominator
		}
		run_count++
	}
	return run_count
}

fn decode_path(runs []Run, mut decoded &Decoded) bool {
	mut ln := i64(0)
	mut ld := i64(1)
	mut un := i64(1)
	mut ud := i64(0)
	mut previous := i64(-1)
	for run in runs {
		if (run.direction != 0 && run.direction != 1) || run.count < 1 ||
			run.count > max_component || run.direction == previous { return false }
		if run.direction == 0 {
			un += run.count * ln
			ud += run.count * ld
			if un > max_component || ud > max_component { return false }
		} else {
			ln += run.count * un
			ld += run.count * ud
			if ln > max_component || ld > max_component { return false }
		}
		previous = run.direction
	}
	numerator := ln + un
	denominator := ld + ud
	if !valid_fraction(numerator, denominator) { return false }
	decoded = Decoded{numerator: numerator, denominator: denominator, lower_num: ln, lower_den: ld,
		upper_num: un, upper_den: ud}
	return true
}

fn common_prefix(left []Run, right []Run, mut prefix [max_runs]Run) int {
	mut i := 0
	mut j := 0
	mut count := 0
	mut left_used := i64(0)
	mut right_used := i64(0)
	for i < left.len && j < right.len && left[i].direction == right[j].direction {
		shared := min(left[i].count - left_used, right[j].count - right_used)
		prefix[count] = Run{direction: left[i].direction, count: shared}
		count++
		left_used += shared
		right_used += shared
		if left_used == left[i].count { i++; left_used = 0 }
		if right_used == right[j].count { j++; right_used = 0 }
	}
	return count
}

fn append_word(mut words [max_output_words]i64, mut word_count &int, value i64) bool {
	if word_count >= max_output_words { return false }
	words[word_count] = value
	word_count++
	return true
}

@[export: 'stern_brocot_tree']
pub fn stern_brocot_tree(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(max_input_length) { return -1 }
	query_count := unsafe { input[0] }
	if query_count < 1 || query_count > i64(max_queries) { return -1 }
	mut words := [max_output_words]i64{}
	mut word_count := 0
	mut position := 1
	for _ in 0 .. int(query_count) {
		if position >= int(length) { return -1 }
		operation := unsafe { input[position] }
		position++
		if operation == 0 {
			if position + 2 > int(length) { return -1 }
			numerator := unsafe { input[position] }
			denominator := unsafe { input[position + 1] }
			position += 2
			if !valid_fraction(numerator, denominator) { return -1 }
			mut runs := [max_runs]Run{}
			run_count := encode_path(numerator, denominator, mut runs)
			if run_count < 0 || !append_word(mut words, mut word_count, operation) ||
				!append_word(mut words, mut word_count, i64(run_count)) { return -1 }
			for run in runs[..run_count] {
				if !append_word(mut words, mut word_count, run.direction) || !append_word(mut words, mut word_count, run.count) { return -1 }
			}
		} else if operation == 1 {
			if position >= int(length) { return -1 }
			raw_count := unsafe { input[position] }
			position++
			if raw_count < 0 || raw_count > i64(max_runs) || position + int(raw_count) * 2 > int(length) { return -1 }
			mut runs := [max_runs]Run{}
			for i in 0 .. int(raw_count) {
				runs[i] = Run{direction: unsafe { input[position] }, count: unsafe { input[position + 1] }}
				position += 2
			}
			mut decoded := Decoded{}
			if !decode_path(runs[..int(raw_count)], mut decoded) ||
				!append_word(mut words, mut word_count, operation) ||
				!append_word(mut words, mut word_count, decoded.numerator) ||
				!append_word(mut words, mut word_count, decoded.denominator) { return -1 }
		} else if operation == 2 {
			if position + 4 > int(length) { return -1 }
			a := unsafe { input[position] }
			b := unsafe { input[position + 1] }
			c := unsafe { input[position + 2] }
			d := unsafe { input[position + 3] }
			position += 4
			if !valid_fraction(a, b) || !valid_fraction(c, d) { return -1 }
			mut left := [max_runs]Run{}
			mut right := [max_runs]Run{}
			mut prefix := [max_runs]Run{}
			left_count := encode_path(a, b, mut left)
			right_count := encode_path(c, d, mut right)
			if left_count < 0 || right_count < 0 { return -1 }
			prefix_count := common_prefix(left[..left_count], right[..right_count], mut prefix)
			mut decoded := Decoded{}
			if !decode_path(prefix[..prefix_count], mut decoded) ||
				!append_word(mut words, mut word_count, operation) ||
				!append_word(mut words, mut word_count, decoded.numerator) ||
				!append_word(mut words, mut word_count, decoded.denominator) { return -1 }
		} else if operation == 3 {
			if position + 3 > int(length) { return -1 }
			depth := unsafe { input[position] }
			numerator := unsafe { input[position + 1] }
			denominator := unsafe { input[position + 2] }
			position += 3
			if depth < 1 || depth > max_component || !valid_fraction(numerator, denominator) { return -1 }
			mut path := [max_runs]Run{}
			mut prefix := [max_runs]Run{}
			path_count := encode_path(numerator, denominator, mut path)
			if path_count < 0 || !append_word(mut words, mut word_count, operation) { return -1 }
			mut total_depth := i64(0)
			for run in path[..path_count] { total_depth += run.count }
			if depth > total_depth {
				if !append_word(mut words, mut word_count, -1) { return -1 }
			} else {
				mut remaining := depth
				mut prefix_count := 0
				for run in path[..path_count] {
					if remaining == 0 { break }
					take := min(remaining, run.count)
					prefix[prefix_count] = Run{direction: run.direction, count: take}
					prefix_count++
					remaining -= take
				}
				mut decoded := Decoded{}
				if !decode_path(prefix[..prefix_count], mut decoded) ||
					!append_word(mut words, mut word_count, decoded.numerator) ||
					!append_word(mut words, mut word_count, decoded.denominator) { return -1 }
			}
		} else if operation == 4 {
			if position + 2 > int(length) { return -1 }
			numerator := unsafe { input[position] }
			denominator := unsafe { input[position + 1] }
			position += 2
			if !valid_fraction(numerator, denominator) { return -1 }
			mut path := [max_runs]Run{}
			path_count := encode_path(numerator, denominator, mut path)
			if path_count < 0 { return -1 }
			mut decoded := Decoded{}
			if !decode_path(path[..path_count], mut decoded) ||
				!append_word(mut words, mut word_count, operation) ||
				!append_word(mut words, mut word_count, decoded.lower_num) ||
				!append_word(mut words, mut word_count, decoded.lower_den) ||
				!append_word(mut words, mut word_count, decoded.upper_num) ||
				!append_word(mut words, mut word_count, decoded.upper_den) { return -1 }
		} else { return -1 }
	}
	if position != int(length) { return -1 }
	byte_count := word_count * 8
	if output_capacity < usize(byte_count) || unsafe { output == nil } { return -2 }
	for i in 0 .. word_count {
		bits := u64(words[i])
		for byte in 0 .. 8 {
			unsafe { output[i * 8 + byte] = u8((bits >> u64(byte * 8)) & 255) }
		}
	}
	return query_count
}
