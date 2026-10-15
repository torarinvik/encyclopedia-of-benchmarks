module apriori

const max_transactions = 64
const max_items = 12
const max_itemsets = 1 << max_items
const support_scale = i64(1_000_000)

fn item_count(value i64) int {
	mut mask := value
	mut count := 0
	for mask != 0 {
		count += int(mask & 1)
		mask >>= 1
	}
	return count
}

fn support_is_frequent(support i64, transaction_count i64, threshold_ppm i64) bool {
	return support * support_scale >= threshold_ppm * transaction_count
}

@[export: 'apriori']
pub fn apriori(input &i64, length usize) i64 {
	if length < 5 { return -1 }
	unsafe {
		transaction_count := input[0]
		items := input[1]
		min_support_ppm := input[2]
		min_confidence_ppm := input[3]
		if transaction_count < 1 || transaction_count > max_transactions || items < 1 || items > max_items ||
			min_support_ppm < 1 || min_support_ppm > support_scale || min_confidence_ppm < 0 ||
			min_confidence_ppm > support_scale || length != usize(4 + transaction_count) { return -1 }
		mask_limit := i64(1) << u32(items)
		mut transactions := []i64{len: max_transactions, init: 0}
		for index in 0 .. int(transaction_count) {
			if input[index + 4] < 0 || input[index + 4] >= mask_limit { return -1 }
			transactions[index] = input[index + 4]
		}
		mut supports := []i64{len: max_itemsets, init: 0}
		mut previous := []bool{len: max_itemsets, init: false}
		mut all_frequent := []bool{len: max_itemsets, init: false}
		mut current := []bool{len: max_itemsets, init: false}
		mut mask := i64(1)
		for mask < mask_limit {
			mut support := i64(0)
			for transaction in 0 .. int(transaction_count) {
				if (transactions[transaction] & mask) == mask { support++ }
			}
			if support_is_frequent(support, transaction_count, min_support_ppm) {
				supports[int(mask)] = support
				previous[int(mask)] = true
				all_frequent[int(mask)] = true
			}
			mask <<= 1
		}
		for size in 2 .. int(items) + 1 {
			for index in 0 .. max_itemsets { current[index] = false }
			mut found := false
			for candidate in 1 .. int(mask_limit) {
				if item_count(i64(candidate)) != size { continue }
				mut all_subsets_frequent := true
				for item in 0 .. int(items) {
					bit := i64(1) << u32(item)
					if (i64(candidate) & bit) != 0 && !previous[int(i64(candidate) ^ bit)] {
						all_subsets_frequent = false
						break
					}
				}
				if !all_subsets_frequent { continue }
				mut support := i64(0)
				for transaction in 0 .. int(transaction_count) {
					if (transactions[transaction] & i64(candidate)) == i64(candidate) { support++ }
				}
				if support_is_frequent(support, transaction_count, min_support_ppm) {
					supports[candidate] = support
					current[candidate] = true
					all_frequent[candidate] = true
					found = true
				}
			}
			for index in 0 .. max_itemsets { previous[index] = current[index] }
			if !found { break }
		}
		mut rule_count := i64(0)
		for candidate in 1 .. int(mask_limit) {
			if !all_frequent[candidate] || item_count(i64(candidate)) < 2 { continue }
			mut antecedent := (i64(candidate) - 1) & i64(candidate)
			for antecedent != 0 {
				if supports[candidate] * support_scale >= min_confidence_ppm * supports[int(antecedent)] { rule_count++ }
				antecedent = (antecedent - 1) & i64(candidate)
			}
		}
		return rule_count
	}
}
