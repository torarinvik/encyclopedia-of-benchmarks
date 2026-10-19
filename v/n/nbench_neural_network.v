module nbench_neural_network

import math

fn put_i64(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for b := 0; b < 8; b++ { unsafe { output[offset+b] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'nbench_neural_network']
pub fn nbench_neural_network(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length != 1 { return -1 }
	unsafe {
		passes := input[0]
		if passes < 1 || passes > 8 { return -1 }
		if output == nil || capacity < 88 { return -2 }
		pattern := [35]f64{0,1,1,1,0,1,0,0,0,1,1,0,0,0,1,1,0,0,0,1,1,0,0,0,1,1,0,0,0,0,0,1,1,1,0}
		target := [8]f64{0,1,0,0,1,1,1,1}
		mut mw := [8][35]f64{}
		mut ow := [8][8]f64{}
		mut mc := [8][35]f64{}
		mut oc := [8][8]f64{}
		mut mm := [8][35]f64{}
		mut om := [8][8]f64{}
		mut mout := [8]f64{}
		mut oout := [8]f64{}
		for n := 0; n < 8; n++ { for w := 0; w < 35; w++ { mw[n][w] = f64((n*17+w*7)%101-50)/1000.0 } }
		for n := 0; n < 8; n++ { for w := 0; w < 8; w++ { ow[n][w] = f64((n*13+w*5)%71-35)/1000.0 } }
		for pass := i64(0); pass < passes; pass++ {
			for n := 0; n < 8; n++ { for w := 0; w < 35; w++ { mc[n][w] = mm[n][w]; mm[n][w] = 0 } }
			for n := 0; n < 8; n++ { for w := 0; w < 8; w++ { oc[n][w] = om[n][w]; om[n][w] = 0 } }
			for f := 0; f < 2; f++ { for n := 0; n < 8; n++ { mut sum := 0.0; for w := 0; w < 35; w++ { sum += mw[n][w]*pattern[w] }; mout[n] = 1.0/(1.0+math.exp(-sum)) } }
			for n := 0; n < 8; n++ { mut sum := 0.0; for w := 0; w < 8; w++ { sum += ow[n][w]*mout[w] }; oout[n] = 1.0/(1.0+math.exp(-sum)) }
			mut oe := [8]f64{}; mut me := [8]f64{}
			for n := 0; n < 8; n++ { oe[n] = target[n]-oout[n] }
			for n := 0; n < 8; n++ { mut sum := 0.0; for i := 0; i < 8; i++ { sum += ow[i][n]*oe[i] }; me[n] = mout[n]*(1.0-mout[n])*sum }
			for n := 0; n < 8; n++ { for w := 0; w < 8; w++ { mut delta := 0.09*oe[n]*mout[w]; delta += 0.09*oc[n][w]; ow[n][w] += delta; om[n][w] += delta } }
			for n := 0; n < 8; n++ { for w := 0; w < 35; w++ { mut delta := 0.09*me[n]*pattern[w]; delta += 0.09*mc[n][w]; mw[n][w] += delta; mm[n][w] += delta } }
		}
		mut result := [11]i64{}
		result[0] = passes
		for n := 0; n < 8; n++ { result[n+1] = i64(oout[n]*1000000.0) }
		mut ms := 0.0; mut os := 0.0
		for n := 0; n < 8; n++ { for w := 0; w < 35; w++ { ms += mw[n][w] } }
		for n := 0; n < 8; n++ { for w := 0; w < 8; w++ { os += ow[n][w] } }
		result[9] = i64(ms*1000000.0); result[10] = i64(os*1000000.0)
		for i := 0; i < 11; i++ { put_i64(mut output, i*8, result[i]) }
		return 88
	}
}
