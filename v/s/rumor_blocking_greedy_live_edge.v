module rumor_blocking_greedy_live_edge

const max_n=8
const max_m=16
const max_worlds=8

fn put_i64_le(mut output &u8,word int,value i64){bits:=u64(value);for b in 0..8{unsafe{output[word*8+b]=u8((bits>>(8*b))&255)}}}

fn infected_count(n int,m int,world int,sources u16,protectors u16,eu [max_m]int,ev [max_m]int,masks [max_m]int) int {
	mut status:=[max_n]u8{};mut rf:=[max_n]bool{};mut pf:=[max_n]bool{}
	for v in 0..n{if sources&(u16(1)<<v)!=0{status[v]=1;rf[v]=true};if protectors&(u16(1)<<v)!=0{status[v]=2;pf[v]=true}}
	for _ in 0..n{
		mut rp:=[max_n]bool{};mut pp:=[max_n]bool{}
		for e in 0..m{u:=eu[e];v:=ev[e];if status[v]!=0{continue};if pf[u]{pp[v]=true};if rf[u]&&(masks[e]&(1<<world))!=0{rp[v]=true}}
		mut nr:=[max_n]bool{};mut np:=[max_n]bool{};mut changed:=false
		for v in 0..n{if status[v]!=0{continue};if pp[v]{status[v]=2;np[v]=true;changed=true}else if rp[v]{status[v]=1;nr[v]=true;changed=true}}
		rf=nr;pf=np;if !changed{break}
	}
	mut count:=0;for v in 0..n{if status[v]==1{count++}};return count
}

@[export:'rumor_blocking_greedy_live_edge']
pub fn rumor_blocking_greedy_live_edge(input &i64,length usize,mut output &u8,capacity usize)i64{
	if input==nil||length<5||length>61{return -1};n0:=unsafe{input[0]};m0:=unsafe{input[1]};r0:=unsafe{input[2]};k0:=unsafe{input[3]};w0:=unsafe{input[4]}
	if n0<2||n0>8||m0<0||m0>16||r0<1||r0>=n0||k0<1||k0>3||w0<1||w0>8||k0>n0-r0||length!=usize(5+r0+3*m0){return -1}
	n:=int(n0);m:=int(m0);r:=int(r0);k:=int(k0);worlds:=int(w0);mut sources:=u16(0)
	for i in 0..r{v:=unsafe{input[5+i]};if v<0||v>=n0{return -1};bit:=u16(1)<<int(v);if sources&bit!=0{return -1};sources|=bit}
	mut eu:=[max_m]int{};mut ev:=[max_m]int{};mut masks:=[max_m]int{};mut seen:=[max_n*max_n]bool{};at:=5+r;allowed:=(1<<worlds)-1
	for e in 0..m{u:=unsafe{input[at+3*e]};v:=unsafe{input[at+3*e+1]};mask:=unsafe{input[at+3*e+2]};if u<0||u>=n0||v<0||v>=n0||u==v||mask<0||mask>i64(allowed){return -1};key:=int(u)*max_n+int(v);if seen[key]{return -1};seen[key]=true;eu[e]=int(u);ev[e]=int(v);masks[e]=int(mask)}
	mut baseline:=[max_worlds]int{};for w in 0..worlds{baseline[w]=infected_count(n,m,w,sources,0,eu,ev,masks)}
	mut selected:=u16(0);mut chosen:=[max_n]int{};mut scores:=[max_n]int{}
	for round in 0..k{mut current:=[max_worlds]int{};for w in 0..worlds{current[w]=baseline[w]-infected_count(n,m,w,sources,selected,eu,ev,masks)};mut best:=-1;mut best_score:=-1
		for candidate in 0..n{bit:=u16(1)<<candidate;if sources&bit!=0||selected&bit!=0{continue};mut score:=0;for w in 0..worlds{score+=baseline[w]-infected_count(n,m,w,sources,selected|bit,eu,ev,masks)-current[w]};if score>best_score{best=candidate;best_score=score}}
		if best<0{return -1};selected|=u16(1)<<best;chosen[round]=best;scores[round]=best_score
	}
	bytes:=(1+2*k)*8;if output==nil||capacity<usize(bytes){return -2};put_i64_le(mut output,0,i64(k));for i in 0..k{put_i64_le(mut output,1+2*i,i64(chosen[i]));put_i64_le(mut output,2+2*i,i64(scores[i]))};return i64(bytes)
}
