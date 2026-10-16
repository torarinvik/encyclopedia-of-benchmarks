module k_folds

@[export: 'k_folds']
pub fn k_folds(values &i64, length usize) i64 {
	if unsafe { values == nil } || length != 2 { return -1 }
	sample_count := unsafe { values[0] }
	fold_count := unsafe { values[1] }
	if sample_count < 1 || sample_count > 12 || fold_count < 1 || fold_count > 12 { return -1 }
	width := (sample_count + fold_count - 1) / fold_count
	mut packed := u64(sample_count) << 48
	for index in 0 .. int(sample_count) {
		fold := u64((i64(index) + width) / width)
		packed |= fold << (4 * index)
	}
	return i64(packed)
}
