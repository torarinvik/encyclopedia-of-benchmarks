fn rpl_floor_div(a i64, b i64) i64 {
	q := a / b
	r := a % b
	return q - if r < 0 { i64(1) } else { i64(0) }
}

fn rpl_ceil_div(a i64, b i64) i64 {
	return -rpl_floor_div(-a, b)
}

fn rpl_floor_sum(n0 i64, m0 i64, a0 i64, b0 i64) i64 {
	aq := rpl_floor_div(a0,m0)
	bq := rpl_floor_div(b0,m0)
	mut answer := aq*n0*(n0-1)/2+bq*n0
	mut a := a0-aq*m0
	mut b := b0-bq*m0
	mut n := n0
	mut m := m0
	for {
		if a >= m { answer += (n-1)*n*(a/m)/2; a %= m }
		if b >= m { answer += n*(b/m); b %= m }
		top := a*n+b
		if top < m { return answer }
		n = top/m
		b = top%m
		t := m
		m = a
		a = t
	}
	return answer
}

fn rpl_edge_chunk(scale i64, ax i64, ay i64, dx i64, dy i64, start i64, columns i64) i64 {
	if columns <= 0 { return 0 }
	mut aa := dy*scale
	mut bb := ay*dx-dy*ax
	mut den := scale*dx
	if den < 0 { aa = -aa; bb = -bb; den = -den }
	base := aa*start+bb
	if dx > 0 { return -rpl_floor_sum(columns,den,aa,base) }
	return -rpl_floor_sum(columns,den,-aa,-base)-columns
}

fn rpl_inside(xs [8]i64, ys [8]i64, n int, scale i64, x i64, y i64) bool {
	px := x*scale
	py := y*scale
	mut inside := false
	for i in 0 .. n {
		j := (i+1)%n
		cross := (xs[j]-xs[i])*(py-ys[i])-(ys[j]-ys[i])*(px-xs[i])
		if cross == 0 && px >= min(xs[i],xs[j]) && px <= max(xs[i],xs[j]) && py >= min(ys[i],ys[j]) && py <= max(ys[i],ys[j]) { return false }
		if (ys[i] > py) != (ys[j] > py) {
			dy := ys[j]-ys[i]
			dx := xs[j]-xs[i]
			left := xs[i]*dy+(py-ys[i])*dx
			right := px*dy
			if (dy > 0 && left > right) || (dy < 0 && left < right) { inside = !inside }
		}
	}
	return inside
}

@[export: 'rational_polygon_lattice_points']
pub fn rational_polygon_lattice_points(input &i64, length usize) i64 {
	if length < 2 || length > 19 { return -1 }
	unsafe {
		if input == nil { return -1 }
		scale := input[0]
		nr := input[1]
		if scale < 2 || scale > 8 || nr < 3 || nr > 8 || length != usize(2+2*nr) { return -1 }
		n := int(nr)
		mut xs := [8]i64{}
		mut ys := [8]i64{}
		mut fractional := false
		for i in 0 .. n {
			xs[i] = input[2+2*i]
			ys[i] = input[3+2*i]
			if xs[i] < -32 || xs[i] > 32 || ys[i] < -32 || ys[i] > 32 { return -1 }
			if xs[i] < -4*scale || xs[i] > 4*scale || ys[i] < -4*scale || ys[i] > 4*scale { return -1 }
			if xs[i]%scale != 0 || ys[i]%scale != 0 { fractional = true }
			for j in 0 .. i { if xs[i] == xs[j] && ys[i] == ys[j] { return -1 } }
		}
		if !fractional { return -1 }
		mut area2 := i64(0)
		for i in 0 .. n {
			j := (i+1)%n
			area2 += xs[i]*ys[j]-ys[i]*xs[j]
		}
		if area2 == 0 { return -1 }
		orientation := if area2 > 0 { i64(1) } else { i64(-1) }
		for i in 0 .. n {
			next := (i+1)%n
			for j in 0 .. n {
				if j == i || j == next { continue }
				cross := (xs[next]-xs[i])*(ys[j]-ys[i])-(ys[next]-ys[i])*(xs[j]-xs[i])
				if cross*orientation <= 0 { return -1 }
			}
		}
		mut signed_count := i64(0)
		for i in 0 .. n {
			j := (i+1)%n
			dx := xs[j]-xs[i]
			dy := ys[j]-ys[i]
			if dx == 0 { continue }
			lo := if xs[i] < xs[j] { xs[i] } else { xs[j] }
			hi := if xs[i] > xs[j] { xs[i] } else { xs[j] }
			start := rpl_ceil_div(lo,scale)
			stop := rpl_ceil_div(hi,scale)
			mut cursor := start
			for col in start .. stop {
				event := false
				for k in 0 .. n { if xs[k] == col*scale { event = true } }
				if event {
					signed_count += rpl_edge_chunk(scale,xs[i],ys[i],dx,dy,cursor,col-cursor)
					cursor = col+1
				}
			}
			signed_count += rpl_edge_chunk(scale,xs[i],ys[i],dx,dy,cursor,stop-cursor)
		}
		for i in 0 .. n {
			if xs[i]%scale != 0 { continue }
			mut first := true
			for j in 0 .. i { if xs[j] == xs[i] { first = false } }
			if !first { continue }
			x := xs[i]/scale
			mut count := i64(0)
			for y in -4 .. 5 { if rpl_inside(xs,ys,n,scale,x,i64(y)) { count++ } }
			signed_count += orientation*count
		}
		result := signed_count*orientation
		return if result >= 0 { result } else { i64(-1) }
	}
}
