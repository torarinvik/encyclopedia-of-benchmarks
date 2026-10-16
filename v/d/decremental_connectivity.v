module decremental_connectivity

const max_n = 32
const max_q = 128

fn dc_find(parent &int, x0 int) int {
 mut x := x0
 for unsafe { parent[x] } != x { p := unsafe { parent[x] }; gp := unsafe { parent[p] }; unsafe { parent[x] = gp }; x = gp }
 return x
}
fn dc_side(adj &u64, n int, start int, out &int) int {
 mut seen := []bool{len: max_n}
 mut stack := []int{cap: max_n}
 mut count := 0
 stack << start
 for stack.len > 0 {
  u := stack.pop()
  if seen[u] { continue }
  seen[u] = true
  unsafe { out[count] = u }
  count++
  for v in 0 .. n {
   if ((unsafe { adj[u] } >> u32(v)) & 1) != 0 && !seen[v] { stack << v }
  }
 }
 return count
}

@[export: 'decremental_connectivity']
pub fn decremental_connectivity(a &i64, length usize) i64 {
 if unsafe { a == nil } || length < 3 || length > 449 { return -1 }
 n64 := unsafe { a[0] }; m64 := unsafe { a[1] }
 if n64 < 1 || n64 > max_n || m64 < 0 || m64 >= n64 { return -1 }
 n := int(n64); m := int(m64); ep := 2 + 2*m
 if length <= usize(ep) { return -1 }
 q64 := unsafe { a[ep] }
 if q64 < 0 || q64 > max_q || length != usize(ep+1+3*int(q64)) { return -1 }
 q := int(q64)
 mut adj := []u64{len: max_n}
 mut parent := []int{len: max_n}
 for i in 0 .. n { parent[i] = i }
 for i in 0 .. m {
  u_value := unsafe { a[2+2*i] }; v_value := unsafe { a[3+2*i] }
  if u_value < 0 || u_value >= n64 || v_value < 0 || v_value >= n64 || u_value == v_value { return -1 }
  u := int(u_value); v := int(v_value)
  if ((adj[u] >> u32(v)) & 1) != 0 { return -1 }
  ru := dc_find(unsafe { &parent[0] },u); rv := dc_find(unsafe { &parent[0] },v)
  if ru == rv { return -1 }
  parent[rv] = ru; adj[u] = adj[u] | (u64(1) << u32(v)); adj[v] = adj[v] | (u64(1) << u32(u))
 }
 mut comp := []int{len: max_n, init: -1}; mut next := 0
 mut stack := []int{cap: max_n}
 for start in 0 .. n {
  if comp[start] >= 0 { continue }
  stack << start; comp[start] = next
  for stack.len > 0 {
   u := stack.pop()
   for v in 0 .. n { if ((adj[u] >> u32(v)) & 1) != 0 && comp[v] < 0 { comp[v] = next; stack << v } }
  }
  next++
 }
 mut h := u64(14695981039346656037)
 for k in 0 .. q {
  p := ep+1+3*k; op := unsafe { a[p] }; u_value := unsafe { a[p+1] }; v_value := unsafe { a[p+2] }
  if (op != 0 && op != 1) || u_value < 0 || u_value >= n64 || v_value < 0 || v_value >= n64 { return -1 }
  u := int(u_value); v := int(v_value)
  if op == 1 { h = (h ^ u64(comp[u] == comp[v])) * u64(1099511628211); continue }
  if ((adj[u] >> u32(v)) & 1) == 0 || comp[u] != comp[v] { return -1 }
  adj[u] = adj[u] & ~(u64(1) << u32(v)); adj[v] = adj[v] & ~(u64(1) << u32(u))
  mut left := []int{len: max_n}; mut right := []int{len: max_n}; lc := dc_side(unsafe { &adj[0] },n,u,unsafe { &left[0] }); rc := dc_side(unsafe { &adj[0] },n,v,unsafe { &right[0] })
  if lc < rc || (lc == rc && u < v) { for j in 0 .. lc { comp[left[j]] = next } } else { for j in 0 .. rc { comp[right[j]] = next } }
  next++
 }
 return i64(h)
}
