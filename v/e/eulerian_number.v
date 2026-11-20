module eulerian_number

@[export: 'eulerian_number']
pub fn eulerian_number(values &i64, length usize) i64 {
	if length != 2 { return -1 }
	unsafe {
		if values == nil { return -1 }
		n, target := values[0], values[1]
		if n < 0 || n > 20 || target < 0 ||
			(n == 0 && target != 0) || (n > 0 && target >= n) { return -1 }

		mut previous := [21]i64{}
		mut current := [21]i64{}
		previous[0] = 1
		for row := 1; row <= int(n); row++ {
			for k := 0; k < row; k++ {
				same := previous[k]
				fewer := i64(0)
				if k > 0 { fewer = previous[k - 1] }
				current[k] = (i64(k) + 1) * same + (i64(row) - i64(k)) * fewer
			}
			for index := 0; index < 21; index++ {
				previous[index] = current[index]
				current[index] = 0
			}
		}
		return previous[int(target)]
	}
}
