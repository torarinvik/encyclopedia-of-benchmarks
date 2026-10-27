module sequential_lut_k_cut_enumeration

const max_n = 3
const max_m = 3
const max_cuts = 45

fn put_i64_le(mut output &u8, word int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[word * 8 + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'sequential_lut_k_cut_enumeration']
pub fn sequential_lut_k_cut_enumeration(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 3 || length > 12 { return -1 }
	n0 := unsafe { input[0] }; k0 := unsafe { input[1] }; m0 := unsafe { input[2] }
	if n0 < 1 || n0 > 3 || k0 < 1 || k0 > 2 || m0 < 0 || m0 > 3 || length != usize(3 + 3*m0) { return -1 }
	n := int(n0); k := int(k0); m := int(m0)
	mut eu := [max_m]int{}; mut ev := [max_m]int{}; mut ed := [max_m]int{}
	for e in 0 .. m {
		u := unsafe { input[3+3*e] }; v := unsafe { input[4+3*e] }; d := unsafe { input[5+3*e] }
		if u < 0 || v <= u || v >= n0 || (d != 0 && d != 1) { return -1 }
		for j in 0 .. e { if eu[j] == int(u) && ev[j] == int(v) && ed[j] == int(d) { return -1 } }
		eu[e]=int(u); ev[e]=int(v); ed[e]=int(d)
	}
	mut in_u := [max_n * max_m]int{}; mut in_d := [max_n * max_m]int{}; mut degree := [max_n]int{}
	for e in 0 .. m { v:=ev[e]; slot:=degree[v]; in_u[v*max_m+slot]=eu[e]; in_d[v*max_m+slot]=ed[e]; degree[v]++ }
	mut cuts := [max_n * max_cuts]u64{}; mut counts := [max_n]int{}
	for v in 0 .. n {
		cuts[v*max_cuts]=u64(1) << (3*v); counts[v]=1
		if degree[v] > 0 {
			c0:=counts[in_u[v*max_m]]
			c1:=if degree[v]>1 { counts[in_u[v*max_m+1]] } else { 1 }
			c2:=if degree[v]>2 { counts[in_u[v*max_m+2]] } else { 1 }
			for a in 0 .. c0 { for b in 0 .. c1 { for cc in 0 .. c2 {
				mut merged:=u64(0)
				for slot in 0 .. degree[v] {
					idx:=if slot==0 { a } else if slot==1 { b } else { cc }
					u:=in_u[v*max_m+slot]; delay:=in_d[v*max_m+slot]
					for bit in 0 .. 3*n {
						if cuts[u*max_cuts+idx] & (u64(1)<<bit) != 0 {
							next:=bit%3+delay; if next>2 { return -1 }
							merged |= u64(1) << (3*(bit/3)+next)
						}
					}
				}
				mut bits:=merged; mut size:=0; for bits!=0 { bits &= bits-1; size++ }
				if size<=k {
					mut found:=false; for i in 0 .. counts[v] { if cuts[v*max_cuts+i]==merged { found=true } }
					if !found && counts[v]<max_cuts { cuts[v*max_cuts+counts[v]]=merged; counts[v]++ }
				}
			}}}
		}
		for i in 1 .. counts[v] { x:=cuts[v*max_cuts+i]; mut j:=i; for j>0 && cuts[v*max_cuts+j-1]>x { cuts[v*max_cuts+j]=cuts[v*max_cuts+j-1]; j-- }; cuts[v*max_cuts+j]=x }
	}
	mut words:=1; for v in 0 .. n { words += 1+counts[v] }; bytes:=words*8
	if output==nil || capacity<usize(bytes) { return -2 }
	put_i64_le(mut output, 0, i64(n)); mut at:=1
	for v in 0 .. n { put_i64_le(mut output, at, i64(counts[v])); at++; for i in 0 .. counts[v] { put_i64_le(mut output, at, i64(cuts[v*max_cuts+i]));at++ } }
	return i64(bytes)
}
