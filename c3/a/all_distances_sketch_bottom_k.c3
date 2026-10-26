module all_distances_sketch_bottom_k;
fn void put_i64(uint8* out, usz offset, long x){ulong b=(ulong)x;for(usz i=0;i<8;i++)out[offset+i]=(uint8)(b>>(8*i));}
fn long all_distances_sketch_bottom_k(long* input, usz length, uint8* output, usz capacity) @export("all_distances_sketch_bottom_k") {
    if(input==null||length<6||length>104)return -1;long n0=input[0],m0=input[1],k0=input[2],s0=input[3];
    if(n0<2||n0>10||m0<0||m0>n0*(n0-1)||k0<1||k0>n0||s0<0||s0>=n0||length!=(usz)(4+n0+2*m0))return -1;
    usz n=(usz)n0,m=(usz)m0,k=(usz)k0,source=(usz)s0;long[10] rank=zeroed;bool[10] used=zeroed;
    for(usz i=0;i<n;i++){long r=input[4+i];if(r<0||r>=n0||used[(usz)r])return -1;used[(usz)r]=true;rank[i]=r;}
    bool[10][10] adj=zeroed;for(usz e=0;e<m;e++){long u0=input[4+n+2*e],v0=input[5+n+2*e];if(u0<0||u0>=n0||v0<0||v0>=n0||u0==v0)return -1;usz u=(usz)u0,v=(usz)v0;if(adj[u][v])return -1;adj[u][v]=true;}
    long[10] dist;for(usz i=0;i<n;i++)dist[i]=-1;usz[10] queue=zeroed,head=0,tail=0;dist[source]=0;queue[tail++]=source;
    while(head<tail){usz u=queue[head++];for(usz v=0;v<n;v++)if(adj[u][v]&&dist[v]<0){dist[v]=dist[u]+1;queue[tail++]=v;}}
    long[21] staged=zeroed;usz count=0;for(usz d=0;d<n;d++)for(usz v=0;v<n;v++)if(dist[v]==(long)d){usz less=0;for(usz x=0;x<n;x++)if(dist[x]>=0&&(dist[x]<dist[v]||(dist[x]==dist[v]&&x<=v))&&rank[x]<rank[v])less++;if(less<k){staged[1+2*count]=(long)v;staged[2+2*count]=dist[v];count++;}}
    staged[0]=(long)count;usz words=1+2*count,bytes=8*words;if(output==null||capacity<bytes)return -2;for(usz i=0;i<words;i++)put_i64(output,8*i,staged[i]);return (long)bytes;
}
