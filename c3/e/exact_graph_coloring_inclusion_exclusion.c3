module exact_graph_coloring_inclusion_exclusion;

fn long exact_graph_coloring_inclusion_exclusion(long* x, usz length, char* out, usz cap)
    @export("exact_graph_coloring_inclusion_exclusion")
{
    if(x==null)return -2;if(length<2||length>44)return -1;long nv=x[0],mv=x[1];
    if(nv<1||nv>7||mv<0||mv>21||length!=2+2*(usz)mv)return -1;usz n=(usz)nv,m=(usz)mv;
    bool[7][7] adj=zeroed;
    for(usz e=0;e<m;e++){long uv=x[2+2*e],vv=x[3+2*e];if(uv<0||vv<0||uv>=nv||vv>=nv||uv==vv)return -1;usz u=(usz)uv,v=(usz)vv;if(adj[u][v])return -1;adj[u][v]=true;adj[v][u]=true;}
    long[128] cnt=zeroed;cnt[0]=1;usz lim=1ul<<(ulong)n;
    for(usz mask=1;mask<lim;mask++){usz bit=mask & (0ul-mask);usz v=0;while((1ul<<v)!=bit)v++;usz rest=mask^bit,allowed=rest;for(usz u=0;u<n;u++)if(adj[v][u])allowed &= ~(1ul<<u);cnt[mask]=cnt[rest]+cnt[allowed];}
    long chi=(long)n;for(usz k=1;k<=n;k++){long sum=0;for(usz mask=0;mask<lim;mask++){long term=1,base=cnt[mask]-1;for(usz q=0;q<k;q++)term*=base;usz pc=0;for(usz bits=mask;bits!=0;bits &= bits-1)pc++;sum += ((n-pc)%2==0)?term:-term;}if(sum>0){chi=(long)k;break;}}
    if(cap<8||out==null)return -2;ulong value=(ulong)chi;for(usz i=0;i<8;i++)out[i]=(char)((value>>(8*i))&255ul);return 8;
}
