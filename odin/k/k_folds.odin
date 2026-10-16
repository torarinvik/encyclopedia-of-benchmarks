package k_folds

import "core:c"

@(export)
k_folds :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	sample_count, fold_count := values[0], values[1]
	if sample_count < 1 || sample_count > 12 || fold_count < 1 || fold_count > 12 do return -1
	width := (sample_count + fold_count - 1) / fold_count
	packed: u64 = u64(sample_count) << 48
	for index := 0; index < int(sample_count); index += 1 {
		fold := u64(index + int(width)) / u64(width)
		packed |= fold << (4 * index)
	}
	return i64(packed)
}
