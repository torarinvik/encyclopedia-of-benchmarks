@[export: 'mdp_value_iteration_deterministic']
pub fn mdp_value_iteration_deterministic(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 7 || length > 29 { return -1 }
		s64:=input[0]; a64:=input[1]; h64:=input[2]; p:=input[3]; q:=input[4]
		if s64<1 || s64>4 || a64<1 || a64>3 || h64<1 || h64>8 || q<1 || q>4 || p<0 || p>=q || length!=usize(5+2*s64*a64) { return -1 }
		states:=int(s64); actions:=int(a64); horizon:=int(h64)
		mut rewards:=[][]i64{len:states,init:[]i64{len:actions,init:0}}
		mut targets:=[][]i64{len:states,init:[]i64{len:actions,init:0}}
		mut at:=5
		for s in 0..states { for a in 0..actions {
			r:=input[at]; target:=input[at+1]; at+=2
			if r < -100 || r > 100 || target < 0 || target >= s64 { return -1 }
			rewards[s][a]=r; targets[s][a]=target
		} }
		mut scale:=i64(1)
		for _ in 0..horizon { scale*=q }
		mut value:=[]i64{len:states,init:0}; mut next_value:=[]i64{len:states,init:0}; mut policy:=[]i64{len:states,init:0}
		for _ in 0..horizon {
			for s in 0..states {
				mut best:=i64(0); mut best_action:=0
				for a in 0..actions {
					candidate:=rewards[s][a]*scale+p*(value[int(targets[s][a])]/q)
					if a==0 || candidate>best { best=candidate; best_action=a }
				}
				next_value[s]=best; policy[s]=i64(best_action)
			}
			for s in 0..states { value[s]=next_value[s] }
		}
		bytes:=8*(1+2*states)
		if output==nil || capacity<usize(bytes) { return -2 }
		mut fields:=[]i64{len:1+2*states,init:0}; fields[0]=scale
		for s in 0..states { fields[1+s]=value[s]; fields[1+states+s]=policy[s] }
		for i in 0..fields.len {
			bits:=u64(fields[i])
			for b in 0..8 { output[8*i+b]=u8((bits>>(8*b))&255) }
		}
		return i64(bytes)
	}
}
