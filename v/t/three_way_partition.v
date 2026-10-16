module three_way_partition

@[export: 'three_way_partition']
pub fn three_way_partition(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 2 || length > 258 { return -1 }
	n := input[0]
	pivot := input[1]
	if n < 0 || n > 256 || length != usize(n + 2) || pivot < -2147483648 || pivot > 2147483647 { return -1 }
	mut a := []i32{len: int(n)}
	for i in 0 .. int(n) { if input[i + 2] < -2147483648 || input[i + 2] > 2147483647 { return -1 }; a[i] = i32(input[i + 2]) }
	mut low := 0
	mut mid := 0
	mut high := int(n)
	for mid < high { if i64(a[mid]) < pivot { a[low], a[mid] = a[mid], a[low]; low++; mid++ } else if i64(a[mid]) > pivot { high--; a[mid], a[high] = a[high], a[mid] } else { mid++ } }
	bytes := usize(n + 2) * 4
	if capacity < bytes { return -2 }
	out32 := unsafe { &i32(output) }
	for i in 0 .. int(n) { unsafe { out32[i] = a[i] } }
	unsafe { out32[int(n)] = i32(low); out32[int(n) + 1] = i32(high) }
	return n + 2
}
