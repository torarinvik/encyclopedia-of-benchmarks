module truthful_multicast_pmst_tree;

const int MAX_N = 8;
const int MAX_M = 28;
const int MAX_INPUT = 95;
const int MAX_OUTPUT = 176;
fn void put_i64(char* o, usz at, long x) { ulong b=(ulong)x; for(usz i=0;i<8;i++){o[at+i]=(char)(b&255);b>>=8;} }
fn int find_root(int* p,int x){while(p[x]!=x){p[x]=p[p[x]];x=p[x];}return x;}

fn long truthful_multicast_pmst_tree(long* a,usz n,char* out,usz cap) @export("truthful_multicast_pmst_tree") {
    if(a==null||n<4||n>(usz)MAX_INPUT||a[0]<2||a[0]>MAX_N||a[1]<a[0]-1||a[1]>MAX_M||a[2]<0||a[2]>=a[0]||a[3]<1||a[3]>=a[0])return -1;
    int nv=(int)a[0],m=(int)a[1],source=(int)a[2],r=(int)a[3];if(n!=(usz)(4+3*m+r))return -1;
    int[MAX_M] eu;int[MAX_M] ev;int[MAX_M] ew;int[MAX_M] order;int pu=-1,pv=-1;
    for(int i=0;i<m;i++){long u=a[4+3*i],v=a[5+3*i],w=a[6+3*i];if(u<0||v<=u||v>=nv||w<1||w>100||(i>0&&(u<pu||(u==pu&&v<=pv))))return -1;eu[i]=(int)u;ev[i]=(int)v;ew[i]=(int)w;order[i]=i;pu=(int)u;pv=(int)v;}
    int[MAX_N] receivers;int last=-1;for(int i=0;i<r;i++){long x=a[4+3*m+i];if(x<0||x>=nv||x==source||(i>0&&x<=last))return -1;receivers[i]=(int)x;last=(int)x;}
    for(int i=1;i<m;i++){int key=order[i],j=i;while(j>0){int q=order[j-1];if(ew[q]<ew[key]||(ew[q]==ew[key]&&(eu[q]<eu[key]||(eu[q]==eu[key]&&ev[q]<ev[key]))))break;order[j]=q;j-=1;}order[j]=key;}
    int[MAX_N] dsu;for(int i=0;i<nv;i++)dsu[i]=i;int[MAX_N-1] tu;int[MAX_N-1] tv;int[MAX_N-1] tw;int te=0;
    for(int z=0;z<m&&te<nv-1;z++){int e=order[z],x=find_root(&dsu[0],eu[e]),y=find_root(&dsu[0],ev[e]);if(x!=y){dsu[x]=y;tu[te]=eu[e];tv[te]=ev[e];tw[te]=ew[e];te+=1;}}
    if(te!=nv-1)return -1;
    int[MAX_N][MAX_N] edge_at;for(int i=0;i<nv;i++)for(int j=0;j<nv;j++)edge_at[i][j]=-1;for(int e=0;e<te;e++){edge_at[tu[e]][tv[e]]=e;edge_at[tv[e]][tu[e]]=e;}
    int[MAX_N] parent;int[MAX_N] parent_edge;int[MAX_N] stack;for(int i=0;i<nv;i++){parent[i]=-1;parent_edge[i]=-1;}parent[source]=source;int top=0;stack[top]=source;top+=1;
    while(top>0){top-=1;int u=stack[top];for(int v=0;v<nv;v++)if(edge_at[u][v]>=0&&parent[v]<0){parent[v]=u;parent_edge[v]=edge_at[u][v];stack[top]=v;top+=1;}}
    int[MAX_N-1] keep;for(int e=0;e<te;e++)keep[e]=0;for(int i=0;i<r;i++){int v=receivers[i];while(v!=source){if(parent[v]<0)return -1;keep[parent_edge[v]]=1;v=parent[v];}}
    int[MAX_N-1] selected;int count=0;for(int e=0;e<te;e++)if(keep[e]!=0){selected[count]=e;count+=1;}
    for(int i=1;i<count;i++){int key=selected[i],j=i;while(j>0&&(tu[selected[j-1]]>tu[key]||(tu[selected[j-1]]==tu[key]&&tv[selected[j-1]]>tv[key]))){selected[j]=selected[j-1];j-=1;}selected[j]=key;}
    usz bytes=8*(usz)(1+3*count);if(out==null||cap<bytes)return -2;char[MAX_OUTPUT] staged=zeroed;put_i64(&staged[0],0,(long)count);for(int i=0;i<count;i++){int e=selected[i];put_i64(&staged[0],(usz)(8*(1+3*i)),(long)tu[e]);put_i64(&staged[0],(usz)(8*(2+3*i)),(long)tv[e]);put_i64(&staged[0],(usz)(8*(3+3*i)),(long)tw[e]);}for(usz i=0;i<bytes;i++)out[i]=staged[i];return (long)bytes;
}
