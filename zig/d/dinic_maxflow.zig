const MAX_N: usize=16;
const MAX_M: usize=64;
const INF_FLOW: i64=6401;

fn dfs(u:usize,t:usize,pushed:i64,residual:*[MAX_N][MAX_N]i64,level:*[MAX_N]i32,next:*[MAX_N]usize,n:usize)i64{
    if(u==t)return pushed;
    while(next[u]<n){const v=next[u];if(level[v]==level[u]+1 and residual[u][v]>0){const sent=dfs(v,t,@min(pushed,residual[u][v]),residual,level,next,n);if(sent>0){residual[u][v]-=sent;residual[v][u]+=sent;return sent;}}next[u]+=1;}
    return 0;
}

/// Return the maximum flow for a bounded directed graph edge list.
export fn dinic_maxflow(input:[*]const i64,length:usize)i64{
    if(length<4)return -1;const v=input[0..length];const nv=v[0];const mv=v[1];const sv=v[2];const tv=v[3];
    if(nv<2 or nv>16 or mv<0 or mv>64 or sv<1 or sv>nv or tv<1 or tv>nv or sv==tv)return -1;
    const n:usize=@intCast(nv);const m:usize=@intCast(mv);const s:usize=@intCast(sv-1);const t:usize=@intCast(tv-1);if(length!=4+3*m)return -1;
    var residual=[_] [MAX_N]i64{[_]i64{0}**MAX_N}**MAX_N;
    for(0..m)|i|{const u=v[4+3*i];const w=v[5+3*i];const c=v[6+3*i];if(u<1 or u>nv or w<1 or w>nv or u==w or c<0 or c>100)return -1;residual[@intCast(u-1)][@intCast(w-1)]+=c;}
    var flow:i64=0;while(true){var level=[_]i32{-1}**MAX_N;var queue=[_]usize{0}**MAX_N;var head:usize=0;var tail:usize=0;level[s]=0;queue[tail]=s;tail+=1;
        while(head<tail):(head+=1){const u=queue[head];for(0..n)|w|{if(residual[u][w]>0 and level[w]<0){level[w]=level[u]+1;queue[tail]=w;tail+=1;}}}
        if(level[t]<0)break;var next=[_]usize{0}**MAX_N;while(true){const pushed=dfs(s,t,INF_FLOW,&residual,&level,&next,n);if(pushed==0)break;flow+=pushed;}
    }return flow;
}
