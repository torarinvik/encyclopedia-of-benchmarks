package apriori

import "core:c"

MAX_TRANSACTIONS :: 64
MAX_ITEMS :: 12
MAX_ITEMSETS :: 4096
SUPPORT_SCALE :: i64(1_000_000)

item_count :: proc "contextless" (value: i64) -> int {
	mask := value
	count := 0
	for mask != 0 {
		count += int(mask & 1)
		mask = mask >> 1
	}
	return count
}

support_is_frequent :: proc "contextless" (support, transaction_count, threshold_ppm: i64) -> bool {
	return support * SUPPORT_SCALE >= threshold_ppm * transaction_count
}

@(export)
apriori :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 5 do return -1
	transaction_count := input[0]
	items := input[1]
	min_support_ppm := input[2]
	min_confidence_ppm := input[3]
	if transaction_count < 1 || transaction_count > MAX_TRANSACTIONS || items < 1 || items > MAX_ITEMS ||
		min_support_ppm < 1 || min_support_ppm > SUPPORT_SCALE || min_confidence_ppm < 0 ||
		min_confidence_ppm > SUPPORT_SCALE || length != c.size_t(4 + transaction_count) {
		return -1
	}

	mask_limit := i64(1) << u32(items)
	transactions: [MAX_TRANSACTIONS]i64
	for index := 0; index < int(transaction_count); index += 1 {
		if input[index+4] < 0 || input[index+4] >= mask_limit do return -1
		transactions[index] = input[index+4]
	}

	supports: [MAX_ITEMSETS]i64
	previous: [MAX_ITEMSETS]bool
	all_frequent: [MAX_ITEMSETS]bool
	current: [MAX_ITEMSETS]bool
	for mask := i64(1); mask < mask_limit; mask <<= 1 {
		support := i64(0)
		for transaction := 0; transaction < int(transaction_count); transaction += 1 {
			if (transactions[transaction] & mask) == mask do support += 1
		}
		if support_is_frequent(support, transaction_count, min_support_ppm) {
			supports[int(mask)] = support
			previous[int(mask)] = true
			all_frequent[int(mask)] = true
		}
	}

	for size := 2; size <= int(items); size += 1 {
		for index := 0; index < MAX_ITEMSETS; index += 1 { current[index] = false }
		found := false
		for candidate := i64(1); candidate < mask_limit; candidate += 1 {
			if item_count(candidate) != size do continue
			all_subsets_frequent := true
			for item := 0; item < int(items); item += 1 {
				bit := i64(1) << u32(item)
				subset := candidate ~ bit
				if (candidate & bit) != 0 && !previous[int(subset)] {
					all_subsets_frequent = false
					break
				}
			}
			if !all_subsets_frequent do continue
			support := i64(0)
			for transaction := 0; transaction < int(transaction_count); transaction += 1 {
				if (transactions[transaction] & candidate) == candidate do support += 1
			}
			if support_is_frequent(support, transaction_count, min_support_ppm) {
				supports[int(candidate)] = support
				current[int(candidate)] = true
				all_frequent[int(candidate)] = true
				found = true
			}
		}
		previous = current
		if !found do break
	}

	rule_count := i64(0)
	for candidate := i64(1); candidate < mask_limit; candidate += 1 {
		if !all_frequent[int(candidate)] || item_count(candidate) < 2 do continue
		antecedent := (candidate - 1) & candidate
		for antecedent != 0 {
			if supports[int(candidate)]*SUPPORT_SCALE >= min_confidence_ppm*supports[int(antecedent)] do rule_count += 1
			antecedent = (antecedent - 1) & candidate
		}
	}
	return rule_count
}
