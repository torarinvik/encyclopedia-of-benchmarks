package list_rooted_trees

import "core:c"

MAX_VERTICES :: 7
MAX_SHAPES :: 48
MAX_WIDTH :: 14
MAX_CANDIDATES :: 37
MAX_OUTPUT :: 674

Candidate :: struct {
	size: int,
	text: [MAX_WIDTH]u8,
}

Generator :: struct {
	shapes: [MAX_VERTICES + 1][MAX_SHAPES][MAX_WIDTH]u8,
	counts: [MAX_VERTICES + 1]int,
	target: int,
}

candidate_less :: proc(left, right: Candidate) -> bool {
	for index := 0; index < MAX_WIDTH; index += 1 {
		if left.text[index] < right.text[index] do return true
		if left.text[index] > right.text[index] do return false
	}
	return false
}

shape_less :: proc(left, right: [MAX_WIDTH]u8, width: int) -> bool {
	for index := 0; index < width; index += 1 {
		if left[index] < right[index] do return true
		if left[index] > right[index] do return false
	}
	return false
}

enumerate_multisets :: proc(generator: ^Generator, candidates: [^]Candidate,
		candidate_count, start, remaining: int, children: [^]u8, child_length: int) {
	if remaining == 0 {
		shape_index := generator.counts[generator.target]
		generator.shapes[generator.target][shape_index][0] = u8('(')
		for index := 0; index < child_length; index += 1 {
			generator.shapes[generator.target][shape_index][index + 1] = children[index]
		}
		generator.shapes[generator.target][shape_index][child_length + 1] = u8(')')
		generator.counts[generator.target] += 1
		return
	}

	for index := start; index < candidate_count; index += 1 {
		child_size := candidates[index].size
		if child_size > remaining do continue
		encoded_length := 2 * child_size
		for byte := 0; byte < encoded_length; byte += 1 {
			children[child_length + byte] = candidates[index].text[byte]
		}
		enumerate_multisets(generator, candidates, candidate_count, index,
			remaining - child_size, children, child_length + encoded_length)
	}
}

@(export)
list_rooted_trees :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != c.size_t(1) do return -1
	if input[0] < 1 || input[0] > MAX_VERTICES do return -1
	vertices := int(input[0])

	generator: Generator
	generator.counts[1] = 1
	generator.shapes[1][0][0] = u8('(')
	generator.shapes[1][0][1] = u8(')')
	for target := 2; target <= vertices; target += 1 {
		generator.target = target
		candidates: [MAX_CANDIDATES]Candidate = {}
		candidate_count := 0
		for size := 1; size < target; size += 1 {
			for shape_index := 0; shape_index < generator.counts[size]; shape_index += 1 {
				candidates[candidate_count].size = size
				for byte := 0; byte < MAX_WIDTH; byte += 1 {
					candidates[candidate_count].text[byte] = generator.shapes[size][shape_index][byte]
				}
				candidate_count += 1
			}
		}
		for index := 1; index < candidate_count; index += 1 {
			saved := candidates[index]
			place := index
			for place > 0 && candidate_less(saved, candidates[place - 1]) {
				candidates[place] = candidates[place - 1]
				place -= 1
			}
			candidates[place] = saved
		}

		children: [MAX_WIDTH]u8 = {}
		enumerate_multisets(&generator, &candidates[0], candidate_count, 0,
			target - 1, &children[0], 0)

		width := 2 * target
		for index := 1; index < generator.counts[target]; index += 1 {
			saved := generator.shapes[target][index]
			place := index
			for place > 0 && shape_less(saved, generator.shapes[target][place - 1], width) {
				generator.shapes[target][place] = generator.shapes[target][place - 1]
				place -= 1
			}
			generator.shapes[target][place] = saved
		}
	}

	count := generator.counts[vertices]
	width := 2 * vertices
	needed := 2 + count * width
	staged: [MAX_OUTPUT]u8 = {}
	staged[0] = u8(count & 0xff)
	staged[1] = u8((count >> 8) & 0xff)
	position := 2
	for shape_index := 0; shape_index < count; shape_index += 1 {
		for byte := 0; byte < width; byte += 1 {
			staged[position] = generator.shapes[vertices][shape_index][byte]
			position += 1
		}
	}

	if output == nil || capacity < c.size_t(needed) do return -2
	for byte := 0; byte < needed; byte += 1 do output[byte] = staged[byte]
	return i64(needed)
}
