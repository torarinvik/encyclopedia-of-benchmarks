// Rodinia SRAD v2 bounded two-kernel profile; full source license and citations:
// benchmarks/r/rodinia_srad_v2/LICENSE.txt.
module rodinia_srad_v2

import math

const pixels = 256
const input_count = 258
const lambda_min = u32(0x3c23d70a)
const lambda_max = u32(0x3dcccccd)
const q0_min = u32(0x3c23d70a)
const q0_max = u32(0x3f800000)
const j_min = u32(0x3f800000)
const j_max = u32(0x3fa00000)

@[inline]
fn add32(a f32, b f32) f32 { return a + b }
@[inline]
fn sub32(a f32, b f32) f32 { return a - b }
@[inline]
fn mul32(a f32, b f32) f32 { return a * b }
@[inline]
fn div32(a f32, b f32) f32 { return a / b }

fn srad_from_bits(bits u32) f32 {
	mut value := f32(1.0 + f64(bits & u32(0x7fffff)) / 8388608.0)
	mut exponent := int((bits >> 23) & 255) - 127
	for exponent > 0 {
		value *= f32(2.0)
		exponent--
	}
	for exponent < 0 {
		value /= f32(2.0)
		exponent++
	}
	return value
}

@[export: 'rodinia_srad_v2']
pub fn rodinia_srad_v2(values &i64, length usize) i64 {
    unsafe {
        if values == nil || length != input_count { return -1 }
        for i in 0 .. length {
            if values[i] < 0 || u64(values[i]) > u64(0xffff_ffff) { return -1 }
        }
        lambda_bits := u32(values[0])
        q0_bits := u32(values[1])
        if lambda_bits < lambda_min || lambda_bits > lambda_max || q0_bits < q0_min || q0_bits > q0_max { return -1 }
		lambda := srad_from_bits(lambda_bits)
		q0sqr := srad_from_bits(q0_bits)
        mut image := [pixels]f32{}
        mut coeff := [pixels]f32{}
        mut north := [pixels]f32{}
        mut south := [pixels]f32{}
        mut west := [pixels]f32{}
        mut east := [pixels]f32{}
        for i in 0 .. pixels {
            bits := u32(values[i + 2])
            if bits < j_min || bits > j_max { return -1 }
			image[i] = srad_from_bits(bits)
        }
        for row in 0 .. 16 {
            for col in 0 .. 16 {
                i := row * 16 + col
                jc := image[i]
                n := sub32(image[(if row > 0 { row - 1 } else { row }) * 16 + col], jc)
                s := sub32(image[(if row < 15 { row + 1 } else { row }) * 16 + col], jc)
                w := sub32(image[row * 16 + (if col > 0 { col - 1 } else { col })], jc)
                e := sub32(image[row * 16 + (if col < 15 { col + 1 } else { col })], jc)
                north[i], south[i], west[i], east[i] = n, s, w, e
                mut gradient := add32(add32(add32(mul32(n,n),mul32(s,s)),mul32(w,w)),mul32(e,e))
                gradient = div32(gradient,mul32(jc,jc))
                laplacian := div32(add32(add32(add32(n,s),w),e),jc)
                lap_sq := mul32(laplacian,laplacian)
                num := f32(0.5 * f64(gradient) - (1.0/16.0) * f64(lap_sq))
                mut den := f32(1.0 + 0.25 * f64(laplacian))
                if den == 0 { return -1 }
                qsqr := div32(num,mul32(den,den))
                den = div32(sub32(qsqr,q0sqr),mul32(q0sqr,add32(f32(1),q0sqr)))
                if den == -1 { return -1 }
                c := f32(1.0 / (1.0 + f64(den)))
				if math.is_inf(f64(c), 0) || math.is_nan(f64(c)) { return -1 }
				mut saturated := c
				if saturated < 0 { saturated = 0 }
				if saturated > 1 { saturated = 1 }
				coeff[i] = saturated
            }
        }
        mut checksum := i64(0)
        for row in 0 .. 16 {
            for col in 0 .. 16 {
                i := row * 16 + col
                cc := coeff[i]
                cs := coeff[(if row < 15 { row + 1 } else { row }) * 16 + col]
                ce := coeff[row * 16 + (if col < 15 { col + 1 } else { col })]
                divergence := add32(add32(add32(mul32(cc,north[i]),mul32(cs,south[i])),mul32(cc,west[i])),mul32(ce,east[i]))
                updated := f32(f64(image[i]) + 0.25 * f64(lambda) * f64(divergence))
                if math.is_inf(f64(updated), 0) || math.is_nan(f64(updated)) || updated < 0 { return -1 }
                checksum += i64(f64(updated) * 1_000_000.0 + 0.5)
            }
        }
        return checksum
    }
}
