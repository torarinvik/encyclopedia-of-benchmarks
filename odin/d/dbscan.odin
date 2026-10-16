package dbscan

import "core:c"

@(export)
dbscan :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > 67 do return -1
	n0, eps, minimum := input[0], input[1], input[2]
	if n0 < 1 || n0 > 32 || eps < 1 || eps > 2_000_000 || minimum < 1 || minimum > n0 || length != c.size_t(3 + 2*n0) do return -1
	n := int(n0)
	x: [32]i64
	y: [32]i64
	labels: [32]i64
	expanded: [32]bool
	for i in 0..<n {
		x[i] = input[3+2*i]; y[i] = input[4+2*i]; labels[i] = -1
		if x[i] < -1_000_000 || x[i] > 1_000_000 || y[i] < -1_000_000 || y[i] > 1_000_000 do return -1
	}
	for i in 0..<n { for j in 0..<i { if x[i] == x[j] && y[i] == y[j] do return -1 } }
	if output == nil || capacity < c.size_t(n) do return -2
	e2 := eps*eps
	next: i64 = 0
	for i in 0..<n {
		if labels[i] >= 0 do continue
		count := 0
		for j in 0..<n { dx := x[i]-x[j]; dy := y[i]-y[j]; if dx*dx+dy*dy <= e2 do count += 1 }
		if count < int(minimum) do continue
		cluster := next; next += 1; labels[i] = cluster
		queue: [32]int
		queued: [32]bool
		head, tail := 0, 0
		for j in 0..<n { dx := x[i]-x[j]; dy := y[i]-y[j]; if dx*dx+dy*dy <= e2 { queue[tail] = j; tail += 1; queued[j] = true } }
		for head < tail {
			q := queue[head]; head += 1
			if labels[q] >= 0 && labels[q] != cluster do continue
			labels[q] = cluster
			if expanded[q] do continue
			expanded[q] = true
			nc := 0
			for j in 0..<n { dx := x[q]-x[j]; dy := y[q]-y[j]; if dx*dx+dy*dy <= e2 do nc += 1 }
			if nc >= int(minimum) {
				for j in 0..<n { dx := x[q]-x[j]; dy := y[q]-y[j]; if dx*dx+dy*dy <= e2 && labels[j] < 0 && !queued[j] { queue[tail] = j; tail += 1; queued[j] = true } }
			}
		}
	}
	for i in 0..<n {
		if labels[i] < 0 { output[i] = 0 } else { output[i] = u8(labels[i]+1) }
	}
	return i64(n)
}
