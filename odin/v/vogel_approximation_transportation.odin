package vogel_approximation_transportation

import "core:c"

MAX_LENGTH :: 18

@(export)
vogel_approximation_transportation :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 5 || length > c.size_t(MAX_LENGTH) do return -1
	if input[0] < 1 || input[0] > 3 || input[1] < 1 || input[1] > 3 do return -1
	rows := int(input[0])
	cols := int(input[1])
	cell_count := rows * cols
	if length != c.size_t(2 + cell_count + rows + cols) do return -1

	costs: [9]i64 = {}
	supply: [3]i64 = {}
	demand: [3]i64 = {}
	offset := 2
	for i in 0..<cell_count {
		value := input[offset + i]
		if value < 0 || value > 9 do return -1
		costs[i] = value
	}
	offset += cell_count
	supply_total: i64 = 0
	demand_total: i64 = 0
	for i in 0..<rows {
		value := input[offset + i]
		if value < 1 || value > 3 do return -1
		supply[i] = value
		supply_total += value
	}
	offset += rows
	for j in 0..<cols {
		value := input[offset + j]
		if value < 1 || value > 3 do return -1
		demand[j] = value
		demand_total += value
	}
	if supply_total != demand_total do return -1

	active_rows: [3]bool = {true, true, true}
	active_cols: [3]bool = {true, true, true}
	allocation: [9]i64 = {}
	total_cost: i64 = 0
	remaining := supply_total
	for remaining > 0 {
		best_kind := -1
		best_line := 0
		best_penalty: i64 = -1
		for kind in 0..<2 {
			line_count := rows
			partner_count := cols
			if kind == 1 { line_count = cols; partner_count = rows }
			for line in 0..<line_count {
				if !(if kind == 0 { active_rows[line] } else { active_cols[line] }) do continue
				first: i64 = 10
				second: i64 = 10
				found := 0
				for partner in 0..<partner_count {
					if !(if kind == 0 { active_cols[partner] } else { active_rows[partner] }) do continue
					row := line
					col := partner
					if kind == 1 { row = partner; col = line }
					value := costs[row * cols + col]
					if value < first { second = first; first = value }
					else if value < second { second = value }
					found += 1
				}
				if found == 0 do continue
				penalty: i64 = second - first
				if found == 1 { penalty = 10 }
				if penalty > best_penalty { best_penalty = penalty; best_kind = kind; best_line = line }
			}
		}
		if best_kind < 0 do return -1
		partner_count := cols
		if best_kind == 1 { partner_count = rows }
		best_partner := partner_count
		cheapest: i64 = 10
		for partner in 0..<partner_count {
			if !(if best_kind == 0 { active_cols[partner] } else { active_rows[partner] }) do continue
			row := best_line
			col := partner
			if best_kind == 1 { row = partner; col = best_line }
			value := costs[row * cols + col]
			if value < cheapest { cheapest = value; best_partner = partner }
		}
		if best_partner == partner_count do return -1
		row := best_line
		col := best_partner
		if best_kind == 1 { row = best_partner; col = best_line }
		quantity := supply[row]
		if demand[col] < quantity { quantity = demand[col] }
		allocation[row * 3 + col] = quantity
		total_cost += quantity * costs[row * cols + col]
		supply[row] -= quantity
		demand[col] -= quantity
		remaining -= quantity
		if supply[row] == 0 { active_rows[row] = false }
		if demand[col] == 0 { active_cols[col] = false }
	}

	signature: i64 = 0
	place: i64 = 1
	for cell in 0..<9 { signature += allocation[cell] * place; place *= 4 }
	return total_cost * place + signature
}
