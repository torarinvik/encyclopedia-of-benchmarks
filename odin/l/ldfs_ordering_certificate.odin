// Clean-room Lexicographic Depth-First Search with 4-vertex certificates.
package ldfs_ordering_certificate
import "core:c"
const MAX_N :: 8
const MAX_FIELDS :: 234
put :: proc "contextless" (out:[^]u8,at:int,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{out[at+b]=u8(bits&255);bits>>=8}}
@(export)
ldfs_ordering_certificate :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64 {
 if v==nil||n<3||n>10||v[0]<1||v[0]>MAX_N do return -1
 count:=int(v[0]);if n!=c.size_t(count+2)||v[1]<0||v[1]>=i64(count) do return -1
 all:=(u64(1)<<count)-1;adj:[MAX_N]u64
 for i:=0;i<count;i+=1{if v[2+i]<0||u64(v[2+i])>all||(u64(v[2+i])&(u64(1)<<i))!=0 do return -1;adj[i]=u64(v[2+i])}
 for i:=0;i<count;i+=1{for j:=0;j<count;j+=1{if ((adj[i]>>j)&1)!=((adj[j]>>i)&1) do return -1}}
 reach:=u64(1)<<int(v[1]);for pass:=0;pass<count;pass+=1{old:=reach;for i:=0;i<count;i+=1{if ((reach>>i)&1)!=0{reach|=adj[i]}};if old==reach{break}};if reach!=all do return -1
 order:[MAX_N]int;order[0]=int(v[1]);used:=1;visited:=u64(1)<<int(v[1])
 for used<count{chosen:=count;for x:=0;x<count;x+=1{if ((visited>>x)&1)==0{wins:=chosen==count;if !wins{for k:=used;k>0;k-=1{u:=order[k-1];xb:=(adj[x]>>u)&1;yb:=(adj[chosen]>>u)&1;if xb!=yb{wins=xb>yb;break};if k==1{wins=x<chosen}}};if wins{chosen=x}}};order[used]=chosen;used+=1;visited|=u64(1)<<chosen}
 fields:[MAX_FIELDS]i64;fields[0]=i64(count);for i:=0;i<count;i+=1{fields[1+i]=i64(order[i])};certs:=0;at:=count+2
 for i:=0;i<count;i+=1{for j:=i+1;j<count;j+=1{for k:=j+1;k<count;k+=1{a,b,c0:=order[i],order[j],order[k];if ((adj[a]>>c0)&1)!=0&&((adj[a]>>b)&1)==0{witness:=-1;for t:=i+1;t<j;t+=1{d:=order[t];if ((adj[d]>>b)&1)!=0&&((adj[d]>>c0)&1)==0{witness=d;break}};fields[at]=i64(a);fields[at+1]=i64(b);fields[at+2]=i64(c0);fields[at+3]=i64(witness);at+=4;certs+=1}}}}
 fields[count+1]=i64(certs);bytes:=8*at;if out==nil||cap<c.size_t(bytes) do return -2;for i:=0;i<at;i+=1{put(&out[0],8*i,fields[i])};return i64(bytes)
}
