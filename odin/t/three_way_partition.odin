package three_way_partition

import "core:mem"

@(export, link_name="three_way_partition")
three_way_partition :: proc "c" (input: [^]i64, length: uint, output: [^]u8, capacity: uint) -> i64 {
	if length < 2 || length > 258 do return -1
	n, pivot := input[0], input[1]
	if n < 0 || n > 256 || length != uint(n + 2) || pivot < -2147483648 || pivot > 2147483647 do return -1
	items: [256]i32
	for i: i64 = 0; i < n; i += 1 { x := input[i + 2]; if x < -2147483648 || x > 2147483647 do return -1; items[i] = i32(x) }
	low, mid, high: i64 = 0, 0, n
	for mid < high { if i64(items[mid]) < pivot { items[low], items[mid] = items[mid], items[low]; low += 1; mid += 1 } else if i64(items[mid]) > pivot { high -= 1; items[mid], items[high] = items[high], items[mid] } else { mid += 1 } }
	bytes := uint(n + 2) * 4
	if capacity < bytes do return -2
	out := transmute([^]i32)(output)
	for i: i64 = 0; i < n; i += 1 { out[i] = items[i] }
	out[n], out[n + 1] = i32(low), i32(high)
	return n + 2
}
main :: proc() {}
