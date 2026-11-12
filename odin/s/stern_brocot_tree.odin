package stern_brocot_tree

import "core:c"

Max_Queries :: 128
Max_Runs :: 64
Max_Input_Length :: 16_384
Max_Output_Words :: 32_768
Max_Component :: i64(1_000_000_000)

Run :: struct { direction, count: i64 }
Decoded :: struct { numerator, denominator, lower_num, lower_den, upper_num, upper_den: i64 }

sbt_gcd :: proc "contextless" (a_value, b_value: i64) -> i64 {
	a, b := a_value, b_value
	for b != 0 {
		remainder := a % b
		a, b = b, remainder
	}
	return a
}

valid_fraction :: proc "contextless" (numerator, denominator: i64) -> bool {
	return numerator >= 1 && numerator <= Max_Component && denominator >= 1 &&
		denominator <= Max_Component && sbt_gcd(numerator, denominator) == 1
}

encode_path :: proc "contextless" (numerator_value, denominator_value: i64,
	runs: ^Run, run_count: ^int) -> bool {
	numerator, denominator := numerator_value, denominator_value
	 run_count^ = 0
	for numerator != denominator {
		if run_count^ >= Max_Runs do return false
		if numerator < denominator {
			count := (denominator - 1) / numerator
			runs[run_count^] = {0, count}
			denominator -= count * numerator
		} else {
			count := (numerator - 1) / denominator
			runs[run_count^] = {1, count}
			numerator -= count * denominator
		}
		run_count^ += 1
	}
	return true
}

decode_path :: proc "contextless" (runs: ^Run, run_count: int, result: ^Decoded) -> bool {
	ln, ld, un, ud, previous := i64(0), i64(1), i64(1), i64(0), i64(-1)
	for i := 0; i < run_count; i += 1 {
		direction, count := runs[i].direction, runs[i].count
		if (direction != 0 && direction != 1) || count < 1 || count > Max_Component || direction == previous do return false
		if direction == 0 {
			un += count * ln
			ud += count * ld
			if un > Max_Component || ud > Max_Component do return false
		} else {
			ln += count * un
			ld += count * ud
			if ln > Max_Component || ld > Max_Component do return false
		}
		previous = direction
	}
	numerator, denominator := ln + un, ld + ud
	if !valid_fraction(numerator, denominator) do return false
	result.numerator, result.denominator = numerator, denominator
	result.lower_num, result.lower_den = ln, ld
	result.upper_num, result.upper_den = un, ud
	return true
}

common_prefix :: proc "contextless" (left: ^Run, left_count: int, right: ^Run, right_count: int,
	prefix: ^Run) -> int {
	i, j, count := 0, 0, 0
	left_used, right_used := i64(0), i64(0)
	for i < left_count && j < right_count && left[i].direction == right[j].direction {
		left_remaining := left[i].count - left_used
		right_remaining := right[j].count - right_used
		shared := min(left_remaining, right_remaining)
		prefix[count] = {left[i].direction, shared}
		count += 1
		left_used += shared
		right_used += shared
		if left_used == left[i].count { i += 1; left_used = 0 }
		if right_used == right[j].count { j += 1; right_used = 0 }
	}
	return count
}

append_word :: proc "contextless" (words: ^i64, word_count: ^int, value: i64) -> bool {
	if word_count^ >= Max_Output_Words do return false
	words[word_count^] = value
	word_count^ += 1
	return true
}

@(export)
stern_brocot_tree :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(Max_Input_Length) do return -1
	query_count := input[0]
	if query_count < 1 || query_count > i64(Max_Queries) do return -1
	words: [Max_Output_Words]i64
	word_count, position := 0, 1
	for query := i64(0); query < query_count; query += 1 {
		if position >= int(length) do return -1
		operation := input[position]
		position += 1
		if operation == 0 {
			if position+2 > int(length) do return -1
			numerator, denominator := input[position], input[position+1]
			position += 2
			if !valid_fraction(numerator, denominator) do return -1
			runs: [Max_Runs]Run
		run_count := 0
		if !encode_path(numerator, denominator, &runs[0], &run_count) ||
			!append_word(&words[0], &word_count, operation) || !append_word(&words[0], &word_count, i64(run_count)) do return -1
		for i := 0; i < run_count; i += 1 {
			if !append_word(&words[0], &word_count, runs[i].direction) || !append_word(&words[0], &word_count, runs[i].count) do return -1
		}
		} else if operation == 1 {
			if position >= int(length) do return -1
			raw_count := input[position]
			position += 1
			if raw_count < 0 || raw_count > i64(Max_Runs) || position+int(raw_count)*2 > int(length) do return -1
			run_count := int(raw_count)
			runs: [Max_Runs]Run
			for i := 0; i < run_count; i += 1 { runs[i] = {input[position], input[position+1]}; position += 2 }
			decoded: Decoded
			if !decode_path(&runs[0], run_count, &decoded) || !append_word(&words[0], &word_count, operation) ||
				!append_word(&words[0], &word_count, decoded.numerator) || !append_word(&words[0], &word_count, decoded.denominator) do return -1
		} else if operation == 2 {
			if position+4 > int(length) do return -1
			a, b, c_value, d := input[position], input[position+1], input[position+2], input[position+3]
			position += 4
			if !valid_fraction(a, b) || !valid_fraction(c_value, d) do return -1
			left, right, prefix: [Max_Runs]Run
			left_count, right_count := 0, 0
			if !encode_path(a, b, &left[0], &left_count) || !encode_path(c_value, d, &right[0], &right_count) do return -1
			prefix_count := common_prefix(&left[0], left_count, &right[0], right_count, &prefix[0])
			decoded: Decoded
			if !decode_path(&prefix[0], prefix_count, &decoded) || !append_word(&words[0], &word_count, operation) ||
				!append_word(&words[0], &word_count, decoded.numerator) || !append_word(&words[0], &word_count, decoded.denominator) do return -1
		} else if operation == 3 {
			if position+3 > int(length) do return -1
			depth, numerator, denominator := input[position], input[position+1], input[position+2]
			position += 3
			if depth < 1 || depth > Max_Component || !valid_fraction(numerator, denominator) do return -1
			path, prefix: [Max_Runs]Run
			path_count := 0
			if !encode_path(numerator, denominator, &path[0], &path_count) || !append_word(&words[0], &word_count, operation) do return -1
			total_depth := i64(0)
			for i := 0; i < path_count; i += 1 { total_depth += path[i].count }
			if depth > total_depth {
				if !append_word(&words[0], &word_count, -1) do return -1
			} else {
				remaining, prefix_count := depth, 0
				for i := 0; i < path_count && remaining > 0; i += 1 {
					take := min(remaining, path[i].count)
					prefix[prefix_count] = {path[i].direction, take}
					prefix_count += 1
					remaining -= take
				}
				decoded: Decoded
				if !decode_path(&prefix[0], prefix_count, &decoded) || !append_word(&words[0], &word_count, decoded.numerator) ||
					!append_word(&words[0], &word_count, decoded.denominator) do return -1
			}
		} else if operation == 4 {
			if position+2 > int(length) do return -1
			numerator, denominator := input[position], input[position+1]
			position += 2
			if !valid_fraction(numerator, denominator) do return -1
			path: [Max_Runs]Run
			path_count := 0
			if !encode_path(numerator, denominator, &path[0], &path_count) do return -1
			decoded: Decoded
			if !decode_path(&path[0], path_count, &decoded) || !append_word(&words[0], &word_count, operation) ||
				!append_word(&words[0], &word_count, decoded.lower_num) || !append_word(&words[0], &word_count, decoded.lower_den) ||
				!append_word(&words[0], &word_count, decoded.upper_num) || !append_word(&words[0], &word_count, decoded.upper_den) do return -1
		} else { return -1 }
	}
	if position != int(length) do return -1
	byte_count := word_count * 8
	if output_capacity < c.size_t(byte_count) || output == nil do return -2
	for i := 0; i < word_count; i += 1 {
		bits := u64(words[i])
		for byte := 0; byte < 8; byte += 1 { output[i*8+byte] = u8((bits >> u64(byte*8)) & 255) }
	}
	return query_count
}
