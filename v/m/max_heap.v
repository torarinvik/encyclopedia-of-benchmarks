module max_heap

const max_operations = 512
const max_insertions = 256

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'max_heap']
pub unsafe fn max_heap(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	operations64 := unsafe { input[0] }
	if operations64 < 0 || operations64 > max_operations { return -1 }
	operations := int(operations64)
	if int(length) != 1 + operations * 2 { return -1 }
	mut inserts := 0
	mut words := 0
	for i in 0 .. operations {
		op := unsafe { input[1 + 2 * i] }; value := unsafe { input[2 + 2 * i] }
		if op < 0 || op > 2 { return -1 }
		if op == 0 { inserts++; if inserts > max_insertions || value < -2147483648 || value > 2147483647 { return -1 } }
		else { if value != 0 { return -1 }; words++ }
	}
	if int(capacity) < words * 8 || (words > 0 && unsafe { output == nil }) { return -2 }
	mut heap := [max_insertions]i64{}
	mut size := 0
	mut out_index := 0
	for i in 0 .. operations {
		op := unsafe { input[1 + 2 * i] }; value := unsafe { input[2 + 2 * i] }
		if op == 0 {
			mut at := size; heap[at] = value; size++
			for at > 0 { parent := (at - 1) / 2; if heap[parent] >= heap[at] { break }; temp := heap[parent]; heap[parent] = heap[at]; heap[at] = temp; at = parent }
			continue
		}
		mut result := i64(-9223372036854775808)
		if size > 0 {
			result = heap[0]
			if op == 2 { size--; heap[0] = heap[size]; mut at := 0
				for at < size / 2 { mut child := at * 2 + 1; if child + 1 < size && heap[child + 1] > heap[child] { child++ }; if heap[at] >= heap[child] { break }; temp := heap[at]; heap[at] = heap[child]; heap[child] = temp; at = child }
			}
		}
		store_i64_le(output, out_index * 8, result); out_index++
	}
	return i64(words)
}
