package deep_clone_graph

import "core:c"

mix :: proc "contextless" (h0, x0: u64) -> u64 {
 h, x := h0, x0
 for byte: int = 0; byte < 8; byte += 1 { h = ((h ~ (x & 255))) * 1099511628211; x = x >> 8 }
 return h
}

@(export)
deep_clone_graph :: proc "contextless" (a: [^]i64, length: int) -> i64 {
 if a == nil || length < 4 || length > 34 do return -1
 n64, root64 := a[0], a[1]
 if n64 < 1 || n64 > 16 || root64 < 0 || root64 >= n64 || length != 2+2*int(n64) do return -1
 n, root := int(n64), int(root64)
 labels: [16]i64
 masks, cloned: [16]u64
 seen: [16]bool
 stack: [256]int
 top, count := 0, 0
 for i in 0..<n {
  if a[2+i] < -2147483648 || a[2+i] > 2147483647 || a[2+n+i] < 0 || (u64(a[2+n+i]) >> u64(n)) != 0 do return -1
  labels[i] = a[2+i]; masks[i] = u64(a[2+n+i])
 }
 for i in 0..<n { for j in 0..<n { if ((masks[i]>>u64(j))&1) != ((masks[j]>>u64(i))&1) do return -1 } }
 stack[top] = root; top += 1
 for top > 0 {
  top -= 1; u := stack[top]
  if seen[u] do continue
  seen[u] = true; count += 1; cloned[u] = masks[u]
  for v in 0..<n { if ((masks[u]>>u64(v))&1) != 0 && !seen[v] { stack[top] = v; top += 1 } }
 }
 h := mix(14695981039346656037, u64(count)); h = mix(h, u64(root))
 for i in 0..<n { if seen[i] { h = mix(h, transmute(u64)labels[i]); h = mix(h, cloned[i]) } }
 return transmute(i64)h
}
