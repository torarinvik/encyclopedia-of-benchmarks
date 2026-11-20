#include <stddef.h>
#include <stdint.h>

enum { MAX_N=8, MAX_M=9, MAX_STATES=1023, MAX_ZDD=511, MAX_INPUT=23, RADIX=2048 };
typedef struct { int u,v; } Edge;
typedef struct { int level; uint8_t mate[MAX_N]; int result; } Memo;
typedef struct { int level,low,high; } ZNode;
typedef struct {
    int n,m,source,target,memo_count,node_count;
    Edge edges[MAX_M]; int last[MAX_N];
    Memo memo[MAX_STATES]; ZNode nodes[MAX_ZDD];
} Context;

static int degree_of(const uint8_t mate[MAX_N],int v){
    if(mate[v]==v+1)return 0;
    if(mate[v]==0)return 2;
    return 1;
}

/* 0 means pruned, 1 means a suffix state, 2 means the one-terminal. */
static int transition(const Context *c,int level,const uint8_t mate[MAX_N],int select,
                      uint8_t next[MAX_N]){
    for(int i=0;i<c->n;i++)next[i]=mate[i];
    if(select){
        const int u=c->edges[level].u,v=c->edges[level].v;
        const int du=degree_of(next,u),dv=degree_of(next,v);
        if(du==2||dv==2)return 0;
        if((u==c->source||u==c->target)&&du==1)return 0;
        if((v==c->source||v==c->target)&&dv==1)return 0;
        const int mu=next[u],mv=next[v];
        if(mu==v+1&&mv==u+1)return 0;
        if((mu==c->source+1&&mv==c->target+1)||
           (mu==c->target+1&&mv==c->source+1)){
            for(int w=0;w<c->n;w++)
                if(w!=c->source&&w!=c->target&&w!=u&&w!=v&&degree_of(next,w)==1)return 0;
            return 2;
        }
        next[u]=0; next[v]=0;
        next[mu-1]=(uint8_t)mv; next[mv-1]=(uint8_t)mu;
    }
    for(int w=0;w<c->n;w++)if(c->last[w]==level){
        const int degree=degree_of(next,w);
        if(w==c->source||w==c->target){if(degree==0)return 0;}
        else{
            if(degree==1)return 0;
            next[w]=(uint8_t)(w+1);
        }
    }
    return 1;
}

static int make_node(Context *c,int level,int low,int high){
    if(high==0)return low;
    for(int i=0;i<c->node_count;i++)
        if(c->nodes[i].level==level&&c->nodes[i].low==low&&c->nodes[i].high==high)return i+2;
    if(c->node_count>=MAX_ZDD)return -1;
    c->nodes[c->node_count]=(ZNode){level,low,high};
    return c->node_count++ + 2;
}

static int memo_find(const Context *c,int level,const uint8_t mate[MAX_N]){
    for(int i=0;i<c->memo_count;i++){
        const Memo *entry=&c->memo[i];
        if(entry->level!=level)continue;
        int equal=1;for(int v=0;v<c->n;v++)if(entry->mate[v]!=mate[v]){equal=0;break;}
        if(equal)return entry->result;
    }
    return -1;
}

static int solve(Context *c,int level,const uint8_t mate[MAX_N]){
    if(level==c->m)return 0;
    int found=memo_find(c,level,mate);if(found>=0)return found;
    uint8_t next[MAX_N];
    int low=transition(c,level,mate,0,next)?solve(c,level+1,next):0;
    const int high_status=transition(c,level,mate,1,next);
    int high=high_status==0?0:(high_status==2?1:solve(c,level+1,next));
    const int result=make_node(c,level,low,high);
    if(result<0||c->memo_count>=MAX_STATES)return -1;
    Memo *entry=&c->memo[c->memo_count++];entry->level=level;entry->result=result;
    for(int v=0;v<c->n;v++)entry->mate[v]=mate[v];
    return result;
}

static int reachable_nodes(const Context *c,int root){
    uint8_t seen[MAX_ZDD+2]={0};int stack[2*MAX_ZDD+3],top=0,count=0;stack[top++]=root;
    while(top){int id=stack[--top];if(id<=1||seen[id])continue;seen[id]=1;count++;
        const ZNode node=c->nodes[id-2];stack[top++]=node.low;stack[top++]=node.high;
    }
    return count;
}

int64_t simpath_st_paths_zdd(const int64_t *input,size_t length){
    if(input==NULL||length<4||length>MAX_INPUT)return -1;
    const int64_t n64=input[0],m64=input[1],s64=input[2],t64=input[3];
    if(n64<2||n64>MAX_N||m64<0||m64>MAX_M||s64<0||s64>=n64||t64<0||t64>=n64||s64==t64||length!=4+2*(size_t)m64)return -1;
    Context c={0};c.n=(int)n64;c.m=(int)m64;c.source=(int)s64;c.target=(int)t64;
    for(int v=0;v<c.n;v++)c.last[v]=-1;
    for(int i=0;i<c.m;i++){
        const int64_t u=input[4+2*i],v=input[5+2*i];if(u<0||u>=v||v>=n64)return -1;
        for(int j=0;j<i;j++)if(c.edges[j].u==(int)u&&c.edges[j].v==(int)v)return -1;
        c.edges[i]=(Edge){(int)u,(int)v};c.last[u]=c.last[v]=i;
    }
    uint8_t initial[MAX_N]={0};for(int v=0;v<c.n;v++)initial[v]=(uint8_t)(v+1);
    const int root=solve(&c,0,initial);if(root<0)return -1;
    uint16_t ways[MAX_ZDD+2]={0};ways[1]=1;
    for(int id=2;id<c.node_count+2;id++){
        const ZNode node=c.nodes[id-2];ways[id]=(uint16_t)(ways[node.low]+ways[node.high]);
    }
    const int node_count=reachable_nodes(&c,root),path_count=ways[root];
    if(path_count>=RADIX)return -1;
    return (int64_t)node_count*RADIX+path_count;
}
