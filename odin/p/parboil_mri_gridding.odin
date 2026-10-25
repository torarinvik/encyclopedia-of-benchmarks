package parboil_mri_gridding

import "core:c"
import "core:math"

CELLS :: 27
MAX_SAMPLES :: 4
WIDTH :: f32(2.5)
OVERSAMPLE :: f32(0.608933)
COEFF := [15]f32{
	0.210580722890567e-22, 0.380715242345326e-19, 0.479440257548300e-16,
	0.435125971262668e-13, 0.300931127112960e-10, 0.160224679395361e-7,
	0.654858370096785e-5, 0.202591084143397e-2, 0.463076284721000e0,
	0.754337328948189e2, 0.830792541809429e4, 0.571661130563785e6,
	0.216415572361227e8, 0.356644482244025e9, 0.144048298227235e10,
}

decode :: proc(raw: i64) -> f32 { return f32(raw) / 1_000_000.0 }
kernel :: proc(value: f32) -> f32 {
	z := value*value
	num := COEFF[0]
	for i := 1; i < 15; i += 1 { product := z*num; num = product+COEFF[i] }
	den := z-f32(0.307646912682801e4)
	den = z*den; den = den+f32(0.347626332405882e7)
	den = z*den; den = den-f32(0.144048298227235e10)
	return -num/den
}
beta_value :: proc() -> f32 {
	first := f32(4.0)*WIDTH; first = first*WIDTH
	divisor := OVERSAMPLE*OVERSAMPLE; first = first/divisor
	shifted := f64(OVERSAMPLE)-0.5
	arg := f64(first)*shifted; arg = arg*shifted; arg = arg-0.8
	return f32(3.14159265359*math.sqrt(arg))
}
weight :: proc(v, inverse, beta, sdc: f32) -> f32 {
	product := v*inverse
	radicand := 1.0-f64(product)
	argument := f32(f64(beta)*math.sqrt(radicand))
	return kernel(argument)*sdc
}
lower :: proc(k, cutoff: f32) -> int {
	delta := k-cutoff
	if delta < 0 { return 0 }
	return int(u32(delta))
}
upper :: proc(k, cutoff: f32) -> int {
	total := k+cutoff
	if total > 2 { return 2 }
	return int(u32(total))
}
quantize :: proc(value: f32) -> i64 {
	scaled := value*1000.0
	mag := scaled; if mag < 0 { mag = -mag }
	whole := i64(mag)
	if mag-f32(whole) >= 0.5 { whole += 1 }
	if scaled < 0 { return -whole }
	return whole
}

@(export)
parboil_mri_gridding :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 25 do return -1
	n := input[0]
	if n < 0 || n > MAX_SAMPLES || length != c.size_t(1+6*n) do return -1
	for s := 0; s < int(n); s += 1 {
		p := 1+6*s
		for a := 0; a < 3; a += 1 { if input[p+a] != 0 && input[p+a] != 1_000_000 && input[p+a] != 2_000_000 do return -1 }
		if input[p+3] < -1_000_000 || input[p+3] > 1_000_000 || input[p+4] < -1_000_000 || input[p+4] > 1_000_000 || input[p+5] < 0 || input[p+5] > 1_000_000 do return -1
	}
	var real: [CELLS]f32 = {}
	var imag: [CELLS]f32 = {}
	var density: [CELLS]f32 = {}
	cutoff := f32(f64(WIDTH)/2.0); cutoff2 := cutoff*cutoff; inverse := f32(1.0)/cutoff2; beta := beta_value()
	for s := 0; s < int(n); s += 1 {
		p := 1+6*s
		kx, ky, kz := decode(input[p]), decode(input[p+1]), decode(input[p+2])
		sr, si, sdc := decode(input[p+3]), decode(input[p+4]), decode(input[p+5])
		if (sr != 0 || si != 0) && sdc != 0 {
			x0, x1 := lower(kx,cutoff), upper(kx,cutoff); y0, y1 := lower(ky,cutoff), upper(ky,cutoff); z0, z1 := lower(kz,cutoff), upper(kz,cutoff)
			for z := z0; z <= z1; z += 1 {
				dz := kz-f32(z); dz2 := dz*dz
				if dz2 < cutoff2 {
					for y := y0; y <= y1; y += 1 {
						dy := ky-f32(y); dy2 := dy*dy; yz := dz2+dy2
						if yz < cutoff2 {
							for x := x0; x <= x1; x += 1 {
								dx := kx-f32(x); dx2 := dx*dx; v := yz+dx2
								if v < cutoff2 {
									index := x+3*y+9*z; w := weight(v,inverse,beta,sdc)
									dr, di := w*sr, w*si
									real[index] = real[index]+dr; imag[index] = imag[index]+di
									density[index] = f32(f64(density[index])+1.0)
								}
							}
						}
					}
				}
			}
		}
	}
	checksum: i64 = 0
	for i := 0; i < CELLS; i += 1 { checksum += i64(i+1)*(quantize(real[i])+quantize(imag[i])+i64(density[i])) }
	return checksum
}
