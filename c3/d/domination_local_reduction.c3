module domination_local_reduction;

fn void put_word(char* out, usz offset, long x) {
    ulong bits=(ulong)x;
    for(usz b=0;b<8;b++) out[offset+b]=(char)(bits>>(8*b));
}

fn long domination_local_reduction(long* input, usz length, char* output, usz capacity) @export("domination_local_reduction") {
    if(input==null||length<3||length>135)return -1;
    long n0=input[0];long m0=input[1];long p0=input[2];
    if(n0<1||n0>12||m0<0||m0>66||p0<0||p0>=n0||length!=(usz)(3+2*m0))return -1;
    usz n=(usz)n0;usz m=(usz)m0;usz p=(usz)p0;
    bool[12][12] adj;
    for(usz e=0;e<m;e++){long u0=input[3+2*e];long v0=input[4+2*e];if(u0<0||v0<=u0||v0>=n0)return -1;usz u=(usz)u0;usz v=(usz)v0;if(adj[u][v])return -1;adj[u][v]=true;adj[v][u]=true;}
    bool[12] closed, exits, guards, prisoners;closed[p]=true;
    for(usz u=0;u<n;u++)if(adj[p][u])closed[u]=true;
    for(usz u=0;u<n;u++)if(adj[p][u])for(usz x=0;x<n;x++)if(adj[u][x]&&!closed[x]){exits[u]=true;break;}
    for(usz u=0;u<n;u++)if(adj[p][u]&&!exits[u])for(usz x=0;x<n;x++)if(exits[x]&&adj[u][x]){guards[u]=true;break;}
    usz np=0;for(usz u=0;u<n;u++)if(adj[p][u]&&!exits[u]&&!guards[u]){prisoners[u]=true;np++;}if(np==0)return -1;
    usz[12] ids;long[12] remap;for(usz u=0;u<n;u++)remap[u]=-1;usz kept=0;
    for(usz u=0;u<n;u++)if(!guards[u]&&!prisoners[u]){ids[kept]=u;remap[u]=(long)kept;kept++;}
    usz k=kept+1;usz leaf=k-1;long[25] words;words[0]=(long)k;
    for(usz i=0;i<kept;i++)words[1+i]=(long)ids[i];words[1+kept]=-1;
    for(usz i=0;i<kept;i++)for(usz j=0;j<kept;j++)if(adj[ids[i]][ids[j]])words[1+k+i]|=(long)(1ul<<j);
    usz rp=(usz)remap[p];words[1+k+rp]|=(long)(1ul<<leaf);words[1+k+leaf]=(long)(1ul<<rp);
    usz count=1+2*k;usz bytes=count*8;if(output==null||capacity<bytes)return -2;
    for(usz i=0;i<count;i++)put_word(output,8*i,words[i]);return (long)bytes;
}
