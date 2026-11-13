module isap_maxflow;
const usz NMAX=8, MMAX=24, INPUT_MAX=4+3*MMAX+1;
const long FLOW_MAX=2400;

fn long dfs(usz u, usz sink, long amount, usz n, long* residual,
            long* distance, long* gap, usz* current, long* stopped) {
    if(u==sink)return amount;
    while(current[u]<n){usz v=current[u];usz e=u*NMAX+v;
        if(residual[e]>0&&distance[u]==distance[v]+1){long limit=amount<residual[e]?amount:residual[e];long sent=dfs(v,sink,limit,n,residual,distance,gap,current,stopped);
            if(sent>0){residual[e]-=sent;residual[v*NMAX+u]+=sent;return sent;}if(*stopped!=0)return 0;}
        current[u]++;
    }
    long old=distance[u],best=(long)n;
    for(usz v=0;v<n;v++)if(residual[u*NMAX+v]>0&&distance[v]<best)best=distance[v];
    long replacement=best+1<(long)n?best+1:(long)n;
    gap[(usz)old]--;distance[u]=replacement;gap[(usz)replacement]++;current[u]=0;
    if(old<(long)n&&gap[(usz)old]==0)*stopped=1;
    return 0;
}

fn long isap_maxflow_impl(long* input, usz length) {
    if(input==null||length<4||length>INPUT_MAX)return -1;
    long nv=input[0],mv=input[1],sv=input[2],tv=input[3];
    if(nv<2||nv>8||mv<0||mv>24||sv<0||sv>=nv||tv<0||tv>=nv||sv==tv||length!=4+3*(usz)mv)return -1;
    usz n=(usz)nv,s=(usz)sv,t=(usz)tv;
    long[64] residual=zeroed;
    for(usz e=0;e<(usz)mv;e++){long u=input[4+3*e],v=input[5+3*e],c=input[6+3*e];if(u<0||u>=nv||v<0||v>=nv||u==v||c<0||c>100)return -1;residual[(usz)u*NMAX+(usz)v]+=c;}
    long[8] distance=zeroed;long[9] gap=zeroed;usz[8] current=zeroed,queue=zeroed;
    for(usz v=0;v<n;v++)distance[v]=nv;distance[t]=0;usz head=0,tail=1;queue[0]=t;
    while(head<tail){usz v=queue[head++];for(usz p=0;p<n;p++)if(distance[p]==nv&&residual[p*NMAX+v]>0){distance[p]=distance[v]+1;queue[tail++]=p;}}
    if(distance[s]>=nv)return 0;
    for(usz v=0;v<n;v++)gap[(usz)distance[v]]++;
    long flow=0,stopped=0;while(distance[s]<nv&&stopped==0)flow+=dfs(s,t,FLOW_MAX,n,&residual,&distance,&gap,&current,&stopped);
    return flow;
}
fn long isap_maxflow(long* input, usz length) @export("isap_maxflow") { return isap_maxflow_impl(input,length); }
