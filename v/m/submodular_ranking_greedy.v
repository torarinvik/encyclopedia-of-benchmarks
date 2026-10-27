module submodular_ranking_greedy

import core.c

const max_n = 5
const max_m = 4
const max_input = 131

fn store_i64_le(out &u8, at int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { out[at+b] = u8((bits >> (8*b)) & 255) }
}

@[export: 'submodular_ranking_greedy']
pub fn submodular_ranking_greedy(input &i64, length usize, out &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n64,m64 := input[0],input[1]
		if n64 < 1 || n64 > max_n || m64 < 1 || m64 > max_m { return -1 }
		n,m := int(n64),int(m64);size := 1 << n
		if length != usize(2+m*size) { return -1 }
		mut f := [][]i64{len:m,init:[]i64{len:32,init:0}}
		for i in 0 .. m {
			for a in 0 .. size { v:=input[2+i*size+a];if v<0||v>8{return -1};f[i][a]=v }
			if f[i][0]!=0||f[i][size-1]!=8{return -1}
			for a in 0 .. size { for bit in 0 .. n { e:=1<<bit;if (a&e)==0&&f[i][a]>f[i][a|e]{return -1} } }
			for a in 0 .. size { for b in 0 .. size { if (a&b)!=a{continue};for bit in 0 .. n { e:=1<<bit;if (b&e)==0&&f[i][a|e]-f[i][a]<f[i][b|e]-f[i][b]{return -1} } } }
		}
		out_bytes:=8*(1+n+m);if out==nil||capacity<usize(out_bytes){return -2}
		mut order:=[]int{len:n,init:0};mut times:=[]i64{len:m,init:0};mut total:=i64(0);mut mask:=0
		for t in 1 .. n+1 {
			mut winner:=0;mut best_num:=i64(-1);mut best_den:=i64(1)
			for e in 0 .. n { bit:=1<<e;if (mask&bit)!=0{continue};mut num:=i64(0);mut den:=i64(1)
				for i in 0 .. m { cur:=f[i][mask];if cur==8{continue};d:=8-cur;gain:=f[i][mask|bit]-cur;num=num*d+gain*den;den*=d }
				if best_num<0||num*best_den>best_num*den{winner=e;best_num=num;best_den=den}
			}
			mask|=1<<winner;order[t-1]=winner
			for i in 0 .. m { if times[i]==0&&f[i][mask]==8{times[i]=i64(t);total+=i64(t)} }
		}
		store_i64_le(out,0,total)
		for j in 0 .. n { store_i64_le(out,8*(1+j),i64(order[j])) }
		for i in 0 .. m { store_i64_le(out,8*(1+n+i),times[i]) }
		return i64(out_bytes)
	}
}
