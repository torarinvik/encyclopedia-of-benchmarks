fn mpls_key(mask int, distances [8]int, n int) i64 {
	mut score := i64(0)
	mut bits := 0
	for i in 0 .. n { if mask & (1 << i) != 0 { score += i64(distances[i]*distances[i]); bits++ } }
	return score*2304 + i64(bits*256+mask)
}
fn mpls_push(mut heap [256]int, size int, mask int, distances [8]int, n int) int {
	mut at := size
	key := mpls_key(mask, distances, n)
	for at > 0 && key < mpls_key(heap[(at-1)/2], distances, n) { heap[at] = heap[(at-1)/2]; at = (at-1)/2 }
	heap[at] = mask
	return size+1
}
fn mpls_pop(mut heap [256]int, size int, distances [8]int, n int) int {
	result := heap[0]
	remaining := size-1
	last := heap[remaining]
	mut at := 0
	for 2*at+1 < remaining {
		mut child := 2*at+1
		if child+1 < remaining && mpls_key(heap[child+1], distances, n) < mpls_key(heap[child], distances, n) { child++ }
		if mpls_key(heap[child], distances, n) >= mpls_key(last, distances, n) { break }
		heap[at] = heap[child]; at = child
	}
	if remaining > 0 { heap[at] = last }
	return result
}
@[export: 'multiprobe_lsh_probe_sequence']
pub fn multiprobe_lsh_probe_sequence(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 7 || input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 1000 { return -1 }
		m := int(input[0]); width := int(input[1]); mut limit := 1
		for _ in 0 .. m { limit *= 3 }
		if length != usize(3+m) || input[2] < 0 || input[2] >= i64(limit) { return -1 }
		count := int(input[2])
		mut distances := [8]int{}; mut coords := [8]int{}; mut signs := [8]int{}
		for i in 0 .. m {
			if input[3+i] < 0 || input[3+i] > i64(width) { return -1 }
			distances[2*i] = int(input[3+i]); distances[2*i+1] = width-distances[2*i]
			coords[2*i] = i; coords[2*i+1] = i; signs[2*i] = -1; signs[2*i+1] = 1
		}
		for i in 1 .. 2*m {
			d := distances[i]; c := coords[i]; s := signs[i]; mut j := i
			for j > 0 && (distances[j-1] > d || (distances[j-1] == d && (coords[j-1] > c || (coords[j-1] == c && signs[j-1] > s)))) {
				distances[j] = distances[j-1]; coords[j] = coords[j-1]; signs[j] = signs[j-1]; j--
			}
			distances[j] = d; coords[j] = c; signs[j] = s
		}
		mut heap := [256]int{}; mut result := [80]u8{}
		mut size := mpls_push(mut heap, 0, 1, distances, 2*m); mut emitted := 0
		for emitted < count {
			mask := mpls_pop(mut heap, size, distances, 2*m); size--; mut top := 0
			for (1 << (top+1)) <= mask { top++ }
			if top+1 < 2*m {
				size = mpls_push(mut heap, size, (mask ^ (1 << top)) | (1 << (top+1)), distances, 2*m)
				size = mpls_push(mut heap, size, mask | (1 << (top+1)), distances, 2*m)
			}
			mut seen := 0; mut valid := true
			for i in 0 .. 2*m { if mask & (1 << i) != 0 { bit := 1 << coords[i]; if seen & bit != 0 { valid = false; break }; seen |= bit } }
			if valid { result[emitted] = u8(mask); emitted++ }
		}
		if output == nil || capacity < usize(count) { return -2 }
		for i in 0 .. count { output[i] = result[i] }
		return i64(count)
	}
}
