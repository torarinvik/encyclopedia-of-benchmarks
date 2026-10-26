package exact_graph_coloring_inclusion_exclusion

import "core:c"

// Exact chromatic number through independent-set inclusion-exclusion.
@(export)
exact_graph_coloring_inclusion_exclusion :: proc "c" (x:[^]i64,length:c.size_t,out:[^]u8,cap:c.size_t)->i64{
    if x==nil do return -2
    if length<2||length>44 do return -1
    nv,mv:=x[0],x[1]
    if nv<1||nv>7||mv<0||mv>21||int(length)!=2+2*int(mv) do return -1
    n,m:=int(nv),int(mv);adj:[7][7]bool
    for e:=0;e<m;e+=1{u,v:=x[2+2*e],x[3+2*e];if u<0||v<0||u>=nv||v>=nv||u==v do return -1;a,b:=int(u),int(v);if adj[a][b] do return -1;adj[a][b],adj[b][a]=true,true}
    cnt:[128]i64;cnt[0]=1;lim:=1<<n
    for mask:=1;mask<lim;mask+=1{bit:=mask & -mask;v:=0;for (1<<v)!=bit{v+=1};rest:=mask^bit;allowed:=rest;for u:=0;u<n;u+=1{if adj[v][u]{allowed &= ~(1<<u)}};cnt[mask]=cnt[rest]+cnt[allowed]}
    chi:=i64(n)
    for k:=1;k<=n;k+=1{sum:=i64(0);for mask:=0;mask<lim;mask+=1{term:=i64(1);base:=cnt[mask]-1;for q:=0;q<k;q+=1{term*=base};pc:=0;for bits:=mask;bits!=0;bits &= bits-1{pc+=1};if (n-pc)%2==0{sum+=term}else{sum-=term}};if sum>0{chi=i64(k);break}}
    if cap<8||out==nil do return -2
    value:=u64(chi);for i:=0;i<8;i+=1{out[i]=u8((value>>(8*i))&255)}
    return 8
}
