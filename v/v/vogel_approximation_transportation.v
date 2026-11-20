module vogel_approximation_transportation

const max_length = 18

@[export: 'vogel_approximation_transportation']
pub fn vogel_approximation_transportation(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_length { return -1 }
		if input[0] < 1 || input[0] > 3 || input[1] < 1 || input[1] > 3 { return -1 }
		rows := int(input[0])
		cols := int(input[1])
		cell_count := rows * cols
		if length != usize(2 + cell_count + rows + cols) { return -1 }

		mut costs := [9]i64{}
		mut supply := [3]i64{}
		mut demand := [3]i64{}
		mut offset := 2
		for i in 0 .. cell_count {
			value := input[offset + i]
			if value < 0 || value > 9 { return -1 }
			costs[i] = value
		}
		offset += cell_count
		mut supply_total := i64(0)
		mut demand_total := i64(0)
		for i in 0 .. rows {
			value := input[offset + i]
			if value < 1 || value > 3 { return -1 }
			supply[i] = value
			supply_total += value
		}
		offset += rows
		for j in 0 .. cols {
			value := input[offset + j]
			if value < 1 || value > 3 { return -1 }
			demand[j] = value
			demand_total += value
		}
		if supply_total != demand_total { return -1 }

		mut active_rows := [3]bool{true, true, true}
		mut active_cols := [3]bool{true, true, true}
		mut allocation := [9]i64{}
		mut total_cost := i64(0)
		mut remaining := supply_total
		for remaining > 0 {
			mut best_kind := -1
			mut best_line := 0
			mut best_penalty := i64(-1)
			for kind in 0 .. 2 {
				line_count := if kind == 0 { rows } else { cols }
				partner_count := if kind == 0 { cols } else { rows }
				for line in 0 .. line_count {
					if !(if kind == 0 { active_rows[line] } else { active_cols[line] }) { continue }
					mut first := i64(10)
					mut second := i64(10)
					mut found := 0
					for partner in 0 .. partner_count {
						if !(if kind == 0 { active_cols[partner] } else { active_rows[partner] }) { continue }
						row := if kind == 0 { line } else { partner }
						col := if kind == 0 { partner } else { line }
						value := costs[row * cols + col]
						if value < first { second = first; first = value }
						else if value < second { second = value }
						found++
					}
					if found == 0 { continue }
					penalty := if found == 1 { i64(10) } else { second - first }
					if penalty > best_penalty { best_penalty = penalty; best_kind = kind; best_line = line }
				}
			}
			if best_kind < 0 { return -1 }
			partner_count := if best_kind == 0 { cols } else { rows }
			mut best_partner := partner_count
			mut cheapest := i64(10)
			for partner in 0 .. partner_count {
				if !(if best_kind == 0 { active_cols[partner] } else { active_rows[partner] }) { continue }
				row := if best_kind == 0 { best_line } else { partner }
				col := if best_kind == 0 { partner } else { best_line }
				value := costs[row * cols + col]
				if value < cheapest { cheapest = value; best_partner = partner }
			}
			if best_partner == partner_count { return -1 }
			row := if best_kind == 0 { best_line } else { best_partner }
			col := if best_kind == 0 { best_partner } else { best_line }
			quantity := if supply[row] < demand[col] { supply[row] } else { demand[col] }
			allocation[row * 3 + col] = quantity
			total_cost += quantity * costs[row * cols + col]
			supply[row] -= quantity
			demand[col] -= quantity
			remaining -= quantity
			if supply[row] == 0 { active_rows[row] = false }
			if demand[col] == 0 { active_cols[col] = false }
		}

		mut signature := i64(0)
		mut place := i64(1)
		for cell in 0 .. 9 { signature += allocation[cell] * place; place *= 4 }
		return total_cost * place + signature
	}
}
