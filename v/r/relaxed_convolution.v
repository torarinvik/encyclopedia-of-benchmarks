// New bounded relaxed-convolution schedule; see benchmarks/r/relaxed_convolution/README.md and LICENSE.txt.
module relaxed_convolution

const modulus = i64(998244353)

@[export: 'relaxed_convolution']
pub fn relaxed_convolution(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > 33 { return -1 }
		n0 := input[0]
		if n0 < 1 || n0 > 16 || input_length != usize(1+2*n0) { return -1 }
		n := int(n0)
		mut a := [16]i64{}
		mut b := [16]i64{}
		mut c := [16]i64{}
		for i in 0 .. n { a[i]=input[1+i]; b[i]=input[1+n+i]; if a[i]<0 || a[i]>=modulus || b[i]<0 || b[i]>=modulus { return -1 } }
		if output == nil || output_capacity < usize(4*n) { return -2 }
		for index in 0 .. n {
			mut value := a[index]*b[0]
			if index > 0 { value += b[index]*a[0] }
			c[index] = (c[index] + value) % modulus
			q := index+1
			mut d := 1
			for d <= q {
				if q%(2*d)==d {
					mut end_index := q+d
					if end_index > n { end_index=n }
					if q==d {
						for i in q .. end_index { target:=d+i-q; for r in 0 .. d { y:=target-r; if y<d { c[i]=(c[i]+a[r]*b[y])%modulus } } }
					} else {
						for i in q .. end_index { target:=d+i-q; for r in 0 .. d { y:=target-r; if y<2*d { c[i]=(c[i]+a[q-d+r]*b[y]+b[q-d+r]*a[y])%modulus } } }
					}
				}
				d *= 2
			}
		}
		for i in 0 .. n { x:=u32(c[i]); for j in 0 .. 4 { output[4*i+j]=u8(x>>(8*j)) } }
		return i64(4*n)
	}
}
