module dinic_maxflow;
const usz MAX_N=16, MAX_M=64;

fn long dfs(usz u, usz sink, long pushed, long* residual, long* level, usz* next, usz n)
{
    if(u==sink)return pushed;
    while(next[u]<n){usz v=next[u];usz k=u*MAX_N+v;if(level[v]==level[u]+1&&residual[k]>0){long sent=dfs(v,sink,pushed<residual[k]?pushed:residual[k],residual,level,next,n);if(sent>0){residual[k]-=sent;residual[v*MAX_N+u]+=sent;return sent;}}next[u]++;}
    return 0;
}

fn long dinic_maxflow_impl(long* input, usz length)
{
    if(input==null||length<4)return -1;
    long nv=input[0],mv=input[1],sv=input[2],tv=input[3];
    if(nv<2||nv>16||mv<0||mv>64||sv<1||sv>nv||tv<1||tv>nv||sv==tv)return -1;
    usz n=(usz)nv,m=(usz)mv,s=(usz)(sv-1),t=(usz)(tv-1);if(length!=4+3*m)return -1;
    long[256] residual=zeroed;
    for(usz i=0;i<m;i++){long u=input[4+3*i],v=input[5+3*i],c=input[6+3*i];if(u<1||u>nv||v<1||v>nv||u==v||c<0||c>100)return -1;residual[((usz)u-1)*MAX_N+((usz)v-1)]+=c;}
    long flow=0;
    while(true){long[16] level;usz[16] queue;for(usz i=0;i<16;i++)level[i]=-1;usz head=0,tail=0;level[s]=0;queue[tail++]=s;
        while(head<tail){usz u=queue[head++];for(usz v=0;v<n;v++)if(residual[u*MAX_N+v]>0&&level[v]<0){level[v]=level[u]+1;queue[tail++]=v;}}
        if(level[t]<0)break;usz[16] next=zeroed;while(true){long pushed=dfs(s,t,6401,&residual,&level,&next,n);if(pushed==0)break;flow+=pushed;}
    }return flow;
}
fn long dinic_maxflow(long* input, usz length) @export("dinic_maxflow") { return dinic_maxflow_impl(input,length); }
