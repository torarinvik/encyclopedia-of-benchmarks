// Solve unbounded knapsack with the source's take-again or skip-previous recurrence.
fn unbounded_knapsack_solve(item int, capacity int, values []i64, weights []i64, mut memo [][]i64) i64 {
	if item == 0 { return i64(capacity) / weights[0] * values[0] }
	if memo[item][capacity] >= 0 { return memo[item][capacity] }
	skip := unbounded_knapsack_solve(item - 1, capacity, values, weights, mut memo)
	mut take := i64(0)
	if i64(capacity) >= weights[item] { take = values[item] + unbounded_knapsack_solve(item, capacity - int(weights[item]), values, weights, mut memo) }
	if take > skip { memo[item][capacity] = take } else { memo[item][capacity] = skip }
	return memo[item][capacity]
}

@[export: 'unbounded_knapsack']
pub fn unbounded_knapsack(input &i64, length usize) i64 {
	if length < 2 { return -1 }
	unsafe {
		nv := input[0]; cv := input[1]
		if nv < 0 || nv > 16 || cv < 0 || cv > 100 { return -1 }
		n := int(nv); capacity := int(cv)
		if length != usize(2 + 2*n) { return -1 }
		if n == 0 { return 0 }
		values := input[2..2+n]; weights := input[2+n..2+2*n]
		for i := 0; i < n; i++ { if values[i] < 1 || values[i] > 100 || weights[i] < 1 || weights[i] > 100 { return -1 } }
		mut memo := [][]i64{len: n, init: []i64{len: 101, init: -1}}
		return unbounded_knapsack_solve(n-1, capacity, values, weights, mut memo)
	}
}
