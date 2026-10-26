module exact_graph_coloring_inclusion_exclusion

// Exact chromatic number through independent-set inclusion-exclusion.
@[export: 'exact_graph_coloring_inclusion_exclusion']
pub fn exact_graph_coloring_inclusion_exclusion(x &i64,length usize,out &u8,cap usize)i64{
    unsafe{
        if length<2||length>44{return -1};nv:=x[0];mv:=x[1]
        if nv<1||nv>7||mv<0||mv>21||int(length)!=2+2*int(mv){return -1};n:=int(nv);m:=int(mv)
        mut adj:=[7][7]bool{}
        for e:=0;e<m;e++{u:=x[2+2*e];v:=x[3+2*e];if u<0||v<0||u>=nv||v>=nv||u==v{return -1};a:=int(u);b:=int(v);if adj[a][b]{return -1};adj[a][b]=true;adj[b][a]=true}
        mut cnt:=[128]i64{};cnt[0]=1;lim:=1<<n
        for mask:=1;mask<lim;mask++{bit:=mask&-mask;mut v:=0;for (1<<v)!=bit{v++};rest:=mask^bit;mut allowed:=rest;for u:=0;u<n;u++{if adj[v][u]{allowed &= ~(1<<u)}};cnt[mask]=cnt[rest]+cnt[allowed]}
        mut chi:=i64(n)
        for k:=1;k<=n;k++{mut sum:=i64(0);for mask:=0;mask<lim;mask++{mut term:=i64(1);base:=cnt[mask]-1;for _:=0;_<k;_++{term*=base};mut pc:=0;mut bits:=mask;for bits!=0{bits &= bits-1;pc++};if (n-pc)%2==0{sum+=term}else{sum-=term}};if sum>0{chi=i64(k);break}}
        if cap<8{return -2};value:=u64(chi);for i:=0;i<8;i++{out[i]=u8((value>>(8*i))&255)};return 8
    }
}
