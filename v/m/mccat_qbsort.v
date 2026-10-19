module mccat_qbsort

fn bubble(mut a []i32) {
	if a.len < 2 { return }
	for end := a.len; end > 1; end-- {
		for i := 0; i + 1 < end; i++ { if a[i + 1] < a[i] { t := a[i]; a[i] = a[i + 1]; a[i + 1] = t } }
	}
}
fn quick(mut a []i32) {
	if a.len < 2 { return }
	pivot := a[0]
	mut lower := []i32{}
	mut upper := []i32{}
	for i in 1 .. a.len { if a[i] < pivot { lower << a[i] } else { upper << a[i] } }
	quick(mut upper); quick(mut lower)
	mut k := 0
	for value in lower { a[k] = value; k++ }
	a[k] = pivot; k++
	for value in upper { a[k] = value; k++ }
}

@[export: 'mccat_qbsort']
pub fn mccat_qbsort(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if input == nil || length < 3 || length > 34 { return -1 }
	mode := unsafe { input[0] }; count_value := unsafe { input[1] }
	if (mode != 0 && mode != 1) || count_value < 1 || count_value > 32 { return -1 }
	n := int(count_value)
	if length != usize(n + 2) { return -1 }
	mut values := []i32{len: n, init: 0}
	for i in 0 .. n {
		value := unsafe { input[i + 2] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[i] = i32(value)
	}
	for _ in 0 .. 1000 {
		for i in 0 .. n { values[i] = i32(unsafe { input[i + 2] }) }
		if mode == 0 { bubble(mut values) } else { quick(mut values) }
	}
	need := n * 4
	if output == nil || output_capacity < usize(need) { return -2 }
	for i in 0 .. n {
		bits := u32(values[i])
		for b in 0 .. 4 { unsafe { output[i * 4 + b] = u8((bits >> (8 * b)) & 255) } }
	}
	return i64(need)
}
