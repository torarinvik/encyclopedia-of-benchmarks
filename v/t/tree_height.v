module tree_height

const max_nodes = 1023
const max_arcs = 2 * (max_nodes - 1)

fn dfs_height(node int, head &int, to &int, next &int, visited &bool, dp &int, reached &int) int {
	unsafe {
		visited[node] = true
		*reached += 1
		mut child_height := 1
		mut arc := head[node]
		for arc >= 0 {
			child := to[arc]
			if !visited[child] {
				if dfs_height(child, head, to, next, visited, dp, reached) < 0 { return -1 }
				if dp[child] + 1 > child_height { child_height = dp[child] + 1 }
			}
			arc = next[arc]
		}
		dp[node] = child_height
		return child_height
	}
}

@[export: 'tree_height']
pub fn tree_height(values &i64, length usize) i64 {
	if length < 1 { return -1 }
	unsafe {
		if values[0] < 1 || values[0] > max_nodes { return -1 }
		count := int(values[0])
		if length != usize(1 + 2 * (count - 1)) { return -1 }
		mut head := [max_nodes + 1]int{}
		mut to := [max_arcs]int{}
		mut next := [max_arcs]int{}
		mut dp := [max_nodes + 1]int{}
		mut visited := [max_nodes + 1]bool{}
		for node in 0 .. count + 1 { head[node] = -1 }
		mut arcs := 0
		for edge in 0 .. count - 1 {
			a_value := values[1 + 2 * edge]
			b_value := values[2 + 2 * edge]
			if a_value < 1 || b_value < 1 || a_value > count || b_value > count || a_value == b_value { return -1 }
			a := int(a_value); b := int(b_value)
			to[arcs] = b; next[arcs] = head[a]; head[a] = arcs; arcs++
			to[arcs] = a; next[arcs] = head[b]; head[b] = arcs; arcs++
		}
		mut reached := 0
		result := dfs_height(1, &head[0], &to[0], &next[0], &visited[0], &dp[0], &reached)
		if result < 0 || reached != count { return -1 }
		return i64(result)
	}
}
