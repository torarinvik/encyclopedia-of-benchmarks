module color_coding_k_path;

// Subset/endpoint dynamic program for a colorful path of exactly k vertices.
fn long color_coding_k_path(long* values, usz length, char* output, usz output_capacity)
    @export("color_coding_k_path")
{
    if (values == null) return -2;
    if (length < 3 || length > 147) return -1;
    long nv=values[0], mv=values[1], kv=values[2];
    if (nv < 1 || nv > 12 || mv < 0 || mv > 66 || kv < 1 || kv > 6 || kv > nv) return -1;
    usz n=(usz)nv, m=(usz)mv, k=(usz)kv, split=3+(usz)nv;
    if (length != split+2*m) return -1;
    usz[12] colors; ulong[12] adj = zeroed;
    for (usz v=0;v<n;v++) { if(values[3+v]<0||values[3+v]>=kv)return -1; colors[v]=(usz)values[3+v]; }
    for (usz e=0;e<m;e++) {
        long av=values[split+2*e],bv=values[split+2*e+1];
        if(av<0||bv<0||av>=nv||bv>=nv||av==bv)return -1;
        usz a=(usz)av,b=(usz)bv; ulong bit=1ul << (ulong)b;
        if((adj[a]&bit)!=0ul)return -1; adj[a]|=bit; adj[b]|=1ul << (ulong)a;
    }
    bool[64][12] dp = zeroed;
    for(usz v=0;v<n;v++)dp[1ul << (ulong)colors[v]][v]=true;
    usz full=(1ul << (ulong)k)-1; bool found=false;
    for(usz mask=1;mask<=full && !found;mask++) for(usz v=0;v<n;v++) if(dp[mask][v]) {
        if(mask==full){found=true;break;}
        for(usz u=0;u<n;u++) if((adj[v]&(1ul << (ulong)u))!=0ul && (mask&(1ul << (ulong)colors[u]))==0)
            dp[mask | (1ul << (ulong)colors[u])][u]=true;
    }
    if(output_capacity<8 || output==null)return -2;
    output[0]=(char)(found?1:0); for(usz i=1;i<8;i++)output[i]=0;
    return 8;
}
