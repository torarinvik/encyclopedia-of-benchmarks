module integer_partition

@[export: 'integer_partition']
pub fn integer_partition(m i64) i64 {
	if m < 1 || m > 300 { return -9223372036854775807 - 1 }
	mut memo := []i64{len: 90300}
	mut i := i64(0)
	for i <= m {
		memo[int(i * 300)] = 1
		i++
	}
	mut n := i64(0)
	for n <= m {
		mut k := i64(1)
		for k < m {
			index := int(n * 300 + k)
			memo[index] += memo[index - 1]
			if n - k > 0 { memo[index] += memo[int((n-k-1)*300+k)] }
			k++
		}
		n++
	}
	return memo[int(m * 300 + m - 1)]
}
