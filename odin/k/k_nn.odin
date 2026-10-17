package k_nn

import "core:c"

MAX_INPUT_VALUES :: 300
MAX_TRAINING_COUNT :: 32
MAX_FEATURE_COUNT :: 8

@(export)
k_nn :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_VALUES do return -1
	training_value, feature_value, neighbor_value := input[0], input[1], input[2]
	if training_value < 1 || training_value > MAX_TRAINING_COUNT ||
		feature_value < 1 || feature_value > MAX_FEATURE_COUNT ||
		neighbor_value < 1 || neighbor_value > training_value || neighbor_value % 2 == 0 do return -1
	training_count, feature_count, neighbor_count := int(training_value), int(feature_value), int(neighbor_value)
	feature_start := 3
	label_start := feature_start + training_count*feature_count
	query_start := label_start + training_count
	if int(length) != query_start+feature_count do return -1
	for i := 0; i < training_count*feature_count; i += 1 {
		value := input[feature_start+i]
		if value < -32 || value > 32 do return -1
	}
	for row := 0; row < training_count; row += 1 {
		label := input[label_start+row]
		if label != 0 && label != 1 do return -1
	}
	for feature := 0; feature < feature_count; feature += 1 {
		value := input[query_start+feature]
		if value < -32 || value > 32 do return -1
	}
	query_norm := i64(0)
	for feature := 0; feature < feature_count; feature += 1 {
		query := input[query_start+feature]
		query_norm += query*query
	}
	distances: [MAX_TRAINING_COUNT]i64
	order: [MAX_TRAINING_COUNT]int
	for row := 0; row < training_count; row += 1 {
		row_norm, cross_product := i64(0), i64(0)
		for feature := 0; feature < feature_count; feature += 1 {
			coordinate := input[feature_start+row*feature_count+feature]
			query := input[query_start+feature]
			row_norm += coordinate*coordinate
			cross_product += coordinate*query
		}
		distances[row] = query_norm-2*cross_product+row_norm
		order[row] = row
	}
	for row := 0; row < training_count; row += 1 {
		for other := row+1; other < training_count; other += 1 {
			if distances[row] == distances[other] do return -1
		}
	}
	for position := 1; position < training_count; position += 1 {
		row := order[position]
		cursor := position
		for cursor > 0 && distances[order[cursor-1]] > distances[row] {
			order[cursor] = order[cursor-1]
			cursor -= 1
		}
		order[cursor] = row
	}
	zero_votes := 0
	for position := 0; position < neighbor_count; position += 1 {
		if input[label_start+order[position]] == 0 do zero_votes += 1
	}
	if zero_votes > neighbor_count/2 do return 0
	return 1
}
