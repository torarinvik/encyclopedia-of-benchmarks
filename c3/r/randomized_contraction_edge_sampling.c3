module randomized_contraction_edge_sampling;
const usz MAX_N=16; const usz MAX_M=24; const usz MAX_INPUT=74;

fn void put32(char*out,usz p,long x){ulong b=(ulong)x;for(usz j=0;j<4;j+=1){out[p+j]=(char)(b&255);b>>=8;}}

long randomized_contraction_edge_sampling(long*in,usz len,char*out,usz cap) @export("randomized_contraction_edge_sampling") {
    if(in==null||len<5||len>MAX_INPUT)return -1;
    long n64=in[0],m64=in[1];
    if(n64<2||n64>(long)MAX_N||m64<n64-1||m64>(long)MAX_M||len!=2+3*(usz)m64)return -1;
    usz n=(usz)n64,m=(usz)m64;
    long[MAX_M] eu=zeroed,ev=zeroed,bits=zeroed;
    for(usz i=0;i<m;i+=1){eu[i]=in[2+3*i];ev[i]=in[3+3*i];bits[i]=in[4+3*i];if(eu[i]<0||eu[i]>=ev[i]||ev[i]>=n64||(bits[i]!=0&&bits[i]!=1))return -1;for(usz j=0;j<i;j+=1)if(eu[i]==eu[j]&&ev[i]==ev[j])return -1;}
    char[MAX_N] seen=zeroed;long[MAX_N] queue=zeroed;usz head=0,tail=1;queue[0]=0;seen[0]=1;
    while(head<tail){usz current=(usz)queue[head];head+=1;for(usz e=0;e<m;e+=1){long next=-1;if((usz)eu[e]==current)next=ev[e];else if((usz)ev[e]==current)next=eu[e];if(next>=0&&seen[(usz)next]==0){seen[(usz)next]=1;queue[tail]=(long)next;tail+=1;}}}
    if(tail!=n)return -1;
    long[MAX_N] parent=zeroed;for(usz i=0;i<n;i+=1)parent[i]=(long)i;
    for(usz e=0;e<m;e+=1)if(bits[e]!=0){usz a=(usz)eu[e],b=(usz)ev[e];while(parent[a]!=(long)a)a=(usz)parent[a];while(parent[b]!=(long)b)b=(usz)parent[b];if(a!=b)parent[b]=(long)a;}
    long[MAX_N] minimum=zeroed;for(usz i=0;i<n;i+=1)minimum[i]=n64;
    for(usz vertex=0;vertex<n;vertex+=1){usz root=vertex;while(parent[root]!=(long)root)root=(usz)parent[root];if((long)vertex<minimum[root])minimum[root]=(long)vertex;}
    usz bytes=4*n;if(out==null||cap<bytes)return -2;
    char[4*MAX_N] staged=zeroed;
    for(usz vertex=0;vertex<n;vertex+=1){usz root=vertex;while(parent[root]!=(long)root)root=(usz)parent[root];put32(staged,4*vertex,minimum[root]);}
    for(usz i=0;i<bytes;i+=1)out[i]=staged[i];return (long)bytes;
}
