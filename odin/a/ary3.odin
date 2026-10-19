package ary3

import "core:c"

MAX_LENGTH :: 4096

@(export, link_name="ary3")
ary3 :: proc "c" (length: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length < 1 || length > i64(MAX_LENGTH) do return -1
	n := int(length)
	x: [MAX_LENGTH]i32
	y: [MAX_LENGTH]i32
	for index := 0; index < n; index += 1 {
		x[index] = i32(index + 1)
		y[index] = 0
	}
	for pass := 0; pass < 1000; pass += 1 {
		for index := n; index > 0; index -= 1 {
			position := index - 1
			y[position] += x[position]
		}
	}

	first := u32(y[0])
	last := u32(y[n - 1])
	first_reversed: [10]u8
	first_digit_count := 0
	for {
		first_reversed[first_digit_count] = u8(48 + first % 10)
		first_digit_count += 1
		first /= 10
		if first == 0 do break
	}
	reversed: [10]u8
	digit_count := 0
	for {
		reversed[digit_count] = u8(48 + last % 10)
		digit_count += 1
		last /= 10
		if last == 0 do break
	}
	required := first_digit_count + 2 + digit_count
	if output == nil || output_capacity < c.size_t(required) do return -2
	for index := 0; index < first_digit_count; index += 1 {
		output[index] = first_reversed[first_digit_count - index - 1]
	}
	output[first_digit_count] = 32
	for index := 0; index < digit_count; index += 1 {
		output[first_digit_count + 1 + index] = reversed[digit_count - index - 1]
	}
	output[required - 1] = 10
	return i64(required)
}
