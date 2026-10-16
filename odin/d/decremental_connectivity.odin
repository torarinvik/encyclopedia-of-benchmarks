package decremental_connectivity

import "core:c"

MAX_N :: 32
MAX_Q :: 128
find_root :: proc "contextless" (parent: [^]int, x0: int) -> int {
 x := x0
 for parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x] }
 return x
}
side_nodes :: proc "contextless" (adj: [^]u64, n, start: int, out: [^]int) -> int {
 seen: [32]bool
 node_stack: [32]int
 top, count := 0, 0
 node_stack[top] = start; top += 1
 for top > 0 {
  top -= 1; u := node_stack[top]
  if seen[u] do continue
  seen[u] = true; out[count] = u; count += 1
  for v := 0; v < n; v += 1 { if ((adj[u] >> u64(v)) & 1) != 0 && !seen[v] { node_stack[top] = v; top += 1 } }
 }
 return count
}

@(export)
decremental_connectivity :: proc "contextless" (a: [^]i64, length: int) -> i64 {
 if a == nil || length < 3 || length > 449 do return -1
 n64, m64 := a[0], a[1]
 if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 >= n64 do return -1
 n, m := int(n64), int(m64); ep := 2+2*m
 if length <= ep do return -1
 q64 := a[ep]
 if q64 < 0 || q64 > MAX_Q || length != ep+1+3*int(q64) do return -1
 q := int(q64)
 adj: [32]u64
 parent: [32]int
 for i := 0; i < n; i += 1 { parent[i] = i }
 for i := 0; i < m; i += 1 {
  u_value, v_value := a[2+2*i], a[3+2*i]
  if u_value < 0 || u_value >= n64 || v_value < 0 || v_value >= n64 || u_value == v_value do return -1
  u, v := int(u_value), int(v_value)
  if ((adj[u] >> u64(v)) & 1) != 0 do return -1
  ru, rv := find_root(&parent[0],u), find_root(&parent[0],v)
  if ru == rv do return -1
  parent[rv] = ru; adj[u] |= 1 << u64(v); adj[v] |= 1 << u64(u)
 }
 comp: [32]int
 for i := 0; i < n; i += 1 { comp[i] = -1 }
 next := 0
 node_stack: [32]int
 for start := 0; start < n; start += 1 {
  if comp[start] >= 0 do continue
  top := 0; node_stack[top] = start; top += 1; comp[start] = next
  for top > 0 { top -= 1; u := node_stack[top]; for v := 0; v < n; v += 1 { if ((adj[u] >> u64(v)) & 1) != 0 && comp[v] < 0 { comp[v] = next; node_stack[top] = v; top += 1 } } }
  next += 1
 }
 h := u64(14695981039346656037)
 for k := 0; k < q; k += 1 {
  p := ep+1+3*k; op, u_value, v_value := a[p], a[p+1], a[p+2]
  if (op != 0 && op != 1) || u_value < 0 || u_value >= n64 || v_value < 0 || v_value >= n64 do return -1
  u, v := int(u_value), int(v_value)
  if op == 1 { h = (h ~ u64(comp[u] == comp[v])) * 1099511628211; continue }
  if ((adj[u] >> u64(v)) & 1) == 0 || comp[u] != comp[v] do return -1
  adj[u] &= ~(1 << u64(v)); adj[v] &= ~(1 << u64(u))
  left, right: [32]int
  lc, rc := side_nodes(&adj[0],n,u,&left[0]), side_nodes(&adj[0],n,v,&right[0])
  if lc < rc || (lc == rc && u < v) { for j := 0; j < lc; j += 1 { comp[left[j]] = next } } else { for j := 0; j < rc; j += 1 { comp[right[j]] = next } }
  next += 1
 }
 return transmute(i64)h
}
