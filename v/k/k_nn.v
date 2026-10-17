@[export: 'k_nn']
pub fn k_nn(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 300 { return -1 }
		training_value := input[0]
		feature_value := input[1]
		neighbor_value := input[2]
		if training_value < 1 || training_value > 32 || feature_value < 1 || feature_value > 8 ||
			neighbor_value < 1 || neighbor_value > training_value || neighbor_value % 2 == 0 { return -1 }
		training_count := int(training_value)
		feature_count := int(feature_value)
		neighbor_count := int(neighbor_value)
		feature_start := 3
		label_start := feature_start + training_count*feature_count
		query_start := label_start + training_count
		if length != usize(query_start+feature_count) { return -1 }
		for i in 0 .. training_count*feature_count {
			value := input[feature_start+i]
			if value < -32 || value > 32 { return -1 }
		}
		for row in 0 .. training_count {
			label := input[label_start+row]
			if label != 0 && label != 1 { return -1 }
		}
		for feature in 0 .. feature_count {
			value := input[query_start+feature]
			if value < -32 || value > 32 { return -1 }
		}
		mut query_norm := i64(0)
		for feature in 0 .. feature_count {
			query := input[query_start+feature]
			query_norm += query*query
		}
		mut distances := [32]i64{}
		mut order := [32]int{}
		for row in 0 .. training_count {
			mut row_norm := i64(0)
			mut cross_product := i64(0)
			for feature in 0 .. feature_count {
				coordinate := input[feature_start+row*feature_count+feature]
				query := input[query_start+feature]
				row_norm += coordinate*coordinate
				cross_product += coordinate*query
			}
			distances[row] = query_norm-2*cross_product+row_norm
			order[row] = row
		}
		for row in 0 .. training_count {
			for other in row+1 .. training_count {
				if distances[row] == distances[other] { return -1 }
			}
		}
		for position in 1 .. training_count {
			row := order[position]
			mut cursor := position
			for cursor > 0 && distances[order[cursor-1]] > distances[row] {
				order[cursor] = order[cursor-1]
				cursor--
			}
			order[cursor] = row
		}
		mut zero_votes := 0
		for position in 0 .. neighbor_count { if input[label_start+order[position]] == 0 { zero_votes++ } }
		if zero_votes > neighbor_count/2 { return 0 }
		return 1
	}
}
