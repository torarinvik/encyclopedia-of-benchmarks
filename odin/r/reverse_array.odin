package reverse_array

@(export, link_name="reverse_array")
reverse_array :: proc "c" (input: [^]i64, length: uint, output: [^]u8, capacity: uint) -> i64 {
	if length < 1 || length > 257 do return -1
	count := input[0]
	if count < 1 || count > 256 || length != uint(count + 1) do return -1
	for i: i64 = 0; i < count; i += 1 { if input[i + 1] < 0 || input[i + 1] > 255 do return -1 }
	if capacity < uint(count) do return -2
	for i: i64 = 0; i < count; i += 1 { output[i] = u8(input[i + 1]) }
	left: i64 = 0
	right := count - 1
	for left < right { output[left], output[right] = output[right], output[left]; left += 1; right -= 1 }
	return count
}

main :: proc() {}
