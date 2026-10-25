// Rodinia SRAD v2 bounded two-kernel profile; full source license and citations:
// benchmarks/r/rodinia_srad_v2/LICENSE.txt.
package rodinia_srad_v2

import "core:c"
import "core:math"

PIXELS :: 256
INPUTS :: 258
LAMBDA_MIN :: u32(0x3c23d70a)
LAMBDA_MAX :: u32(0x3dcccccd)
Q0_MIN :: u32(0x3c23d70a)
Q0_MAX :: u32(0x3f800000)
J_MIN :: u32(0x3f800000)
J_MAX :: u32(0x3fa00000)

add32 :: proc "contextless" (a, b: f32) -> f32 { return a + b }
sub32 :: proc "contextless" (a, b: f32) -> f32 { return a - b }
mul32 :: proc "contextless" (a, b: f32) -> f32 { return a * b }
div32 :: proc "contextless" (a, b: f32) -> f32 { return a / b }

@(export)
rodinia_srad_v2 :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != c.size_t(INPUTS) do return -1
    for i: usize = 0; i < usize(length); i += 1 {
        if values[i] < 0 || values[i] > 4294967295 do return -1
    }
    lambda_bits, q0_bits := u32(values[0]), u32(values[1])
    if lambda_bits < LAMBDA_MIN || lambda_bits > LAMBDA_MAX || q0_bits < Q0_MIN || q0_bits > Q0_MAX do return -1
    lambda, q0sqr := transmute(f32)(lambda_bits), transmute(f32)(q0_bits)
    image, coeff := [PIXELS]f32{}, [PIXELS]f32{}
    north, south, west, east := [PIXELS]f32{}, [PIXELS]f32{}, [PIXELS]f32{}, [PIXELS]f32{}
    for i: usize = 0; i < PIXELS; i += 1 {
        bits := u32(values[i+2])
        if bits < J_MIN || bits > J_MAX do return -1
        image[i] = transmute(f32)(bits)
    }
    for row: usize = 0; row < 16; row += 1 {
        for col: usize = 0; col < 16; col += 1 {
            i := row*16+col
            jc := image[i]
            n := sub32(image[(if row > 0 do row-1 else do row)*16+col], jc)
            s := sub32(image[(if row < 15 do row+1 else do row)*16+col], jc)
            w := sub32(image[row*16+(if col > 0 do col-1 else do col)], jc)
            e := sub32(image[row*16+(if col < 15 do col+1 else do col)], jc)
            north[i], south[i], west[i], east[i] = n, s, w, e
            gradient := add32(add32(add32(mul32(n,n),mul32(s,s)),mul32(w,w)),mul32(e,e))
            gradient = div32(gradient,mul32(jc,jc))
            laplacian := div32(add32(add32(add32(n,s),w),e),jc)
            lap_sq := mul32(laplacian,laplacian)
            num := f32(0.5*f64(gradient)-(1.0/16.0)*f64(lap_sq))
            den := f32(1.0+0.25*f64(laplacian))
            if den == 0 do return -1
            qsqr := div32(num,mul32(den,den))
            den = div32(sub32(qsqr,q0sqr),mul32(q0sqr,add32(1.0,q0sqr)))
            if den == -1 do return -1
            c := f32(1.0/(1.0+f64(den)))
            if !math.is_finite(f64(c)) do return -1
            coeff[i] = min(1.0,max(0.0,c))
        }
    }
    checksum: i64 = 0
    for row: usize = 0; row < 16; row += 1 {
        for col: usize = 0; col < 16; col += 1 {
            i := row*16+col
            cc := coeff[i]
            cs := coeff[(if row < 15 do row+1 else do row)*16+col]
            ce := coeff[row*16+(if col < 15 do col+1 else do col)]
            divergence := add32(add32(add32(mul32(cc,north[i]),mul32(cs,south[i])),mul32(cc,west[i])),mul32(ce,east[i]))
            updated := f32(f64(image[i])+0.25*f64(lambda)*f64(divergence))
            if !math.is_finite(f64(updated)) || updated < 0 do return -1
            checksum += i64(f64(updated)*1000000.0+0.5)
        }
    }
    return checksum
}
