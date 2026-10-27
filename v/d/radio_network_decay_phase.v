@[export: 'radio_network_decay_phase']
pub fn radio_network_decay_phase(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input==nil || length<3 || length>75 { return -1 }
		n64:=input[0]; k64:=input[1]; initial:=input[2]
		if n64<2 || n64>8 || k64<1 || k64>8 || length!=usize(3+n64+n64*k64) { return -1 }
		n:=int(n64); k:=int(k64); full:=(u64(1)<<n)-1
		if initial<=0 || (u64(initial)&~full)!=0 { return -1 }
		mut adjacency:=[]u64{len:n,init:0}
		for v in 0..n { raw:=input[3+v]; if raw<0 || (u64(raw)&~full)!=0 || (u64(raw)&(u64(1)<<v))!=0 { return -1 }; adjacency[v]=u64(raw) }
		for u in 0..n { for v in 0..n { if ((adjacency[u]>>v)&1)!=((adjacency[v]>>u)&1) { return -1 } } }
		tape_at:=3+n
		for i in 0..n*k { if input[tape_at+i]!=0 && input[tape_at+i]!=1 { return -1 } }
		if output==nil || capacity<16 { return -2 }
		mut active:=[]bool{len:n,init:false}
		for v in 0..n { active[v]=((u64(initial)>>v)&1)!=0 }
		mut newly:=u64(0); mut transmissions:=i64(0)
		for slot in 0..k {
			for sender in 0..n { if active[sender] { transmissions++ } }
			for receiver in 0..n {
				if ((u64(initial)>>receiver)&1)!=0 { continue }
				mut count:=0
				for sender in 0..n { if active[sender] && ((adjacency[sender]>>receiver)&1)!=0 { count++ } }
				if count==1 { newly|=u64(1)<<receiver }
			}
			for sender in 0..n { if active[sender] && (input[tape_at+sender*k+slot]==0 || slot+1==k) { active[sender]=false } }
		}
		mut fields:=[2]i64{i64(newly),transmissions}
		for i in 0..2 { bits:=u64(fields[i]); for b in 0..8 { output[8*i+b]=u8((bits>>(8*b))&255) } }
		return 16
	}
}
