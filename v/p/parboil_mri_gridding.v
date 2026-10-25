module parboil_mri_gridding

import math

const cells = 27
const max_samples = 4
const width = f32(2.5)
const oversample = f32(0.608933)
const coeff = [15]f32{
	0.210580722890567e-22, 0.380715242345326e-19, 0.479440257548300e-16,
	0.435125971262668e-13, 0.300931127112960e-10, 0.160224679395361e-7,
	0.654858370096785e-5, 0.202591084143397e-2, 0.463076284721000e0,
	0.754337328948189e2, 0.830792541809429e4, 0.571661130563785e6,
	0.216415572361227e8, 0.356644482244025e9, 0.144048298227235e10
}

fn decode(raw i64) f32 { return f32(raw) / f32(1_000_000) }
fn kernel(value f32) f32 {
	z := value * value
	mut num := coeff[0]
	for i in 1 .. 15 { product := z * num; num = product + coeff[i] }
	mut den := z - f32(0.307646912682801e4)
	den = z * den; den = den + f32(0.347626332405882e7)
	den = z * den; den = den - f32(0.144048298227235e10)
	return -num / den
}
fn beta_value() f32 {
	mut first := f32(4.0) * width; first = first * width
	divisor := oversample * oversample; first = first / divisor
	shifted := f64(oversample) - 0.5
	mut arg := f64(first) * shifted; arg = arg * shifted; arg = arg - 0.8
	return f32(3.14159265359 * math.sqrt(arg))
}
fn weight(v f32, inverse f32, beta f32, sdc f32) f32 {
	product := v * inverse
	radicand := 1.0 - f64(product)
	argument := f32(f64(beta) * math.sqrt(radicand))
	return kernel(argument) * sdc
}
fn lower(k f32, cutoff f32) int {
	delta := k - cutoff
	if delta < 0 { return 0 }
	return int(delta)
}
fn upper(k f32, cutoff f32) int {
	total := k + cutoff
	if total > 2 { return 2 }
	return int(total)
}
fn quantize(value f32) i64 {
	scaled := value * f32(1000)
	mut magnitude := scaled
	if magnitude < 0 { magnitude = -magnitude }
	mut whole := i64(magnitude)
	if magnitude - f32(whole) >= f32(0.5) { whole++ }
	if scaled < 0 { return -whole }
	return whole
}

@[export: 'parboil_mri_gridding']
pub fn parboil_mri_gridding(input &i64, input_length usize) i64 {
	if unsafe { input == nil } || input_length < 1 || input_length > 25 { return -1 }
	mut values := [25]i64{}
	unsafe { for i in 0 .. int(input_length) { values[i] = input[i] } }
	n := values[0]
	if n < 0 || n > i64(max_samples) || input_length != usize(1 + 6*n) { return -1 }
	for s in 0 .. int(n) {
		p := 1 + 6*s
		for a in 0 .. 3 { if values[p+a] != 0 && values[p+a] != 1_000_000 && values[p+a] != 2_000_000 { return -1 } }
		if values[p+3] < -1_000_000 || values[p+3] > 1_000_000 || values[p+4] < -1_000_000 || values[p+4] > 1_000_000 || values[p+5] < 0 || values[p+5] > 1_000_000 { return -1 }
	}
	mut real := [cells]f32{}
	mut imag := [cells]f32{}
	mut density := [cells]f32{}
	cutoff := f32(f64(width) / 2.0); cutoff2 := cutoff * cutoff; inverse := f32(1) / cutoff2; beta := beta_value()
	for s in 0 .. int(n) {
		p := 1 + 6*s
		kx, ky, kz := decode(values[p]), decode(values[p+1]), decode(values[p+2])
		sr, si, sdc := decode(values[p+3]), decode(values[p+4]), decode(values[p+5])
		if (sr != 0 || si != 0) && sdc != 0 {
			x0, x1 := lower(kx,cutoff), upper(kx,cutoff); y0, y1 := lower(ky,cutoff), upper(ky,cutoff); z0, z1 := lower(kz,cutoff), upper(kz,cutoff)
			for z := z0; z <= z1; z++ {
				dz := kz-f32(z); dz2 := dz*dz
				if dz2 < cutoff2 {
					for y := y0; y <= y1; y++ {
						dy := ky-f32(y); dy2 := dy*dy; yz := dz2+dy2
						if yz < cutoff2 {
							for x := x0; x <= x1; x++ {
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
	mut checksum := i64(0)
	for i in 0 .. cells { checksum += i64(i+1)*(quantize(real[i])+quantize(imag[i])+i64(density[i])) }
	return checksum
}
