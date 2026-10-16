module euler;
fn long euler(long *v, usz n) @export("euler") {
    if (v == null || n < 4 || n > 516 || v[0] < 1 || v[0] > 32 || v[1] < 0 || v[1] >= v[0] || v[2] < 0 || v[2] >= v[0] || v[3] < 0 || v[3] > 256 || n != (usz)(4 + 2 * v[3])) return -2;
    usz count=(usz)v[0], s=(usz)v[1], t=(usz)v[2], m=(usz)v[3]; ulong[32] adj; int[32] degree;
    for(usz i=0;i<32;i++){adj[i]=0ul;degree[i]=0;}
    for(usz i=0;i<m;i++){long x=v[4+2*i],y=v[5+2*i];if(x<0||y<0||x>=v[0]||y>=v[0]||x==y)return -2;ulong bx=1ul<<(usz)x,by=1ul<<(usz)y;if((adj[(usz)x]&by)!=0)return -2;adj[(usz)x]|=by;adj[(usz)y]|=bx;degree[(usz)x]++;degree[(usz)y]++;}
    bool active=false;for(usz i=0;i<count;i++)if(degree[i]>0)active=true;
    if(active){usz start=0;while(degree[start]==0)start++;usz[32] q;usz head=0,tail=0;q[tail++]=start;ulong seen=1ul<<start;while(head<tail){usz u=q[head++];for(usz w=0;w<count;w++)if(((adj[u]>>w)&1ul)!=0&&((seen>>w)&1ul)==0){seen|=1ul<<w;q[tail++]=w;}}for(usz i=0;i<count;i++)if(degree[i]>0&&((seen>>i)&1ul)==0)return -2;}
    int odd=0;for(usz i=0;i<count;i++){bool want=s==t?false:(i==s||i==t);bool is_odd=(degree[i]%2)!=0;if(is_odd!=want)return 0;if(is_odd)odd++;}return odd==(s==t?0:2)?1:0;
}
