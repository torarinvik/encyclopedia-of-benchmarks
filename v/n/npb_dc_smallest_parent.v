// Bounded clean-room NASA NPB DC smallest-parent profile; see NAS-03-005.
module npb_dc_smallest_parent

const max_dims = 5
const max_rows = 16
const max_masks = 32

fn popcount(value int) int {
	mut bits := value
	mut count := 0
	for bits != 0 {
		count += bits & 1
		bits >>= 1
	}
	return count
}

@[export: 'npb_dc_smallest_parent']
pub fn npb_dc_smallest_parent(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > 98 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_dims || input[1] < 1 || input[1] > max_rows { return -1 }
		dimensions := int(input[0])
		rows := int(input[1])
		if int(length) != 2 + rows * (dimensions + 1) { return -1 }
		mut attributes := [max_rows][max_dims]i64{}
		mut measures := [max_rows]i64{}
		mut offset := 2
		for row in 0 .. rows {
			for dimension in 0 .. dimensions {
				value := input[offset]
				offset++
				if value < 0 || value > 7 { return -1 }
				attributes[row][dimension] = value
			}
			measures[row] = input[offset]
			offset++
			if measures[row] < 0 || measures[row] > 1000 { return -1 }
		}
		mut keys := [max_masks][max_rows][max_dims]i64{}
		mut sums := [max_masks][max_rows]i64{}
		mut counts := [max_masks]int{}
		mut parents := [max_masks]int{}
		for mask in 0 .. max_masks { parents[mask] = -2 }
		full := (1 << dimensions) - 1
		parents[full] = -1
		for row in 0 .. rows {
			mut group := 0
			for group < counts[full] {
				mut equal := true
				for dimension in 0 .. dimensions {
					if (full & (1 << dimension)) != 0 && keys[full][group][dimension] != attributes[row][dimension] { equal = false }
				}
				if equal { break }
				group++
			}
			if group == counts[full] {
				for dimension in 0 .. dimensions { keys[full][group][dimension] = attributes[row][dimension] }
				sums[full][group] = measures[row]
				counts[full]++
			} else { sums[full][group] += measures[row] }
		}
		for index in 1 .. counts[full] {
			mut position := index
			for position > 0 {
				mut less := false
				for dimension in 0 .. dimensions {
					if keys[full][position][dimension] < keys[full][position - 1][dimension] { less = true; break }
					if keys[full][position][dimension] > keys[full][position - 1][dimension] { break }
				}
				if !less { break }
				temporary := keys[full][position]
				keys[full][position] = keys[full][position - 1]
				keys[full][position - 1] = temporary
				temporary_sum := sums[full][position]
				sums[full][position] = sums[full][position - 1]
				sums[full][position - 1] = temporary_sum
				position--
			}
		}
		for wanted := dimensions - 1; wanted >= 0; wanted-- {
			for mask in 0 .. (full + 1) {
				if popcount(mask) != wanted { continue }
				mut parent := -1
				mut best := max_rows + 1
				for dimension in 0 .. dimensions {
					bit := 1 << dimension
					if (mask & bit) != 0 { continue }
					candidate := mask | bit
					if parent < 0 || counts[candidate] < best {
						parent = candidate
						best = counts[candidate]
					}
				}
				if parent < 0 { return -1 }
				parents[mask] = parent
				for parent_group in 0 .. counts[parent] {
					mut group := 0
					for group < counts[mask] {
						mut equal := true
						for dimension in 0 .. dimensions {
							if (mask & (1 << dimension)) != 0 && keys[mask][group][dimension] != keys[parent][parent_group][dimension] { equal = false }
						}
						if equal { break }
						group++
					}
					if group == counts[mask] {
						for dimension in 0 .. dimensions {
							if (mask & (1 << dimension)) != 0 { keys[mask][group][dimension] = keys[parent][parent_group][dimension] }
						}
						sums[mask][group] = sums[parent][parent_group]
						counts[mask]++
					} else { sums[mask][group] += sums[parent][parent_group] }
				}
				for index in 1 .. counts[mask] {
					mut position := index
					for position > 0 {
						mut less := false
						for dimension in 0 .. dimensions {
							if (mask & (1 << dimension)) == 0 { continue }
							if keys[mask][position][dimension] < keys[mask][position - 1][dimension] { less = true; break }
							if keys[mask][position][dimension] > keys[mask][position - 1][dimension] { break }
						}
						if !less { break }
						temporary := keys[mask][position]
						keys[mask][position] = keys[mask][position - 1]
						keys[mask][position - 1] = temporary
						temporary_sum := sums[mask][position]
						sums[mask][position] = sums[mask][position - 1]
						sums[mask][position - 1] = temporary_sum
						position--
					}
				}
			}
		}
		mut checksum := i64(0)
		for mask in 0 .. (full + 1) {
			view := i64(mask + 1)
			checksum += view * 1000000 + (i64(parents[mask]) + 2) * 10000 + i64(counts[mask]) * 1000
			for group in 0 .. counts[mask] {
				rank := i64(group + 1)
				checksum += rank * (sums[mask][group] + 1)
				for dimension in 0 .. dimensions {
					if (mask & (1 << dimension)) != 0 {
						checksum += rank * i64(dimension + 1) * (keys[mask][group][dimension] + 1)
					}
				}
			}
		}
		return checksum
	}
}
