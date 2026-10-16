package binary_heap_indexed_operations

import "core:c"

put_i64_le :: proc "contextless" (out: [^]u8, slot: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { out[slot*8+b] = u8(bits & 255); bits >>= 8 }
}
sift_down :: proc "contextless" (h: [^]i64, size, start: int) {
	i := start
	for {
		left := 2*i+1; right := left+1; smallest := i
		if left < size && h[left] < h[smallest] do smallest = left
		if right < size && h[right] < h[smallest] do smallest = right
		if smallest == i do return
		h[i], h[smallest] = h[smallest], h[i]
		i = smallest
	}
}
bubble_up :: proc "contextless" (h: [^]i64, start: int) {
	i := start
	for i > 0 {
		parent := (i-1)/2
		if h[parent] <= h[i] do break
		h[parent], h[i] = h[i], h[parent]
		i = parent
	}
}

@(export)
binary_heap_indexed_operations :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || values[0] < 1 || values[0] > 256 || values[1] < 0 || values[1] > 512 || length != c.size_t(2+values[1]*3) do return -1
	var heap: [256]i64
	size := 0; outputs := 0
	for index := 0; index < int(values[1]); index += 1 {
		op := values[2+3*index]; a := values[3+3*index]; b := values[4+3*index]
		if op == 0 {
			if a < -2147483648 || a > 2147483647 || b != 0 do return -1
			if size < int(values[0]) { heap[size] = a; bubble_up(&heap[0], size); size += 1 }
		} else if op == 1 || op == 2 {
			if a != 0 || b != 0 || (op == 1 && size == 0) do return -1
			if output == nil || c.size_t((outputs+1)*8) > output_capacity do return -2
			result := i64(2147483647); if size > 0 do result = heap[0]
			if op == 2 && size > 0 { size -= 1; heap[0] = heap[size]; if size > 0 do sift_down(&heap[0],size,0) }
			put_i64_le(output,outputs,result); outputs += 1
		} else if op == 3 {
			if a < 0 || a >= i64(size) || b < -2147483648 || b > 2147483647 || b > heap[int(a)] do return -1
			heap[int(a)] = b; bubble_up(&heap[0],int(a))
		} else if op == 4 {
			if a < 0 || a >= i64(size) || b != 0 do return -1
			heap[int(a)] = -2147483648; bubble_up(&heap[0],int(a)); size -= 1; heap[0] = heap[size]; if size > 0 do sift_down(&heap[0],size,0)
		} else { return -1 }
	}
	return i64(outputs*8)
}
