module minimal_dominating_sets_permutation_graphs;

const int MAX_N = 8;
const usz MAX_PARSEABLE_LENGTH = 10;
const usz MAX_STATES = 59049;

struct Context {
    int n;
    int[MAX_N] top;
    int[MAX_N] top_vertex;
    bool[MAX_N][MAX_N] adj;
    long[MAX_STATES] ways;
}

fn int graph_case(Context* c, int i, int j, int k) {
    int a=c.top[i], b=c.top[j], d=c.top[k];
    if(a<b&&b<d)return 1;
    if(a<d&&d<b)return 2;
    if(b<a&&a<d)return 3;
    if(b<d&&d<a)return 4;
    if(d<a&&a<b)return 5;
    return 0;
}

fn bool dominated(Context* c, int y, int* selected, int count) {
    for(int z=0;z<count;z++)if(c.adj[selected[z]][y])return true;
    return false;
}

fn bool irredundant(Context* c, int* selected, int count) {
    for(int x=0;x<count;x++){
        bool found=false;
        for(int y=0;y<c.n&&!found;y++){
            if(!c.adj[selected[x]][y])continue;
            bool shared=false;
            for(int z=0;z<count;z++)if(z!=x&&c.adj[selected[z]][y]){shared=true;break;}
            if(!shared)found=true;
        }
        if(!found)return false;
    }
    return true;
}

fn int private_min_rank(Context* c, int x, int* selected, int count) {
    int best=-1;
    for(int y=0;y<c.n;y++){
        if(!c.adj[x][y])continue;
        bool shared=false;
        for(int z=0;z<count;z++)if(selected[z]!=x&&c.adj[selected[z]][y]){shared=true;break;}
        if(!shared&&(best<0||c.top[y]<c.top[best]))best=y;
    }
    return best;
}

fn bool initial(Context* c,int i,int j,int k,int r,int s){
    int[3] tri={i,j,k};
    if(r!=c.n||!irredundant(c,&tri[0],3))return false;
    int kind=graph_case(c,i,j,k);
    if(kind==1){for(int y=0;y<c.n;y++)if(y<i&&c.top[y]<c.top[i])return false;return s==private_min_rank(c,i,&tri[0],3);}
    if(kind==2){if(s!=c.n)return false;for(int y=0;y<c.n;y++)if(c.top[y]<c.top[k]&&y<j&&!dominated(c,y,&tri[0],3))return false;return true;}
    if(kind==3){for(int y=0;y<c.n;y++)if(c.top[y]<c.top[j]&&y<i)return false;return s==private_min_rank(c,j,&tri[0],3);}
    if(kind==4){if(s!=c.n)return false;for(int y=0;y<c.n;y++)if(c.top[y]<c.top[j]&&y<i&&!dominated(c,y,&tri[0],3))return false;return true;}
    if(kind==5){for(int y=0;y<c.n;y++)if(c.top[y]<c.top[k]&&y<i)return false;return s==private_min_rank(c,k,&tri[0],3);}
    return false;
}

fn bool regular(Context* c,int i,int j,int k,int r,int s){
    int[3] tri={i,j,k};
    if(!irredundant(c,&tri[0],3))return false;
    int kind=graph_case(c,i,j,k);
    if(kind>=1&&kind<=4){if(r<0||r>=i)return false;}else if(kind==5){if(r!=c.n)return false;}else return false;
    if(kind==2||kind==4)return s==c.n;
    if(s<0||s>=c.n)return false;
    if(kind==1)return c.adj[i][s]&&!c.adj[r][s]&&!c.adj[j][s]&&!c.adj[k][s];
    if(kind==3)return c.adj[j][s]&&!c.adj[r][s]&&!c.adj[i][s]&&!c.adj[k][s];
    return c.adj[k][s]&&!c.adj[i][s]&&!c.adj[j][s];
}

fn bool final_state(Context* c,int i,int j,int k,int r){
    int[4] selected;int count=0;if(r!=c.n){selected[count]=r;count++;}selected[count]=i;count++;selected[count]=j;count++;selected[count]=k;count++;
    for(int y=0;y<c.n;y++)if(i<y&&c.top[i]<c.top[y]&&!dominated(c,y,&selected[0],count))return false;
    return true;
}

fn usz state_index(int i,int j,int k,int r,int s,int base){return (((((usz)i*(usz)base+(usz)j)*(usz)base+(usz)k)*(usz)base+(usz)r)*(usz)base+(usz)s);}

fn bool successor(Context* c,int i,int j,int k,int r,int s,int ell,int* out_r,int* out_s){
    int kind=graph_case(c,j,k,ell);if(kind==0)return false;
    int[5] selected;int count=0;if(r!=c.n){selected[count]=r;count++;}selected[count]=i;count++;selected[count]=j;count++;selected[count]=k;count++;selected[count]=ell;count++;
    if(!irredundant(c,&selected[0],count))return false;
    if(s!=c.n&&c.top[ell]<=c.top[s])return false;
    if(!c.adj[j][k])for(int y=0;y<c.n;y++)if(i<y&&y<j&&c.top[i]<c.top[y]&&c.top[y]<c.top[j]&&!dominated(c,y,&selected[0],count))return false;
    if(c.adj[i][k])for(int y=0;y<c.n;y++)if(j<y&&y<k&&c.top[j]<c.top[y]&&c.top[y]<c.top[ell]&&!dominated(c,y,&selected[0],count))return false;
    if(kind==5)*out_r=c.n;else{int max_rank=c.top[i];if(r!=c.n&&c.top[r]>max_rank)max_rank=c.top[r];*out_r=c.top_vertex[max_rank];}
    if(kind==2||kind==4)*out_s=c.n;
    else {
        int old_min=c.top[i];if(c.top[j]<old_min)old_min=c.top[j];if(c.top[k]<old_min)old_min=c.top[k];
        int new_min=c.top[j];if(c.top[k]<new_min)new_min=c.top[k];if(c.top[ell]<new_min)new_min=c.top[ell];
        if(s!=c.n&&old_min==new_min)*out_s=s;
        else{int y=j;if(c.top[k]<c.top[y])y=k;if(c.top[ell]<c.top[y])y=ell;*out_s=private_min_rank(c,y,&selected[0],count);if(*out_s<0)return false;}
    }
    return regular(c,j,k,ell,*out_r,*out_s);
}

fn bool dominates_mask(uint mask,uint* hoods,int n){uint cover=0;for(int x=0;x<n;x++)if(mask&(1u<<x))cover|=hoods[x];return cover==((1u<<n)-1u);}

fn long minimal_dominating_sets_permutation_graphs(long* input,usz length) @export("minimal_dominating_sets_permutation_graphs") {
    if(input==null||length<1||length>MAX_PARSEABLE_LENGTH)return -1;
    if(input[0]<1||input[0]>MAX_N)return -1;
    int n=(int)input[0];if(length!=(usz)n+1)return -1;
    Context c=zeroed;c.n=n;
    for(int x=0;x<n;x++){long rank=input[x+1];if(rank<0||rank>=n)return -1;c.top[x]=(int)rank;for(int y=0;y<x;y++)if(c.top[y]==c.top[x])return -1;c.top_vertex[c.top[x]]=x;c.adj[x][x]=true;}
    for(int x=0;x<n;x++)for(int y=x+1;y<n;y++)c.adj[x][y]=c.adj[y][x]=c.top[x]>c.top[y];
    int base=n+1;long answer=0;
    for(int i=n-3;i>=0;i--)for(int j=i+1;j<n-1;j++)for(int k=j+1;k<n;k++){
        int[3] tri={i,j,k};if(graph_case(&c,i,j,k)==0||!irredundant(&c,&tri[0],3))continue;
        for(int ri=0;ri<=i;ri++){int r=ri==i?n:ri;for(int s=0;s<=n;s++){
            if(!initial(&c,i,j,k,r,s)&&!regular(&c,i,j,k,r,s))continue;
            long paths=final_state(&c,i,j,k,r)?1:0;
            for(int ell=k+1;ell<n;ell++){int nr,ns;if(successor(&c,i,j,k,r,s,ell,&nr,&ns))paths+=c.ways[state_index(j,k,ell,nr,ns,base)];}
            c.ways[state_index(i,j,k,r,s,base)]=paths;if(initial(&c,i,j,k,r,s))answer+=paths;
        }}
    }
    uint[MAX_N] hoods=zeroed;for(int x=0;x<n;x++)for(int y=0;y<n;y++)if(c.adj[x][y])hoods[x]|=1u<<y;
    uint full=(1u<<n)-1u;
    for(uint mask=1;mask<=full;mask++){
        int size=0;for(uint bits=mask;bits;bits>>=1)size+=(int)(bits&1u);
        if(size>2||!dominates_mask(mask,&hoods[0],n))continue;
        bool minimal=true;for(int x=0;x<n;x++)if((mask&(1u<<x))&&dominates_mask(mask^(1u<<x),&hoods[0],n))minimal=false;
        if(minimal)answer++;
    }
    return answer;
}
