module kkt_mst_sampling_filter;
const usz MAX_N=12; const usz MAX_M=24; const usz MAX_INPUT=98;

long kkt_mst_sampling_filter(long*in,usz len,char*out,usz cap) @export("kkt_mst_sampling_filter") {
    if(in==null||len<6||len>MAX_INPUT)return -1;
    long n64=in[0],m64=in[1];
    if(n64<2||n64>(long)MAX_N||m64<1||m64>(long)MAX_M||len!=2+4*(usz)m64)return -1;
    usz n=(usz)n64,m=(usz)m64;
    long[MAX_M] eu=zeroed,ev=zeroed,ew=zeroed,es=zeroed;
    for(usz i=0;i<m;i+=1){
        eu[i]=in[2+4*i];ev[i]=in[3+4*i];ew[i]=in[4+4*i];es[i]=in[5+4*i];
        if(eu[i]<0||eu[i]>=ev[i]||ev[i]>=n64||ew[i]<1||ew[i]>1024||(es[i]!=0&&es[i]!=1))return -1;
        for(usz j=0;j<i;j+=1)if((eu[i]==eu[j]&&ev[i]==ev[j])||ew[i]==ew[j])return -1;
    }
    if(out==null||cap<m)return -2;
    long[MAX_M] order=zeroed;for(usz i=0;i<m;i+=1)order[i]=(long)i;
    for(usz i=0;i<m;i+=1){usz best=i;for(usz j=i+1;j<m;j+=1)if(ew[(usz)order[j]]<ew[(usz)order[best]])best=j;long temp=order[i];order[i]=order[best];order[best]=temp;}
    long[MAX_N] parent=zeroed;for(usz i=0;i<n;i+=1)parent[i]=(long)i;
    char[MAX_M] in_forest=zeroed,staged=zeroed;
    for(usz pos=0;pos<m;pos+=1){usz e=(usz)order[pos];if(es[e]==0)continue;usz a=(usz)eu[e],b=(usz)ev[e];while(parent[a]!=(long)a)a=(usz)parent[a];while(parent[b]!=(long)b)b=(usz)parent[b];if(a!=b){parent[b]=(long)a;in_forest[e]=1;}}
    for(usz e=0;e<m;e+=1){
        if(in_forest[e]!=0){staged[e]=1;continue;}
        long[MAX_N] path_max=zeroed,queue=zeroed;char[MAX_N] visited=zeroed;
        for(usz i=0;i<n;i+=1)path_max[i]=-1;
        usz head=0,tail=0,start=(usz)eu[e],target=(usz)ev[e];queue[tail]=(long)start;tail+=1;visited[start]=1;path_max[start]=0;
        while(head<tail&&visited[target]==0){usz current=(usz)queue[head];head+=1;for(usz k=0;k<m;k+=1){if(in_forest[k]==0)continue;long next=-1;if((usz)eu[k]==current)next=ev[k];else if((usz)ev[k]==current)next=eu[k];if(next>=0&&visited[(usz)next]==0){visited[(usz)next]=1;long w=ew[k];path_max[(usz)next]=path_max[current]>w?path_max[current]:w;queue[tail]=(long)next;tail+=1;}}}
        if(visited[target]==0||ew[e]<path_max[target]){staged[e]=1;}else{staged[e]=0;}
    }
    for(usz i=0;i<m;i+=1)out[i]=staged[i];return (long)m;
}
