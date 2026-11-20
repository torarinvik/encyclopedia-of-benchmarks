package bkp_speed_scaling_trace

import "core:c"

MAX_JOBS :: 4
MAX_SAMPLES :: 8
MAX_OUTPUT :: 136
E_NUM :: i64(271828)
E_DEN :: i64(100000)
EM1_NUM :: i64(171828)

gcd64 :: proc(a0,b0: i64) -> i64 {
	a,b := a0,b0
	for b != 0 { r := a%b; a=b; b=r }
	if a < 0 { return -a }
	return a
}
consider :: proc(release,deadline,work: [^]i64,n: int,t,x_num,x_den: i64,best_num,best_den: ^i64) {
	delta := x_num-t*x_den
	if delta <= 0 do return
	left := E_NUM*t*x_den-EM1_NUM*x_num
	total: i64 = 0
	for j := 0; j < n; j += 1 {
		if release[j] <= t && left <= E_DEN*x_den*release[j] && deadline[j]*x_den <= x_num { total += work[j] }
	}
	num := total*x_den
	if num * best_den^ > best_num^ * delta { best_num^=num; best_den^=delta }
}
put64 :: proc(output: [^]u8,at: int,value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { output[at+b]=u8((bits>>(8*b))&255) }
}

@(export)
bkp_speed_scaling_trace :: proc "c" (input: [^]i64,length: c.size_t,
	output: [^]u8,capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 31 do return -1
	n64,samples64 := input[0],input[1]
	if n64 < 1 || n64 > MAX_JOBS || samples64 < 1 || samples64 > MAX_SAMPLES do return -1
	n,samples := int(n64),int(samples64)
	if length != c.size_t(2+3*n+2*samples) do return -1
	release,deadline,work: [MAX_JOBS]i64
	for j := 0; j < n; j += 1 {
		release[j],deadline[j],work[j] = input[2+3*j],input[3+3*j],input[4+3*j]
		if release[j] < 0 || release[j] >= deadline[j] || deadline[j] > 8 || work[j] < 1 || work[j] > 8 do return -1
	}
	values: [1+2*MAX_SAMPLES]i64
	values[0]=samples64
	for s := 0; s < samples; s += 1 {
		t,mask := input[2+3*n+2*s],input[3+3*n+2*s]
		if t < 0 || t > 8 || mask < 0 || mask >= (i64(1)<<n) do return -1
		for j := 0; j < n; j += 1 { if (mask&(i64(1)<<j)) != 0 && release[j] > t do return -1 }
		best_num,best_den := i64(0),i64(1)
		if mask != 0 {
			for j := 0; j < n; j += 1 {
				if release[j] <= t {
					if deadline[j] > t { consider(&release[0],&deadline[0],&work[0],n,t,deadline[j],1,&best_num,&best_den) }
					if release[j] < t { consider(&release[0],&deadline[0],&work[0],n,t,E_NUM*t-E_DEN*release[j],EM1_NUM,&best_num,&best_den) }
				}
			}
		}
		g := gcd64(best_num,best_den)
		values[1+2*s],values[2+2*s]=best_num/g,best_den/g
	}
	bytes := 8*(1+2*samples)
	if output == nil || capacity < c.size_t(bytes) do return -2
	staged: [MAX_OUTPUT]u8
	for i := 0; i < 1+2*samples; i += 1 { put64(&staged[0],8*i,values[i]) }
	for i := 0; i < bytes; i += 1 { output[i]=staged[i] }
	return i64(bytes)
}
