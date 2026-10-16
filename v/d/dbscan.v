module dbscan

@[export: 'dbscan']
pub fn dbscan(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > 67 { return -1 }
		n0 := input[0]; eps := input[1]; minimum := input[2]
		if n0 < 1 || n0 > 32 || eps < 1 || eps > 2000000 || minimum < 1 || minimum > n0 || length != usize(3 + 2*n0) { return -1 }
		n := int(n0); mut x := []i64{len: 32}; mut y := []i64{len: 32}; mut labels := []i64{len: 32, init: -1}; mut expanded := []bool{len: 32}
		for i in 0 .. n { x[i]=input[3+2*i]; y[i]=input[4+2*i]; if x[i] < -1000000 || x[i] > 1000000 || y[i] < -1000000 || y[i] > 1000000 { return -1 } }
		for i in 0 .. n { for j in 0 .. i { if x[i] == x[j] && y[i] == y[j] { return -1 } } }
		if output == nil || capacity < n { return -2 }
		e2 := eps*eps; mut next := i64(0)
		for i in 0 .. n {
			if labels[i] >= 0 { continue }
			mut count := 0
			for j in 0 .. n { dx:=x[i]-x[j]; dy:=y[i]-y[j]; if dx*dx+dy*dy<=e2 { count++ } }
			if count < int(minimum) { continue }
			cluster:=next; next++; labels[i]=cluster
			mut queue:=[]int{}; mut queued:=[]bool{len: 32}
			for j in 0 .. n { dx:=x[i]-x[j]; dy:=y[i]-y[j]; if dx*dx+dy*dy<=e2 { queue << j; queued[j]=true } }
			mut head:=0
			for head < queue.len { q:=queue[head]; head++; if labels[q]>=0 && labels[q]!=cluster { continue }; labels[q]=cluster; if expanded[q] { continue }; expanded[q]=true
				mut nc:=0; for j in 0 .. n { dx:=x[q]-x[j]; dy:=y[q]-y[j]; if dx*dx+dy*dy<=e2 { nc++ } }
				if nc>=int(minimum) { for j in 0 .. n { dx:=x[q]-x[j]; dy:=y[q]-y[j]; if dx*dx+dy*dy<=e2 && labels[j]<0 && !queued[j] { queue << j; queued[j]=true } } }
			}
		}
		for i in 0 .. n { output[i]=u8(if labels[i]<0 { 0 } else { labels[i]+1 }) }
		return i64(n)
	}
}
