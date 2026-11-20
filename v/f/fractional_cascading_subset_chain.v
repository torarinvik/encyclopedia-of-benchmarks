module fractional_cascading_subset_chain

const max_m = 8
const max_q = 8
const max_n = 16
const max_length = 147
const no_successor = i64(34)

@[export: 'fractional_cascading_subset_chain']
pub fn fractional_cascading_subset_chain(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_length { return -1 }
		if input[0] < 2 || input[0] > max_m || input[1] < 1 || input[1] > max_q { return -1 }
		m, q := int(input[0]), int(input[1])
		mut catalogs := [max_m][max_n]i64{}
		mut sizes := [max_m]int{}
		mut queries := [max_q]i64{}
		mut cursor := 2
		for i in 0 .. m {
			if cursor >= int(length) || input[cursor] < 1 || input[cursor] > max_n { return -1 }
			n := int(input[cursor]); cursor++
			if cursor + n > int(length) { return -1 }
			sizes[i] = n
			for j in 0 .. n {
				key := input[cursor]; cursor++
				if key < -16 || key > 16 || (j > 0 && catalogs[i][j-1] >= key) { return -1 }
				catalogs[i][j] = key
			}
			if i > 0 {
				mut parent_pos, mut child_pos := 0, 0
				for parent_pos < sizes[i-1] && child_pos < n {
					if catalogs[i-1][parent_pos] < catalogs[i][child_pos] { parent_pos++ }
					else if catalogs[i-1][parent_pos] == catalogs[i][child_pos] { parent_pos++; child_pos++ }
					else { return -1 }
				}
				if child_pos != n { return -1 }
			}
		}
		if cursor + q != int(length) { return -1 }
		for i in 0 .. q { queries[i] = input[cursor+i]; if queries[i] < -17 || queries[i] > 17 { return -1 } }
		mut bridge := [max_m-1][max_n+1]int{}
		for i in 0 .. m-1 {
			mut child := 0
			for slot in 0 .. sizes[i] {
				for child < sizes[i+1] && catalogs[i+1][child] < catalogs[i][slot] { child++ }
				bridge[i][slot] = child
			}
			bridge[i][sizes[i]] = sizes[i+1]
		}
		mut checksum := i64(0)
		for qi in 0 .. q {
			mut low, mut high := 0, sizes[0]
			for low < high {
				mid := (low+high)/2
				if catalogs[0][mid] < queries[qi] { low = mid+1 } else { high = mid }
			}
			mut slot := low
			for ci in 0 .. m {
				code := no_successor
				if slot < sizes[ci] { code = catalogs[ci][slot]+17 }
				checksum += i64(qi+1)*i64(ci+1)*code
				if ci+1 < m { slot = bridge[ci][slot] }
			}
		}
		return checksum
	}
}
