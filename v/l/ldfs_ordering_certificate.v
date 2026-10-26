// Clean-room Lexicographic Depth-First Search with 4-vertex certificates.
module ldfs_ordering_certificate
const max_n=8;const max_fields=234
fn put(mut out &u8,at int,value i64){mut bits:=u64(value);for b in 0..8{unsafe{out[at+b]=u8(bits&255)};bits>>=8}}
@[export:'ldfs_ordering_certificate']
pub fn ldfs_ordering_certificate(v &i64,n usize,mut out &u8,cap usize)i64{unsafe{
 if v==nil||n<3||n>10||v[0]<1||v[0]>max_n{return -1};count:=int(v[0]);if n!=usize(count+2)||v[1]<0||v[1]>=i64(count){return -1};all:=(u64(1)<<count)-1;mut adj:=[max_n]u64{}
 for i in 0..count{if v[2+i]<0||u64(v[2+i])>all||(u64(v[2+i])&(u64(1)<<i))!=0{return -1};adj[i]=u64(v[2+i])};for i in 0..count{for j in 0..count{if ((adj[i]>>j)&1)!=((adj[j]>>i)&1){return -1}}}
 mut reach:=u64(1)<<int(v[1]);for _ in 0..count{old:=reach;for i in 0..count{if ((reach>>i)&1)!=0{reach|=adj[i]}};if old==reach{break}};if reach!=all{return -1}
 mut order:=[max_n]int{};order[0]=int(v[1]);mut used:=1;mut visited:=u64(1)<<int(v[1]);for used<count{mut chosen:=count;for x in 0..count{if ((visited>>x)&1)==0{mut wins:=chosen==count;if !wins{mut k:=used;for k>0{k--;u:=order[k];xb:=(adj[x]>>u)&1;yb:=(adj[chosen]>>u)&1;if xb!=yb{wins=xb>yb;break};if k==0{wins=x<chosen}}};if wins{chosen=x}}};order[used]=chosen;used++;visited|=u64(1)<<chosen}
 mut fields:=[max_fields]i64{};fields[0]=i64(count);for i in 0..count{fields[1+i]=i64(order[i])};mut certs:=0;mut at:=count+2
 for i in 0..count{for j in i+1..count{for k in j+1..count{a,b,c0:=order[i],order[j],order[k];if ((adj[a]>>c0)&1)!=0&&((adj[a]>>b)&1)==0{mut witness:=-1;for t in i+1..j{d:=order[t];if ((adj[d]>>b)&1)!=0&&((adj[d]>>c0)&1)==0{witness=d;break}};fields[at]=i64(a);fields[at+1]=i64(b);fields[at+2]=i64(c0);fields[at+3]=i64(witness);at+=4;certs++}}}}
 fields[count+1]=i64(certs);bytes:=8*at;if out==nil||cap<usize(bytes){return -2};for i in 0..at{put(mut out,8*i,fields[i])};return i64(bytes)
}}
