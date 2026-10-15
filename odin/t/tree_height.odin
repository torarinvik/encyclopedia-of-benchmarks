package tree_height

MAX_NODES :: 1023
MAX_ARCS :: 2 * (MAX_NODES - 1)

dfs_height :: proc "contextless" (node: int, head, to, next: [^]int,
		visited: [^]bool, dp: [^]int, reached: ^int) -> int {
	visited[node] = true
	reached^ += 1
	child_height := 1
	arc := head[node]
	for arc >= 0 {
		child := to[arc]
		if !visited[child] {
			if dfs_height(child, head, to, next, visited, dp, reached) < 0 do return -1
			if dp[child] + 1 > child_height do child_height = dp[child] + 1
		}
		arc = next[arc]
	}
	dp[node] = child_height
	return child_height
}

@(export)
tree_height :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || values[0] < 1 || values[0] > MAX_NODES do return -1
	count := int(values[0])
	if int(length) != 1 + 2 * (count - 1) do return -1
	head: [MAX_NODES + 1]int
	to: [MAX_ARCS]int
	next: [MAX_ARCS]int
	dp: [MAX_NODES + 1]int
	visited: [MAX_NODES + 1]bool
	for node := 0; node <= count; node += 1 do head[node] = -1
	arcs := 0
	for edge := 0; edge < count - 1; edge += 1 {
		a_value, b_value := values[1 + 2 * edge], values[2 + 2 * edge]
		if a_value < 1 || b_value < 1 || a_value > i64(count) || b_value > i64(count) || a_value == b_value do return -1
		a, b := int(a_value), int(b_value)
		to[arcs] = b; next[arcs] = head[a]; head[a] = arcs; arcs += 1
		to[arcs] = a; next[arcs] = head[b]; head[b] = arcs; arcs += 1
	}
	reached := 0
	result := dfs_height(1, &head[0], &to[0], &next[0], &visited[0], &dp[0], &reached)
	if result < 0 || reached != count do return -1
	return i64(result)
}
