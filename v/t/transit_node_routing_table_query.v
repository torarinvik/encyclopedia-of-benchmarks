module transit_node_routing_table_query

fn put_i64(mut out &u8,word int,value i64){bits:=u64(value);for b in 0..8{unsafe{out[word*8+b]=u8((bits>>u64(8*b))&255)}}}

@[export: 'transit_node_routing_table_query']
pub fn transit_node_routing_table_query(input &i64,length usize,mut output &u8,capacity usize)i64{
	if input==nil||length<11||length>86{return -1}
	unsafe{
		q0:=input[0];source:=input[1];target:=input[2];if q0<1||q0>8||source<0||source>=32||target<0||target>=32||input[3]!=1{return -1};q:=int(q0);mut at:=4
		nf0:=input[at];at++;if nf0<1||nf0>4||nf0>q0||at+2*int(nf0)>int(length){return -1};nf:=int(nf0);mut f:=[8]int{};mut ds:=[8]i64{}
		for i in 0..nf{u:=input[at];d:=input[at+1];at+=2;if u<0||u>=q0||d<0||d>1000000{return -1};for j in 0..i{if f[j]==int(u){return -1}};f[i]=int(u);ds[i]=d}
		if at>=int(length){return -1};nb0:=input[at];at++;if nb0<1||nb0>4||nb0>q0||at+2*int(nb0)>int(length){return -1};nb:=int(nb0);mut b:=[8]int{};mut dt:=[8]i64{}
		for i in 0..nb{v:=input[at];d:=input[at+1];at+=2;if v<0||v>=q0||d<0||d>1000000{return -1};for j in 0..i{if b[j]==int(v){return -1}};b[i]=int(v);dt[i]=d}
		if at+q*q!=int(length){return -1};mut table:=[8][8]i64{};for i in 0..q{for j in 0..q{d:=input[at];at++;if d<0||d>1000000{return -1};table[i][j]=d}}
		for i in 0..q{if table[i][i]!=0{return -1}};mut best:=i64(0x7fffffffffffffff);mut bestu:=0;mut bestv:=0
		for i in 0..nf{for j in 0..nb{d:=ds[i]+table[f[i]][b[j]]+dt[j];if d<best||(d==best&&(f[i]<bestu||(f[i]==bestu&&b[j]<bestv))){best=d;bestu=f[i];bestv=b[j]}}}
		if output==nil||capacity<24{return -2};put_i64(mut output,0,best);put_i64(mut output,1,i64(bestu));put_i64(mut output,2,i64(bestv));return 24
	}
}
