module rodinia_hybridsort

fn bucket(value f32, minimum f32, span f32) int {
	mut index := int(((value-minimum)/span)*1024.0)
	if index < 0 { index = 0 }
	if index >= 1024 { index = 1023 }
	return index
}

fn merge_sort(mut items []i64, mut scratch []i64) {
	count := items.len
	mut width := 1
	for width < count {
		mut left := 0
		for left < count {
			middle := if left+width < count { left+width } else { count }
			right := if left+2*width < count { left+2*width } else { count }
			mut a := left; mut b := middle; mut out := left
			for a < middle && b < right { if items[a] <= items[b] { scratch[out] = items[a]; a++ } else { scratch[out] = items[b]; b++ }; out++ }
			for a < middle { scratch[out] = items[a]; a++; out++ }
			for b < right { scratch[out] = items[b]; b++; out++ }
			left += 2*width
		}
		for i := 0; i < count; i++ { items[i] = scratch[i] }
		width *= 2
	}
}

fn put_i64(output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for b := 0; b < 8; b++ { output[offset+b] = u8(bits >> (8*b)) }
	}
}

@[export: 'rodinia_hybridsort']
pub fn rodinia_hybridsort(input &i64, length usize, output &u8, capacity usize) i64 {
	if length < 3 || length > 65 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > 64 || length != usize(input[0]+1) { return -1 }
		count := int(input[0]); mut items := []i64{len: count}; mut scratch := []i64{len: count}
		mut min_raw := i64(9223372036854775807); mut max_raw := i64(-9223372036854775807-1)
		for i := 0; i < count; i++ {
			x := input[1+i]
			if x < 0 || x > 1000000 || x % 1000 != 0 { return -1 }
			items[i] = x; if x < min_raw { min_raw = x }; if x > max_raw { max_raw = x }
		}
		if min_raw == max_raw { return -1 }
		bytes := count*8; if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
		minimum := f32(min_raw)/1000000.0; maximum := f32(max_raw)/1000000.0; span := maximum-minimum
		mut histogram := []int{len: 1024}; mut offsets := []int{len: 1025}; mut next := []int{len: 1024}; mut scattered := []i64{len: count}
		for i := 0; i < count; i++ { histogram[bucket(f32(items[i])/1000000.0, minimum, span)]++ }
		for b := 0; b < 1024; b++ { offsets[b+1] = offsets[b]+histogram[b]; next[b] = offsets[b] }
		for i := 0; i < count; i++ { b := bucket(f32(items[i])/1000000.0, minimum, span); scattered[next[b]] = items[i]; next[b]++ }
		for b := 0; b < 1024; b++ { start := offsets[b]; end := offsets[b+1]; if end > start { merge_sort(mut scattered[start..end], mut scratch[..end-start]) } }
		for i := 0; i < count; i++ { put_i64(output, i*8, scattered[i]) }
		return i64(bytes)
	}
}
