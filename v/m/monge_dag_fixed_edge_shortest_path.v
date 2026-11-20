module monge_dag_fixed_edge_shortest_path

const max_n = 32
const side = 33
const max_input = 531
const inf = i64(1152921504606846976)

@[export: 'monge_dag_fixed_edge_shortest_path']
pub fn monge_dag_fixed_edge_shortest_path(input &i64, length usize) i64 {
	if length < 2 || length > max_input || unsafe { input == nil } { return -1 }
	unsafe {
		n_value := input[0]
		d_value := input[1]
		if n_value < 1 || n_value > max_n || d_value < 1 || d_value > n_value { return -1 }
		n := int(n_value)
		layers := int(d_value)
		if length != usize(2+n*(n+1)/2) { return -1 }

		mut cost := [1089]i64{}
		mut offset := 2
		for u in 0 .. n {
			for v in u+1 .. n+1 {
				weight := input[offset]
				offset++
				if weight < 0 || weight > 1_000_000 { return -1 }
				cost[u*side+v] = weight
			}
		}
		for u in 0 .. max(0, n-1) {
			for v in u+2 .. n {
				if cost[u*side+v]+cost[(u+1)*side+v+1] > cost[u*side+v+1]+cost[(u+1)*side+v] { return -1 }
			}
		}

		mut dp := [33]i64{}
		mut next := [33]i64{}
		for v in 0 .. n+1 { dp[v] = inf }
		dp[0] = 0
		for layer in 1 .. layers+1 {
			for v in 0 .. n+1 { next[v] = inf }
			mut row_begin := [64]int{}
			mut row_end := [64]int{}
			mut col_begin := [64]int{}
			mut col_end := [64]int{}
			mut top := 1
			row_begin[0] = layer
			row_end[0] = n+1
			col_begin[0] = layer-1
			col_end[0] = n
			for top > 0 {
				top--
				rb, re := row_begin[top], row_end[top]
				cb, ce := col_begin[top], col_end[top]
				if rb >= re { continue }
				row := (rb+re)/2
				upper := min(ce, row)
				mut best_column := cb
				mut best_value := inf
				for column in cb .. upper {
					if dp[column] == inf { continue }
					candidate := dp[column]+cost[column*side+row]
					if candidate < best_value { best_value = candidate; best_column = column }
				}
				next[row] = best_value
				if row+1 < re && best_column < ce {
					row_begin[top] = row+1; row_end[top] = re
					col_begin[top] = best_column; col_end[top] = ce
					top++
				}
				if rb < row && cb <= best_column {
					row_begin[top] = rb; row_end[top] = row
					col_begin[top] = cb; col_end[top] = best_column+1
					top++
				}
			}
			dp = next
		}
		return dp[n]
	}
}
