// Bounded port of the Benchmark Game fannkuch counter traversal.
module fannkuch

@[export: 'fannkuch']
pub fn fannkuch(values &i64, length usize) i64 {
	if values == nil || length != 1 { return -1 }
	unsafe {
		n64 := values[0]
		if n64 < 1 || n64 > 8 { return -1 }
		n := int(n64)
		mut perm := [8]int{}
		mut perm1 := [8]int{}
		mut count := [8]int{}
		for i in 0 .. n { perm1[i] = i }
		mut r := n
		mut flips_max := 0
		for {
			for r != 1 { count[r - 1] = r; r-- }
			if perm1[0] != 0 && perm1[n - 1] != n - 1 {
				for i in 1 .. n { perm[i] = perm1[i] }
				mut k := perm1[0]
				mut flips := 0
				for {
					mut i := 1
					mut j := k - 1
					for i < j { perm[i], perm[j] = perm[j], perm[i]; i++; j-- }
					flips++
					j = perm[k]
					perm[k] = k
					k = j
					if k == 0 { break }
				}
				if flips_max < flips { flips_max = flips }
			}
			for {
				if r == n { return i64(flips_max) }
				first := perm1[0]
				for i in 0 .. r { perm1[i] = perm1[i + 1] }
				perm1[r] = first
				count[r]--
				if count[r] > 0 { break }
				r++
			}
		}
	}
}
