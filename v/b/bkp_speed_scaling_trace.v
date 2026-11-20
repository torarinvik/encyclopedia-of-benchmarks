module bkp_speed_scaling_trace

const max_jobs = 4
const max_samples = 8
const max_bytes = 136
const e_num = i64(271828)
const e_den = i64(100000)
const em1_num = i64(171828)

fn gcd64(a0 i64, b0 i64) i64 {
	mut a, mut b := a0, b0
	for b != 0 { r := a % b; a = b; b = r }
	if a < 0 { return -a }
	return a
}
fn consider(r &i64,d &i64,w &i64,n int,t i64,x_num i64,x_den i64,bn &i64,bd &i64) {
	unsafe {
		delta := x_num-t*x_den
		if delta <= 0 { return }
		left := e_num*t*x_den-em1_num*x_num
		mut total := i64(0)
		for j in 0 .. n { if r[j] <= t && left <= e_den*x_den*r[j] && d[j]*x_den <= x_num { total += w[j] } }
		numerator := total*x_den
		if numerator*bd[0] > bn[0]*delta { bn[0] = numerator; bd[0] = delta }
	}
}
fn put64(output &u8,at int,value i64) {
	unsafe {
		bits := u64(value)
		for b in 0 .. 8 { output[at+b] = u8((bits>>(8*b))&255) }
	}
}

@[export: 'bkp_speed_scaling_trace']
pub fn bkp_speed_scaling_trace(input &i64,length usize,output &u8,capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 31 { return -1 }
		n64, samples64 := input[0], input[1]
		if n64 < 1 || n64 > i64(max_jobs) || samples64 < 1 || samples64 > i64(max_samples) { return -1 }
		n, samples := int(n64), int(samples64)
		if length != usize(2+3*n+2*samples) { return -1 }
		mut r := [max_jobs]i64{init: 0}
		mut d := [max_jobs]i64{init: 0}
		mut w := [max_jobs]i64{init: 0}
		for j in 0 .. n {
			r[j], d[j], w[j] = input[2+3*j], input[3+3*j], input[4+3*j]
			if r[j] < 0 || r[j] >= d[j] || d[j] > 8 || w[j] < 1 || w[j] > 8 { return -1 }
		}
		mut values := [1+2*max_samples]i64{init: 0}
		values[0] = samples64
		for s in 0 .. samples {
			t, mask := input[2+3*n+2*s], input[3+3*n+2*s]
			if t < 0 || t > 8 || mask < 0 || mask >= (i64(1)<<n) { return -1 }
			for j in 0 .. n { if mask&(i64(1)<<j) != 0 && r[j] > t { return -1 } }
			mut bn, mut bd := i64(0), i64(1)
			if mask != 0 {
				for j in 0 .. n {
					if r[j] <= t {
						if d[j] > t { consider(&r[0],&d[0],&w[0],n,t,d[j],1,bn,bd) }
						if r[j] < t { consider(&r[0],&d[0],&w[0],n,t,e_num*t-e_den*r[j],em1_num,bn,bd) }
					}
				}
			}
			g := gcd64(bn,bd)
			values[1+2*s], values[2+2*s] = bn/g, bd/g
		}
		bytes := 8*(1+2*samples)
		if output == nil || capacity < usize(bytes) { return -2 }
		mut staged := [max_bytes]u8{init: 0}
		for i in 0 .. 1+2*samples { put64(&staged[0],8*i,values[i]) }
		for i in 0 .. bytes { output[i] = staged[i] }
		return i64(bytes)
	}
}
