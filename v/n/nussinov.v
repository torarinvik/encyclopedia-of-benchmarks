module main

const max_n = 128

@[export: 'nussinov']
pub fn nussinov(values &i64, length usize) i64 {
	if length != 1 { return -1 }
	n_value := unsafe { values[0] }
	if n_value < 1 || n_value > max_n { return -1 }
	n := int(n_value)
	mut bases := [max_n]i64{}
	mut table := [max_n][max_n]i64{}
	for i in 0 .. n { bases[i] = i64((i + 1) % 4) }

	for i := n-1; i >= 0; i-- {
		for j := i+1; j < n; j++ {
			mut score := table[i][j-1]
			if i+1 < n {
				if table[i+1][j] > score { score = table[i+1][j] }
				mut inside := table[i+1][j-1]
				if i < j-1 && bases[i]+bases[j] == 3 { inside++ }
				if inside > score { score = inside }
			}
			for k := i+1; k < j; k++ {
				split := table[i][k] + table[k+1][j]
				if split > score { score = split }
			}
			table[i][j] = score
		}
	}

	mut checksum := i64(0)
	for row in 0 .. n {
		for col in row .. n { checksum += table[row][col] }
	}
	return checksum
}
