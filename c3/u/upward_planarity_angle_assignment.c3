module upward_planarity_angle_assignment;
const usz N=8, M=18, F=12;
fn void put64(u8* out, usz at, long value) { ulong x=(ulong)value; for(usz b=0;b<8;b++){out[at*8+b]=(u8)(x&255);x>>=8;} }
fn bool aug(usz t, usz ns, usz* slots, usz* terms, bool* inc, int* owner, bool* seen, int* assigned) {
    for(usz s=0;s<ns;s++) if(inc[terms[t]*F+slots[s]]&&!seen[s]) { seen[s]=true; int old=owner[s]; if(old<0||aug((usz)old,ns,slots,terms,inc,owner,seen,assigned)){owner[s]=(int)t;assigned[t]=(int)s;return true;} }
    return false;
}
fn bool suffix_match(usz first, usz r, usz f, usz* caps, usz* slots, usz* terms, bool* inc) {
    usz ns=0;int[8] owner,assigned;for(usz i=0;i<8;i++){owner[i]=-1;assigned[i]=-1;}
    for(usz face=0;face<f;face++)for(usz k=0;k<caps[face];k++)slots[ns++]=face;
    for(usz t=first;t<r;t++){bool[8] seen;if(!aug(t,ns,slots,terms,inc,&owner[0],&seen[0],&assigned[0]))return false;}return true;
}
fn long upward_planarity_angle_assignment(long* a, usz len, u8* output, usz capacity) @export("upward_planarity_angle_assignment") {
    if(a==null||len<4||len>124)return -1;
    long nn=a[0], mm=a[1], ff=a[2], oo=a[3];
    if(nn<2||nn>8||mm<1||mm>18||ff<1||ff>12||oo<0||oo>=ff||len!=4+6*(usz)mm+(usz)ff)return -1;
    usz n=(usz)nn,m=(usz)mm,f=(usz)ff,o=(usz)oo;
    usz[18] eu,ev; bool[64] adj,oe; usz[8] indeg;
    for(usz i=0;i<m;i++) { long ul=a[4+2*i],vl=a[5+2*i]; if(ul<0||ul>=nn||vl<0||vl>=nn||ul==vl)return -1; usz u=(usz)ul,v=(usz)vl;
        if(i>0&&(eu[i-1]>u||(eu[i-1]==u&&ev[i-1]>=v)))return -1;
        for(usz j=0;j<i;j++)if((eu[j]==u&&ev[j]==v)||(eu[j]==v&&ev[j]==u))return -1;
        eu[i]=u;ev[i]=v;adj[u*N+v]=true;adj[v*N+u]=true;oe[u*N+v]=true;indeg[v]++;
    }
    usz[12] wl;usz[36] wu,wv;bool[64] dart;usz cursor=4+2*m,total=0;
    for(usz j=0;j<f;j++){long kl=a[cursor++];if(kl<1||kl>2*(long)m||total+(usz)kl>2*m)return -1;wl[j]=(usz)kl;
        for(usz z=0;z<(usz)kl;z++){long ul=a[cursor++],vl=a[cursor++];if(ul<0||ul>=nn||vl<0||vl>=nn)return -1;usz u=(usz)ul,v=(usz)vl;if(!adj[u*N+v]||dart[u*N+v])return -1;dart[u*N+v]=true;wu[total]=u;wv[total++]=v;}}
    if(cursor!=len||total!=2*m||n-m+f!=2)return -1;for(usz i=0;i<m;i++)if(!dart[eu[i]*N+ev[i]]||!dart[ev[i]*N+eu[i]])return -1;
    int[64] succ;int[96] corners;for(usz i=0;i<64;i++)succ[i]=-1;for(usz i=0;i<96;i++)corners[i]=-1;bool[96] inc;int[24] sw;cursor=0;
    for(usz j=0;j<f;j++){usz base=cursor,k=wl[j];for(usz i=0;i<k;i++){usz u=wu[cursor],v=wv[cursor],w=wv[base+(i+1)%k];if(v!=wu[base+(i+1)%k]||succ[v*N+u]>=0)return -1;succ[v*N+u]=(int)w;if(corners[j*N+v]<0)corners[j*N+v]=(int)i;inc[v*F+j]=true;if(oe[v*N+u]&&oe[v*N+w])sw[j*2]++;if(!oe[v*N+u]&&!oe[v*N+w])sw[j*2+1]++;cursor++;}}
    bool[8] seen;usz[8] q;usz h=0,t=0;q[t++]=0;seen[0]=true;while(h<t){usz u=q[h++];for(usz v=0;v<n;v++)if(adj[u*N+v]&&!seen[v]){seen[v]=true;q[t++]=v;}}for(usz v=0;v<n;v++)if(!seen[v])return -1;
    usz[8] deg;h=0;t=0;for(usz v=0;v<n;v++){deg[v]=indeg[v];if(deg[v]==0)q[t++]=v;}usz removed=0;while(h<t){usz u=q[h++];removed++;for(usz v=0;v<n;v++)if(oe[u*N+v]){deg[v]--;if(deg[v]==0)q[t++]=v;}}if(removed!=n)return -1;
    for(usz v=0;v<n;v++){usz d=0;for(usz u=0;u<n;u++)if(adj[v*N+u])d++;if(d>0){usz start=0;for(usz u=0;u<n;u++)if(adj[v*N+u]){if(succ[v*N+u]<0)return -1;start=u;}usz cur=start,count=0,trans=0;do{if(++count>d)return -1;usz next=(usz)succ[v*N+cur];if(oe[v*N+cur]!=oe[v*N+next])trans++;cur=next;}while(cur!=start);if(count!=d||(trans!=0&&trans!=2))return -1;}}
    usz[12] caps;long sum=0;bool feasible=true;for(usz j=0;j<f;j++){if(sw[j*2]!=sw[j*2+1])return -1;long c=sw[j*2]+(j==o?1:-1);if(c<0)feasible=false;else caps[j]=(usz)c;sum+=c;}
    usz[8] terms;usz r=0;for(usz v=0;v<n;v++){usz od=0;for(usz u=0;u<n;u++)if(oe[v*N+u])od++;if(indeg[v]==0||od==0)terms[r++]=v;}if(sum!=(long)r)feasible=false;
    if(output==null||capacity<8*(2+3*r))return -2;usz[8] slots,chosen;for(usz i=0;i<8;i++)chosen[i]=8;bool ok=feasible;for(usz i=0;i<r&&ok;i++){bool found=false;for(usz face=0;face<f;face++)if(inc[terms[i]*F+face]&&caps[face]>0){caps[face]--;if(suffix_match(i+1,r,f,&caps[0],&slots[0],&terms[0],&inc[0])){chosen[i]=face;found=true;break;}caps[face]++;}if(!found)ok=false;}
    long[26] words;words[0]=ok?1:0;words[1]=(long)r;usz z=2;for(usz i=0;i<r;i++){if(ok){usz face=chosen[i];words[z++]=(long)terms[i];words[z++]=(long)face;words[z++]=corners[face*N+terms[i]];}else{words[z++]=-1;words[z++]=-1;words[z++]=-1;}}for(usz i=0;i<z;i++)put64(output,i,words[i]);return (long)(8*z);
}
