module simpath_st_paths_zdd;

const int MAX_N=8, MAX_M=9, MAX_STATES=1023, MAX_ZDD=511, MAX_INPUT=23, RADIX=2048;
struct Edge { int u; int v; }
struct Memo { int level; long[MAX_N] mate; int result; }
struct ZNode { int level; int low; int high; }
struct Context {
    int n; int m; int source; int target; int memo_count; int node_count;
    Edge[MAX_M] edges; int[MAX_N] last; Memo[MAX_STATES] memo; ZNode[MAX_ZDD] nodes;
}

fn int degree_of(long* mate,int vertex){if(mate[vertex]==vertex+1)return 0;if(mate[vertex]==0)return 2;return 1;}

/* 0=pruned, 1=suffix state, 2=one-terminal. */
fn int transition(Context* c,int level,long* mate,int selected,long* next){
    for(int i=0;i<c.n;i++)next[i]=mate[i];
    if(selected!=0){
        int u=c.edges[level].u,v=c.edges[level].v,du=degree_of(&next[0],u),dv=degree_of(&next[0],v);
        if(du==2||dv==2)return 0;
        if((u==c.source||u==c.target)&&du==1)return 0;
        if((v==c.source||v==c.target)&&dv==1)return 0;
        long mu=next[u],mv=next[v];
        if(mu==v+1&&mv==u+1)return 0;
        if((mu==c.source+1&&mv==c.target+1)||(mu==c.target+1&&mv==c.source+1)){
            for(int w=0;w<c.n;w++)if(w!=c.source&&w!=c.target&&w!=u&&w!=v&&degree_of(&next[0],w)==1)return 0;
            return 2;
        }
        next[u]=0;next[v]=0;next[(usz)(mu-1)]=mv;next[(usz)(mv-1)]=mu;
    }
    for(int w=0;w<c.n;w++)if(c.last[w]==level){
        int degree=degree_of(&next[0],w);
        if(w==c.source||w==c.target){if(degree==0)return 0;}
        else{if(degree==1)return 0;next[w]=w+1;}
    }
    return 1;
}

fn int make_node(Context* c,int level,int low,int high){
    if(high==0)return low;
    for(int i=0;i<c.node_count;i++)if(c.nodes[i].level==level&&c.nodes[i].low==low&&c.nodes[i].high==high)return i+2;
    if(c.node_count>=MAX_ZDD)return -1;
    c.nodes[c.node_count]=ZNode{level,low,high};c.node_count++;return c.node_count+1;
}

fn int memo_find(Context* c,int level,long* mate){
    for(int i=0;i<c.memo_count;i++)if(c.memo[i].level==level){bool equal=true;for(int v=0;v<c.n;v++)if(c.memo[i].mate[v]!=mate[v]){equal=false;break;}if(equal)return c.memo[i].result;}
    return -1;
}

fn int solve(Context* c,int level,long* mate){
    if(level==c.m)return 0;
    int cached=memo_find(c,level,mate);if(cached>=0)return cached;
    long[MAX_N] next={};int low=transition(c,level,mate,0,&next[0])!=0?solve(c,level+1,&next[0]):0;
    int status=transition(c,level,mate,1,&next[0]);int high=status==0?0:(status==2?1:solve(c,level+1,&next[0]));
    int result=make_node(c,level,low,high);if(result<0||c.memo_count>=MAX_STATES)return -1;
    c.memo[c.memo_count].level=level;c.memo[c.memo_count].result=result;for(int v=0;v<c.n;v++)c.memo[c.memo_count].mate[v]=mate[v];c.memo_count++;
    return result;
}

fn int reachable_nodes(Context* c,int root){
    bool[MAX_ZDD+2] seen={};int[2*MAX_ZDD+3] stack={};int top=0,count=0;stack[top++]=root;
    while(top>0){int id=stack[--top];if(id<=1||seen[id])continue;seen[id]=true;count++;ZNode node=c.nodes[id-2];stack[top++]=node.low;stack[top++]=node.high;}
    return count;
}

fn long simpath_st_paths_zdd(long* input,usz length) @export("simpath_st_paths_zdd"){
    if(input==null||length<4||length>MAX_INPUT)return -1;
    long n64=input[0],m64=input[1],s64=input[2],t64=input[3];
    if(n64<2||n64>MAX_N||m64<0||m64>MAX_M||s64<0||s64>=n64||t64<0||t64>=n64||s64==t64||length!=(usz)(4+2*m64))return -1;
    Context c={};c.n=(int)n64;c.m=(int)m64;c.source=(int)s64;c.target=(int)t64;
    for(int v=0;v<c.n;v++)c.last[v]=-1;
    for(int i=0;i<c.m;i++){
        long u=input[4+2*i],v=input[5+2*i];if(u<0||u>=v||v>=n64)return -1;
        for(int j=0;j<i;j++)if(c.edges[j].u==(int)u&&c.edges[j].v==(int)v)return -1;
        usz ui=(usz)u,vi=(usz)v;
        c.edges[i]=Edge{(int)u,(int)v};c.last[ui]=i;c.last[vi]=i;
    }
    long[MAX_N] initial={};for(int v=0;v<c.n;v++)initial[v]=v+1;
    int root=solve(&c,0,&initial[0]);if(root<0)return -1;
    int[MAX_ZDD+2] ways={};ways[1]=1;
    for(int id=2;id<c.node_count+2;id++){ZNode node=c.nodes[id-2];ways[id]=ways[node.low]+ways[node.high];}
    int zdd_count=reachable_nodes(&c,root),path_count=ways[root];if(path_count>=RADIX)return -1;
    return (long)zdd_count*RADIX+path_count;
}
