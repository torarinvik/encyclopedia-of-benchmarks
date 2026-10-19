module string_heap_sort

const max_keys = 64
const width = 4

fn sift_down(mut a [max_keys]u32, root_value int, ending int) {
	mut root := root_value
	for root < ending / 2 {
		mut child := 2 * root + 1
		if child + 1 < ending && a[child] < a[child + 1] { child++ }
		if a[root] >= a[child] { break }
		 t := a[root]; a[root] = a[child]; a[child] = t
		root = child
	}
}

@[export: 'string_heap_sort']
pub fn string_heap_sort(values &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > 257 { return -1 }
		raw_count := values[0]
		if raw_count < 0 || raw_count > max_keys || length != usize(1 + width * int(raw_count)) { return -1 }
		count := int(raw_count)
		mut keys := [max_keys]u32{init: 0}
		for i in 0 .. count {
			mut key := u32(0)
			for b in 0 .. width {
				x := values[1 + width*i + b]
				if x < 0 || x > 127 { return -1 }
				key = (key << 8) | u32(x)
			}
			keys[i] = key
		}
		mut start := count / 2
		for start > 0 { start--; sift_down(mut keys, start, count) }
		mut ending := count
		for ending > 1 {
			ending--
			t := keys[0]; keys[0] = keys[ending]; keys[ending] = t
			sift_down(mut keys, 0, ending)
		}
		byte_count := count * width
		if output == nil || output_capacity < usize(byte_count) { return -2 }
		for i in 0 .. count {
			for b in 0 .. width { output[i*width+b] = u8((keys[i] >> u32(24-8*b)) & 255) }
		}
		return i64(byte_count)
	}
}
