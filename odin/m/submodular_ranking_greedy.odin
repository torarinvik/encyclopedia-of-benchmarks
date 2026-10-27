package submodular_ranking_greedy

import "core:c"

MAX_N :: 5
MAX_M :: 4
MAX_INPUT :: 131

store_i64_le :: proc(out: [^]u8, at: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { out[at+b] = u8(bits & 255); bits >>= 8 }
}

@(export)
submodular_ranking_greedy :: proc "c" (input: [^]i64, length: c.size_t,
	out: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n64, m64 := input[0], input[1]
	if n64 < 1 || n64 > MAX_N || m64 < 1 || m64 > MAX_M do return -1
	n,m := int(n64),int(m64);size := 1 << n
	if length != c.size_t(2+m*size) do return -1
	f: [MAX_M][32]i64
	for i := 0; i < m; i += 1 {
		for a := 0; a < size; a += 1 { v := input[2+i*size+a]; if v < 0 || v > 8 do return -1; f[i][a] = v }
		if f[i][0] != 0 || f[i][size-1] != 8 do return -1
		for a := 0; a < size; a += 1 { for bit := 0; bit < n; bit += 1 { e := 1 << bit; if (a&e)==0 && f[i][a]>f[i][a|e] do return -1 } }
		for a := 0; a < size; a += 1 { for b := 0; b < size; b += 1 { if (a&b)!=a do continue; for bit := 0; bit < n; bit += 1 { e := 1 << bit; if (b&e)==0 && f[i][a|e]-f[i][a]<f[i][b|e]-f[i][b] do return -1 } } }
	}
	out_bytes := 8*(1+n+m)
	if out == nil || capacity < c.size_t(out_bytes) do return -2
	order: [MAX_N]int;times: [MAX_M]i64;total: i64 = 0;mask := 0
	for t := 1; t <= n; t += 1 {
		winner := 0;best_num: i64 = -1;best_den: i64 = 1
		for e := 0; e < n; e += 1 { bit := 1 << e; if (mask&bit)!=0 do continue; num: i64 = 0;den: i64 = 1
			for i := 0; i < m; i += 1 { cur := f[i][mask];if cur==8 do continue;d := 8-cur;gain := f[i][mask|bit]-cur;num=num*d+gain*den;den*=d }
			if best_num < 0 || num*best_den > best_num*den { winner=e;best_num=num;best_den=den }
		}
		mask |= 1 << winner;order[t-1]=winner
		for i := 0; i < m; i += 1 { if times[i]==0 && f[i][mask]==8 { times[i]=i64(t);total+=i64(t) } }
	}
	store_i64_le(out,0,total)
	for j := 0; j < n; j += 1 { store_i64_le(out,8*(1+j),i64(order[j])) }
	for i := 0; i < m; i += 1 { store_i64_le(out,8*(1+n+i),times[i]) }
	return i64(out_bytes)
}
