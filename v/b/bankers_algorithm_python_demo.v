// Preserve duplicate-need bookkeeping in the pinned Python demonstration.
@[export: 'bankers_algorithm_python_demo']
pub fn bankers_algorithm_python_demo(values &i64, length usize) i64 {
	if length < 5 || length > 266 { return -1 }
	nv := unsafe { values[0] }; mv := unsafe { values[1] }
	if nv < 1 || nv > 16 || mv < 1 || mv > 8 { return -1 }
	n := int(nv); m := int(mv); aoff := 2 + m; moff := aoff + n * m
	if length != usize(moff + n * m) { return -1 }
	mut work := []i64{len: m, init: 0}
	for r := 0; r < m; r++ { x := unsafe { values[2+r] }; if x < 0 || x > 100 { return -1 }; work[r] = x }
	for p := 0; p < n; p++ { for r := 0; r < m; r++ { i := p*m+r; a := unsafe { values[aoff+i] }; x := unsafe { values[moff+i] }; if a < 0 || a > 100 || x < 0 || x > 100 || a > x { return -1 }; work[r] -= a } }
	for r := 0; r < m; r++ { if work[r] < 0 { return -1 } }
	mut first := []int{len: n, init: 0}; mut remaining := []int{len: n, init: 0}
	for p := 0; p < n; p++ { first[p] = p; remaining[p] = p; for q := 0; q < p; q++ { mut equal := true; for r := 0; r < m; r++ { pi:=p*m+r; qi:=q*m+r; if unsafe { values[moff+pi] - values[aoff+pi] } != unsafe { values[moff+qi] - values[aoff+qi] } { equal=false; break } }; if equal { first[p]=first[q]; break } } }
	mut count := n
	for count > 0 { mut selected := count; for i := 0; i < count; i++ { p:=remaining[i]; mut feasible:=true; for r:=0;r<m;r++ { j:=p*m+r; if unsafe { values[moff+j] - values[aoff+j] } > work[r] { feasible=false;break } }; if feasible {selected=i;break} }; if selected==count {return 0}; mapped:=first[remaining[selected]]; for r:=0;r<m;r++ {work[r]+=unsafe {values[aoff+mapped*m+r]}}; for i:=selected+1;i<count;i++ {remaining[i-1]=remaining[i]}; count-- }
	return 1
}
