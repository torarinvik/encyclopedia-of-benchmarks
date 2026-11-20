const max_vertices = 7
const max_shapes = 48
const max_width = 15
const max_candidates = 37
const max_output = 674

struct Candidate {
	size int
	text string
}

fn enumerate_multisets(candidates []Candidate, start int, remaining int,
	children string, mut generated []string) {
	if remaining == 0 {
		generated << "(" + children + ")"
		return
	}
	for index := start; index < candidates.len; index++ {
		candidate := candidates[index]
		if candidate.size <= remaining {
			enumerate_multisets(candidates, index, remaining - candidate.size,
				children + candidate.text, mut generated)
		}
	}
}

fn build_shapes(maximum int) [][]string {
	mut levels := [][]string{len: max_vertices + 1}
	levels[1] = ['()']
	for target := 2; target <= maximum; target++ {
		mut candidates := []Candidate{}
		for size in 1 .. target {
			for shape in levels[size] {
				candidate := Candidate{size: size, text: shape}
				mut position := candidates.len
				for position > 0 && candidate.text < candidates[position - 1].text {
					position--
				}
			candidates.insert(position, candidate)
			}
		}
		mut generated := []string{}
		enumerate_multisets(candidates, 0, target - 1, '', mut generated)
		generated.sort()
		levels[target] = generated
	}
	return levels
}

@[export: 'list_rooted_trees']
pub fn list_rooted_trees(v &i64, n usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if v == nil || n != 1 || v[0] < 1 || v[0] > max_vertices {
			return -1
		}
		vertices := int(v[0])
		levels := build_shapes(vertices)
		shapes := levels[vertices]
		mut staged := []u8{len: max_output}
		staged[0] = u8(shapes.len)
		staged[1] = u8(shapes.len >> 8)
		mut position := 2
		for shape in shapes {
			for index, byte in shape.bytes() {
				staged[position + index] = byte
			}
			position += shape.len
		}
		if output == nil || capacity < position {
			return -2
		}
		mut output_slice := output[0..capacity]
		for index in 0 .. position {
			output_slice[index] = staged[index]
		}
		return i64(position)
	}
}
