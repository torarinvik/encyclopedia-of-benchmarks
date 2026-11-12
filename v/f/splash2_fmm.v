module splash2_fmm

import math

const max_particles = 48
const boxes = 16
const order = 32
const stride = order + 1

@[export: 'splash2_fmm']
pub fn splash2_fmm(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if isnil(input) || input_length < 7 || input_length > 145 { return -1 }
		requested := input[0]
		if requested != requested || requested < 2.0 || requested > 48.0 || f64(int(requested)) != requested { return -1 }
		n := int(requested)
		if input_length != usize(1 + 3*n) { return -1 }
		mut x := [max_particles]f64{}
		mut y := [max_particles]f64{}
		mut charge := [max_particles]f64{}
		mut box_id := [max_particles]int{}
		for i in 0 .. n {
			px, py, q := input[1+3*i], input[2+3*i], input[3+3*i]
			if px != px || px < 0.0 || px >= 8.0 || f64(int(px)) != px || py != py || py < 0.0 || py >= 8.0 || f64(int(py)) != py || q != q || q < -3.0 || q > 3.0 || f64(int(q)) != q { return -1 }
			x[i] = px; y[i] = py; charge[i] = q
			box_id[i] = (int(py)/2)*4 + int(px)/2
			for j in 0 .. i { if x[i] == x[j] && y[i] == y[j] { return -1 } }
		}
		if isnil(output) || output_capacity < usize(n) { return -2 }
		mut mr := [boxes][stride]f64{}
		mut mi := [boxes][stride]f64{}
		mut lr := [boxes][stride]f64{}
		mut li := [boxes][stride]f64{}
		for i in 0 .. n {
			b := box_id[i]; bx := b%4; by := b/4
			zr := x[i]-f64(2*bx+1); zi := y[i]-f64(2*by+1)
			mut pr := 1.0; mut pi := 0.0
			mr[b][0] += charge[i]
			for k in 1 .. order+1 {
				nr := pr*zr-pi*zi; ni := pr*zi+pi*zr
				pr = nr; pi = ni; mr[b][k] += charge[i]*pr; mi[b][k] += charge[i]*pi
			}
		}
		for target in 0 .. boxes {
			tx := target%4; ty := target/4
			for source in 0 .. boxes {
				sx := source%4; sy := source/4
				dbx := tx-sx; dby := ty-sy
				if dbx >= -1 && dbx <= 1 && dby >= -1 && dby <= 1 { continue }
				dx := 2.0*f64(dbx); dy := 2.0*f64(dby); r2 := dx*dx+dy*dy
				mut ir := [2*order+1]f64{}
				mut ii := [2*order+1]f64{}
				ir[0] = 1.0; odr := dx/r2; odi := -dy/r2
				for p in 1 .. 2*order+1 { ir[p] = ir[p-1]*odr-ii[p-1]*odi; ii[p] = ir[p-1]*odi+ii[p-1]*odr }
				mut constant := mr[source][0]*0.5*math.log(r2)
				for k in 1 .. order+1 { constant -= (mr[source][k]*ir[k]-mi[source][k]*ii[k])/f64(k) }
				lr[target][0] += constant
				for deg in 1 .. order+1 {
					mut sr := f64(0); mut si := f64(0)
					for k in 1 .. order+1 {
						mut choose := f64(1)
						for j in 1 .. deg+1 { choose *= f64(k+j-1)/f64(j) }
						scale := choose/f64(k); p := k+deg
						sr += scale*(mr[source][k]*ir[p]-mi[source][k]*ii[p]); si += scale*(mr[source][k]*ii[p]+mi[source][k]*ir[p])
					}
					qscale := (if deg%2 == 1 { f64(1) } else { f64(-1) })/f64(deg)
					mscale := if deg%2 == 1 { f64(-1) } else { f64(1) }
					lr[target][deg] += mr[source][0]*qscale*ir[deg]-mscale*sr
					li[target][deg] += mr[source][0]*qscale*ii[deg]-mscale*si
				}
			}
		}
		for i in 0 .. n {
			b := box_id[i]; bx := b%4; by := b/4
			wr := x[i]-f64(2*bx+1); wi := y[i]-f64(2*by+1)
			mut pr := 1.0; mut pi := 0.0; mut value := lr[b][0]
			for deg in 1 .. order+1 { nr := pr*wr-pi*wi; ni := pr*wi+pi*wr; pr=nr; pi=ni; value += lr[b][deg]*pr-li[b][deg]*pi }
			for j in 0 .. n {
				if j == i { continue }
				sb := box_id[j]; sx := sb%4; sy := sb/4
				dbx := bx-sx; dby := by-sy
				if dbx < -1 || dbx > 1 || dby < -1 || dby > 1 { continue }
				dx := x[j]-x[i]; dy := y[j]-y[i]; value += charge[j]*0.5*math.log(dx*dx+dy*dy)
			}
			output[i] = value
		}
		return i64(n)
	}
}
