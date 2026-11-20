module crust_opposite_pole_selection

const max_samples = 8
const max_cell_vertices = 8

fn put_i64_le(mut output &u8, word int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[word * 8 + b] = u8((bits >> (8 * b)) & 255) } }
}

fn same_point(a [3]i64, b [3]i64) bool { return a[0] == b[0] && a[1] == b[1] && a[2] == b[2] }

@[export: 'crust_opposite_pole_selection']
pub fn crust_opposite_pole_selection(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 1 || length > 226 { return -1 }
	n0 := unsafe { input[0] }
	if n0 < 1 || n0 > 8 { return -1 }
	n := int(n0)
	mut samples := [max_samples][3]i64{}
	mut answer := [max_samples][2]i64{}
	mut offset := 1
	for row in 0 .. n {
		if offset + 4 > int(length) { return -1 }
		sample := [3]i64{unsafe { input[offset] }, unsafe { input[offset + 1] }, unsafe { input[offset + 2] }}
		count0 := unsafe { input[offset + 3] }
		offset += 4
		if count0 < 1 || count0 > max_cell_vertices { return -1 }
		for axis in 0 .. 3 { if sample[axis] < -16 || sample[axis] > 16 { return -1 } }
		for prev in 0 .. row { if same_point(sample, samples[prev]) { return -1 } }
		samples[row] = sample
		count := int(count0)
		if offset + 3 * count > int(length) { return -1 }
		mut cell := [max_cell_vertices][3]i64{}
		for vertex in 0 .. count {
			for axis in 0 .. 3 {
				cell[vertex][axis] = unsafe { input[offset] }
				offset++
				if cell[vertex][axis] < -16 || cell[vertex][axis] > 16 { return -1 }
			}
			if same_point(cell[vertex], sample) { return -1 }
			for prev in 0 .. vertex { if same_point(cell[vertex], cell[prev]) { return -1 } }
		}
		mut positive := 0
		mut positive_distance := i64(-1)
		for vertex in 0 .. count {
			mut distance := i64(0)
			for axis in 0 .. 3 {
				delta := cell[vertex][axis] - sample[axis]
				distance += delta * delta
			}
			if distance > positive_distance { positive_distance = distance; positive = vertex }
		}
		mut forward := [3]i64{}
		for axis in 0 .. 3 { forward[axis] = cell[positive][axis] - sample[axis] }
		mut negative := i64(-1)
		mut negative_distance := i64(-1)
		for vertex in 0 .. count {
			mut distance := i64(0)
			mut projection := i64(0)
			for axis in 0 .. 3 {
				delta := cell[vertex][axis] - sample[axis]
				distance += delta * delta
				projection += delta * forward[axis]
			}
			if projection < 0 && distance > negative_distance { negative_distance = distance; negative = i64(vertex) }
		}
		answer[row] = [2]i64{i64(positive), negative}
	}
	if offset != int(length) { return -1 }
	bytes := 8 * (1 + 2 * n)
	if output == nil || capacity < usize(bytes) { return -2 }
	put_i64_le(mut output, 0, n0)
	mut word := 1
	for row in 0 .. n {
		put_i64_le(mut output, word, answer[row][0]); word++
		put_i64_le(mut output, word, answer[row][1]); word++
	}
	return i64(bytes)
}
