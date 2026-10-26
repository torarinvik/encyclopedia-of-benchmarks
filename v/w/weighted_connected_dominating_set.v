// Clean-room exact bounded minimum weighted connected dominating set.
module weighted_connected_dominating_set
const max_n=16
fn put(mut out &u8,at int,x i64){mut bits:=u64(x);for i in 0..8{unsafe{out[at+i]=u8(bits&255)};bits>>=8}}
@[export:'weighted_connected_dominating_set']
pub fn weighted_connected_dominating_set(v &i64,n usize,mut out &u8,cap usize)i64{unsafe{
 if v==nil||n<3||n>33||v[0]<1||v[0]>max_n{return -1};count:=int(v[0]);if n!=usize(1+2*count){return -1};all:=(u64(1)<<count)-1;mut adj:=[max_n]u64{}
 for i in 0..count{mask,weight:=v[1+i],v[1+count+i];if mask<0||u64(mask)>all||(u64(mask)&(u64(1)<<i))!=0||weight<1||weight>1000{return -1};adj[i]=u64(mask)};for i in 0..count{for j in 0..count{if ((adj[i]>>j)&1)!=((adj[j]>>i)&1){return -1}}}
 mut best:=i64(-1);mut best_mask:=u64(0);mut mask:=u64(1);for mask<=all{mut dominated:=mask;mut cost:=i64(0);for i in 0..count{if ((mask>>i)&1)!=0{dominated|=adj[i];cost+=v[1+count+i]}};if dominated==all{mut seen:=mask&(u64(0)-mask);for{old:=seen;for i in 0..count{if ((seen>>i)&1)!=0{seen|=adj[i]&mask}};if old==seen{break}};if seen==mask&&(best<0||cost<best||(cost==best&&mask<best_mask)){best=cost;best_mask=mask}};mask++}
 if out==nil||cap<16{return -2};put(mut out,0,best);put(mut out,8,i64(best_mask));return 16
}}
