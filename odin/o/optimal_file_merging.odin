package optimal_file_merging

import "core:c"

MAX_FILES :: 32

@(export)
optimal_file_merging :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > c.size_t(MAX_FILES + 1) do return -1
	count := values[0]
	if count < 0 || count > MAX_FILES || length != c.size_t(count) + 1 do return -1
	files: [MAX_FILES]i64
	for i := 0; i < int(count); i += 1 {
		if values[i + 1] < 0 || values[i + 1] > 1_000_000 do return -1
		files[i] = values[i + 1]
	}
	n := int(count)
	total := i64(0)
	for n > 1 {
		a, b := 0, 1
		if files[b] < files[a] { a, b = b, a }
		for i := 2; i < n; i += 1 {
			if files[i] < files[a] { b = a; a = i } else if files[i] < files[b] { b = i }
		}
		merged := files[a] + files[b]
		total += merged
		if a > b { a, b = b, a }
		files[a] = merged
		files[b] = files[n - 1]
		n -= 1
	}
	return total
}
