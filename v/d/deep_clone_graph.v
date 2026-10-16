module deep_clone_graph
fn mix(h0 u64, x0 u64) u64 { mut h := h0; mut x := x0; for _ in 0 .. 8 { h = (h ^ (x & 255)) * 1099511628211; x >>= 8 }; return h }
@[export: 'deep_clone_graph']
pub fn deep_clone_graph(a &i64, len usize) i64 {
 if unsafe { a == nil } || len < 4 || len > 34 { return -1 }
 n := unsafe { a[0] }; root := unsafe { a[1] }
 if n < 1 || n > 16 || root < 0 || root >= n || len != usize(2 + 2*n) { return -1 }
 mut labels := []i64{len: 16}; mut masks := []u64{len: 16}; mut clone_masks := []u64{len: 16}; mut seen := []bool{len:16}; mut stack := []int{cap:256}
 for i in 0 .. int(n) { value:=unsafe{a[2+i]}; row:=unsafe{a[2+int(n)+i]}; if value < -2147483648 || value > 2147483647 || row < 0 || (u64(row) >> u32(n)) != 0 { return -1 }; labels[i]=value;masks[i]=u64(row) }
 for i in 0 .. int(n) { for j in 0 .. int(n) { if ((masks[i]>>u32(j))&1)!=((masks[j]>>u32(i))&1) { return -1 } } }
 stack << int(root); mut count:=0
 for stack.len>0 { u:=stack.pop();if seen[u]{continue};seen[u]=true;count++;clone_masks[u]=masks[u];for v in 0 .. int(n){if ((masks[u]>>u32(v))&1)!=0&&!seen[v]{stack<<v}} }
 mut h:=mix(u64(14695981039346656037),u64(count));h=mix(h,u64(root));for i in 0 .. int(n){if seen[i]{h=mix(h,u64(labels[i]));h=mix(h,clone_masks[i])}};return i64(h)
}
