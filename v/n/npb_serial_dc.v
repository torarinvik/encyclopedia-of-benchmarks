/* NAS Parallel Benchmarks 3.3 DC source notice:
 * Permission to use, copy, distribute and modify this software for any purpose
 * with or without fee is hereby granted. We request, however, that all derived
 * work reference the NAS Parallel Benchmarks 3.3. This software is provided
 * "as is" without express or implied warranty.
 *
 * Clean-room bounded adaptation: packed input and ordered scalar checksum
 * replace generated files and the original memory management harness.
 */
module npb_serial_dc

const max_dims = 5
const max_rows = 16

@[export: 'npb_serial_dc']
pub fn npb_serial_dc(input &i64, length usize) i64 {
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
		mut checksum := i64(0)
		for mask in 1 .. (1 << dimensions) {
			mut keys := [max_rows][max_dims]i64{}
			mut sums := [max_rows]i64{}
			mut group_count := 0
			for row in 0 .. rows {
				mut group := 0
				for group < group_count {
					mut equal := true
					for dimension in 0 .. dimensions {
						if (mask & (1 << dimension)) != 0 && keys[group][dimension] != attributes[row][dimension] { equal = false }
					}
					if equal { break }
					group++
				}
				if group == group_count {
					for dimension in 0 .. dimensions {
						if (mask & (1 << dimension)) != 0 { keys[group][dimension] = attributes[row][dimension] }
					}
					sums[group] = measures[row]
					group_count++
				} else { sums[group] += measures[row] }
			}
			for index in 1 .. group_count {
				mut position := index
				for position > 0 {
					mut comparison := 0
					for dimension in 0 .. dimensions {
						if (mask & (1 << dimension)) == 0 { continue }
						if keys[position][dimension] < keys[position - 1][dimension] { comparison = -1; break }
						if keys[position][dimension] > keys[position - 1][dimension] { comparison = 1; break }
					}
					if comparison >= 0 { break }
					for dimension in 0 .. dimensions {
						temporary := keys[position][dimension]
						keys[position][dimension] = keys[position - 1][dimension]
						keys[position - 1][dimension] = temporary
					}
					temporary_sum := sums[position]
					sums[position] = sums[position - 1]
					sums[position - 1] = temporary_sum
					position--
				}
			}
			view := i64(mask)
			checksum += view * 1009 + i64(group_count) * 9176
			for group in 0 .. group_count {
				checksum += (view + 1) * i64(group + 1) * (sums[group] + 13)
				for dimension in 0 .. dimensions {
					if (mask & (1 << dimension)) != 0 {
						checksum += i64(dimension + 1) * (keys[group][dimension] + 1) * i64(group + 3) * (view + 5)
					}
				}
			}
		}
		return checksum
	}
}
