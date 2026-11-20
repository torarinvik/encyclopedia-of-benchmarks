package monge_dag_fixed_edge_shortest_path

import "core:c"

MAX_N :: 32
SIDE :: 33
MAX_INPUT :: 531
INF: i64 = 1152921504606846976

@(export)
monge_dag_fixed_edge_shortest_path :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n_value, d_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || d_value < 1 || d_value > n_value do return -1
	n, layers := int(n_value), int(d_value)
	if int(length) != 2 + n*(n+1)/2 do return -1

	cost: [1089]i64 = 0
	offset := 2
	for u := 0; u < n; u += 1 {
		for v := u+1; v <= n; v += 1 {
			weight := input[offset]
			offset += 1
			if weight < 0 || weight > 1_000_000 do return -1
			cost[u*SIDE+v] = weight
		}
	}
	for u := 0; u+1 < n; u += 1 {
		for v := u+2; v < n; v += 1 {
			if cost[u*SIDE+v]+cost[(u+1)*SIDE+v+1] > cost[u*SIDE+v+1]+cost[(u+1)*SIDE+v] do return -1
		}
	}

	dp: [33]i64 = INF
	next: [33]i64 = INF
	dp[0] = 0
	for layer := 1; layer <= layers; layer += 1 {
		for v := 0; v <= n; v += 1 { next[v] = INF }
		row_begin, row_end, col_begin, col_end: [64]int
		top := 1
		row_begin[0], row_end[0] = layer, n+1
		col_begin[0], col_end[0] = layer-1, n
		for top > 0 {
			top -= 1
			rb, re := row_begin[top], row_end[top]
			cb, ce := col_begin[top], col_end[top]
			if rb >= re do continue
			row := (rb+re)/2
			upper := min(ce, row)
			best_column := cb
			best_value: i64 = INF
			for column := cb; column < upper; column += 1 {
				if dp[column] == INF do continue
				candidate := dp[column]+cost[column*SIDE+row]
				if candidate < best_value { best_value = candidate; best_column = column }
			}
			next[row] = best_value
			if row+1 < re && best_column < ce {
				row_begin[top], row_end[top] = row+1, re
				col_begin[top], col_end[top] = best_column, ce
				top += 1
			}
			if rb < row && cb <= best_column {
				row_begin[top], row_end[top] = rb, row
				col_begin[top], col_end[top] = cb, best_column+1
				top += 1
			}
		}
		dp = next
	}
	return dp[n]
}
