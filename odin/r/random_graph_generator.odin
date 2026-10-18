package random_graph_generator

import "core:c"

MAX_PARSEABLE_INPUT_LENGTH :: 2020
MAX_OUTPUT_BYTES :: 4096
DRAW_SCALE :: i64(9007199254740992)
MIN_PROBABILITY_UNITS :: i64(-9007199254740992)
MAX_PROBABILITY_UNITS :: i64(18014398509481984)

@(export)
random_graph_generator :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	vertex_count_raw, directed, probability_units := input[0], input[1], input[2]
	if vertex_count_raw < 0 || vertex_count_raw > 64 || (directed != 0 && directed != 1) do return -1
	if probability_units < MIN_PROBABILITY_UNITS || probability_units > MAX_PROBABILITY_UNITS do return -1
	vertex_count := int(vertex_count_raw)
	pair_count := 0
	if vertex_count >= 2 do pair_count = vertex_count * (vertex_count - 1) / 2
	draw_count := 0
	if probability_units > 0 && probability_units < DRAW_SCALE do draw_count = pair_count
	if int(input_length) != 3 + draw_count do return -1
	for index := 0; index < draw_count; index += 1 {
		draw := input[3 + index]
		if draw < 0 || draw >= DRAW_SCALE do return -1
	}

	staged: [MAX_OUTPUT_BYTES]u8
	if probability_units >= DRAW_SCALE {
		for source := 0; source < vertex_count; source += 1 {
			for target := 0; target < vertex_count; target += 1 {
				if source != target do staged[source * vertex_count + target] = 1
			}
		}
	} else if probability_units > 0 {
		draw_index := 0
		for source := 0; source < vertex_count; source += 1 {
			for target := source + 1; target < vertex_count; target += 1 {
				if input[3 + draw_index] < probability_units {
					staged[source * vertex_count + target] = 1
					if directed == 0 do staged[target * vertex_count + source] = 1
				}
				draw_index += 1
			}
		}
	}

	output_bytes := vertex_count * vertex_count
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < output_bytes; index += 1 { output[index] = staged[index] }
	return i64(output_bytes)
}
