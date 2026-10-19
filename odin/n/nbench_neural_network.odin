package nbench_neural_network

import "core:c"
import "core:math"

put_i64 :: proc "contextless" (out: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { out[offset+b] = u8(bits >> u64(8*b)) }
}

nbench_neural_network :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	passes := input[0]
	if passes < 1 || passes > 8 do return -1
	if output == nil || capacity < 88 do return -2
	pattern: [35]f64 = {0,1,1,1,0,1,0,0,0,1,1,0,0,0,1,1,0,0,0,1,1,0,0,0,1,1,0,0,0,0,0,1,1,1,0}
	target: [8]f64 = {0,1,0,0,1,1,1,1}
	 mw: [8][35]f64; ow: [8][8]f64
	mc: [8][35]f64; oc: [8][8]f64; mm: [8][35]f64; om: [8][8]f64
	mout: [8]f64; oout: [8]f64
	for n := 0; n < 8; n += 1 { for w := 0; w < 35; w += 1 { mw[n][w] = f64((n*17+w*7)%101-50)/1000.0 } }
	for n := 0; n < 8; n += 1 { for w := 0; w < 8; w += 1 { ow[n][w] = f64((n*13+w*5)%71-35)/1000.0 } }
	for pass := i64(0); pass < passes; pass += 1 {
		for n := 0; n < 8; n += 1 { for w := 0; w < 35; w += 1 { mc[n][w] = mm[n][w]; mm[n][w] = 0 } }
		for n := 0; n < 8; n += 1 { for w := 0; w < 8; w += 1 { oc[n][w] = om[n][w]; om[n][w] = 0 } }
		for f := 0; f < 2; f += 1 { for n := 0; n < 8; n += 1 { sum := 0.0; for w := 0; w < 35; w += 1 { sum += mw[n][w]*pattern[w] }; mout[n] = 1.0/(1.0+math.exp(-sum)) } }
		for n := 0; n < 8; n += 1 { sum := 0.0; for w := 0; w < 8; w += 1 { sum += ow[n][w]*mout[w] }; oout[n] = 1.0/(1.0+math.exp(-sum)) }
		oe: [8]f64; me: [8]f64
		for n := 0; n < 8; n += 1 { oe[n] = target[n]-oout[n] }
		for n := 0; n < 8; n += 1 { sum := 0.0; for i := 0; i < 8; i += 1 { sum += ow[i][n]*oe[i] }; me[n] = mout[n]*(1.0-mout[n])*sum }
		for n := 0; n < 8; n += 1 { for w := 0; w < 8; w += 1 { delta := 0.09*oe[n]*mout[w]; delta += 0.09*oc[n][w]; ow[n][w] += delta; om[n][w] += delta } }
		for n := 0; n < 8; n += 1 { for w := 0; w < 35; w += 1 { delta := 0.09*me[n]*pattern[w]; delta += 0.09*mc[n][w]; mw[n][w] += delta; mm[n][w] += delta } }
	}
	result: [11]i64; result[0] = passes
	for n := 0; n < 8; n += 1 { result[n+1] = i64(oout[n]*1_000_000.0) }
	ms, os := 0.0, 0.0
	for n := 0; n < 8; n += 1 { for w := 0; w < 35; w += 1 { ms += mw[n][w] } }
	for n := 0; n < 8; n += 1 { for w := 0; w < 8; w += 1 { os += ow[n][w] } }
	result[9] = i64(ms*1_000_000.0); result[10] = i64(os*1_000_000.0)
	for i := 0; i < 11; i += 1 { put_i64(output, i*8, result[i]) }
	return 88
}
