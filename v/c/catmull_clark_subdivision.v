module catmull_clark_subdivision

import math

const max_v = 24
const max_f = 8
const max_d = 8
const max_e = 32
const max_in = 122
const max_out = 386

struct CcEdge {
	u int
	v int
	f0 int
	f1 int
	uses int
}

fn cc_integer(value f64, low int, high int) int {
	if !value.is_finite() || math.trunc(value) != value || value < f64(low) || value > f64(high) { return -1 }
	return int(value)
}

fn cc_mean(values []f64) f64 {
	mut scale := f64(0.0)
	for value in values { if value.abs() > scale { scale = value.abs() } }
	if scale == 0.0 { return 0.0 }
	mut sum := f64(0.0)
	for value in values { sum += value / scale }
	return (sum / f64(values.len)) * scale
}

fn cc_midpoint(a f64, b f64) f64 {
	mut scale := a.abs()
	if b.abs() > scale { scale = b.abs() }
	if scale == 0.0 { return 0.0 }
	return ((a / scale + b / scale) * 0.5) * scale
}

fn cc_average4(a f64, b f64, c f64, d f64) f64 {
	mut scale := a.abs()
	if b.abs() > scale { scale = b.abs() }
	if c.abs() > scale { scale = c.abs() }
	if d.abs() > scale { scale = d.abs() }
	if scale == 0.0 { return 0.0 }
	return ((a / scale + b / scale + c / scale + d / scale) * 0.25) * scale
}

@[export: 'catmull_clark_subdivision']
pub fn catmull_clark_subdivision(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_in { return -1 }
		for i in 0 .. int(length) { if !input[i].is_finite() { return -1 } }
		nv := cc_integer(input[0], 0, max_v)
		nf := cc_integer(input[1], 0, max_f)
		if nv < 0 || nf < 0 { return -1 }
		if (nv == 0 || nf == 0) && !(nv == 0 && nf == 0 && length == 2) { return -1 }

		mut x := [max_v]f64{}
		mut y := [max_v]f64{}
		mut degree := [max_f]int{}
		mut face := [max_f][max_d]int{}
		mut pos := 2
		if pos + 2 * nv > int(length) { return -1 }
		for v in 0 .. nv { x[v] = input[pos]; y[v] = input[pos + 1]; pos += 2 }
		mut edges := [max_e]CcEdge{}
		mut ne := 0
		for f in 0 .. nf {
			if pos >= int(length) { return -1 }
			degree[f] = cc_integer(input[pos], 3, max_d)
			pos++
			if degree[f] < 0 || pos + degree[f] > int(length) { return -1 }
			for i in 0 .. degree[f] {
				face[f][i] = cc_integer(input[pos], 0, nv - 1)
				pos++
				if face[f][i] < 0 { return -1 }
				for j in 0 .. i { if face[f][i] == face[f][j] { return -1 } }
			}
			for i in 0 .. degree[f] {
				a := face[f][i]
				b := face[f][(i + 1) % degree[f]]
				u := if a < b { a } else { b }
				v := if a < b { b } else { a }
				mut found := -1
				for e in 0 .. ne { if edges[e].u == u && edges[e].v == v { found = e; break } }
				if found < 0 {
					if ne == max_e { return -1 }
					edges[ne] = CcEdge{u: u, v: v, f0: f, f1: -1, uses: 1}
					ne++
				} else {
					if edges[found].uses != 1 || edges[found].f0 == f { return -1 }
					edges[found].uses = 2
					edges[found].f1 = f
				}
			}
		}
		if pos != int(length) { return -1 }
		for e in 0 .. ne { if edges[e].uses != 2 { return -1 } }

		for vertex in 0 .. nv {
			mut valence := 0
			for e in 0 .. ne { if edges[e].u == vertex || edges[e].v == vertex { valence++ } }
			mut link_a := [max_f]int{}
			mut link_b := [max_f]int{}
			mut links := 0
			for f in 0 .. nf {
				for i in 0 .. degree[f] {
					if face[f][i] == vertex {
						a := face[f][(i + degree[f] - 1) % degree[f]]
						b := face[f][(i + 1) % degree[f]]
						lo := if a < b { a } else { b }
						hi := if a < b { b } else { a }
						for j in 0 .. links {
							old_lo := if link_a[j] < link_b[j] { link_a[j] } else { link_b[j] }
							old_hi := if link_a[j] < link_b[j] { link_b[j] } else { link_a[j] }
							if lo == old_lo && hi == old_hi { return -1 }
						}
						link_a[links] = a; link_b[links] = b; links++
					}
				}
			}
			if valence < 3 || links != valence { return -1 }
			mut reached := [max_v]bool{}
			reached[link_a[0]] = true
			mut changed := true
			for changed {
				changed = false
				for i in 0 .. links {
					if reached[link_a[i]] && !reached[link_b[i]] { reached[link_b[i]] = true; changed = true }
					if reached[link_b[i]] && !reached[link_a[i]] { reached[link_a[i]] = true; changed = true }
				}
			}
			mut node_degree := [max_v]int{}
			for i in 0 .. links { node_degree[link_a[i]]++; node_degree[link_b[i]]++ }
			mut nodes := 0
			for u in 0 .. nv { if node_degree[u] != 0 { nodes++; if node_degree[u] != 2 || !reached[u] { return -1 } } }
			if nodes < 3 { return -1 }
		}

		for i in 1 .. ne {
			item := edges[i]
			mut j := i
			for j > 0 && (edges[j - 1].u > item.u || (edges[j - 1].u == item.u && edges[j - 1].v > item.v)) {
				edges[j] = edges[j - 1]; j--
			}
			edges[j] = item
		}
		mut face_x := [max_f]f64{}
		mut face_y := [max_f]f64{}
		for f in 0 .. nf {
			mut vx := [max_d]f64{}
			mut vy := [max_d]f64{}
			for i in 0 .. degree[f] { vx[i] = x[face[f][i]]; vy[i] = y[face[f][i]] }
			face_x[f] = cc_mean(vx[..degree[f]])
			face_y[f] = cc_mean(vy[..degree[f]])
		}

		mut staged := [max_out]f64{}
		mut out := 0
		new_v := nv + ne + nf
		mut new_f := 0
		for f in 0 .. nf { new_f += degree[f] }
		staged[out] = f64(new_v); out++; staged[out] = f64(new_f); out++
		for vertex in 0 .. nv {
			mut fxs := [max_f]f64{}; mut fys := [max_f]f64{}
			mut rx := [max_f]f64{}; mut ry := [max_f]f64{}
			mut nfi := 0; mut nei := 0
			for f in 0 .. nf { for i in 0 .. degree[f] { if face[f][i] == vertex { fxs[nfi] = face_x[f]; fys[nfi] = face_y[f]; nfi++; break } } }
			for e in 0 .. ne { if edges[e].u == vertex || edges[e].v == vertex { rx[nei] = cc_midpoint(x[edges[e].u],x[edges[e].v]); ry[nei] = cc_midpoint(y[edges[e].u],y[edges[e].v]); nei++ } }
			fa_x := cc_mean(fxs[..nfi]); fa_y := cc_mean(fys[..nfi]); ra_x := cc_mean(rx[..nei]); ra_y := cc_mean(ry[..nei])
			sx := x[vertex].abs(); sy := y[vertex].abs(); if fa_x.abs()>sx {sx=fa_x.abs()};if ra_x.abs()>sx {sx=ra_x.abs()};if fa_y.abs()>sy {sy=fa_y.abs()};if ra_y.abs()>sy {sy=ra_y.abs()}
			px := f64(0); py := f64(0); if sx!=0 {px=((fa_x/sx+2*ra_x/sx+f64(nei-3)*(x[vertex]/sx))/f64(nei))*sx};if sy!=0 {py=((fa_y/sy+2*ra_y/sy+f64(nei-3)*(y[vertex]/sy))/f64(nei))*sy}
			staged[out]=px;out++;staged[out]=py;out++
		}
		for e in 0 .. ne { staged[out]=cc_average4(x[edges[e].u],x[edges[e].v],face_x[edges[e].f0],face_x[edges[e].f1]);out++;staged[out]=cc_average4(y[edges[e].u],y[edges[e].v],face_y[edges[e].f0],face_y[edges[e].f1]);out++ }
		for f in 0 .. nf { staged[out]=face_x[f];out++;staged[out]=face_y[f];out++ }
		for f in 0 .. nf { for i in 0 .. degree[f] { vertex:=face[f][i];next:=face[f][(i+1)%degree[f]];prev:=face[f][(i+degree[f]-1)%degree[f]];u1:=if vertex<next {vertex}else{next};v1:=if vertex<next {next}else{vertex};u2:=if prev<vertex {prev}else{vertex};v2:=if prev<vertex {vertex}else{prev};mut en:=0;mut ep:=0;for e in 0..ne {if edges[e].u==u1&&edges[e].v==v1 {en=e};if edges[e].u==u2&&edges[e].v==v2 {ep=e}};staged[out]=f64(vertex);out++;staged[out]=f64(nv+en);out++;staged[out]=f64(nv+ne+f);out++;staged[out]=f64(nv+ep);out++ } }
		if out > max_out { return -1 }
		if output == nil || capacity < usize(out) { return -2 }
		for i in 0 .. out { output[i] = staged[i] }
		return i64(out)
	}
}
