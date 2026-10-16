module graph_swift_directed_paths;
const int N=32, M=256, Q=64;
struct Path { long length; long[N] nodes; }
fn int dfs(long* adj, int* degree, int at, int dest, long* path, int depth, int* found_length, bool* visited) {
    if (visited[at]) return 0;
    visited[at] = true;
    if(at==dest){*found_length=depth;return 1;}
    for(int i=0;i<degree[at];i++){int next=(int)adj[at*M+i];path[depth]=next;if(dfs(adj,degree,next,dest,path,depth+1,found_length,visited))return 1;}
    return 0;
}
fn Path search(long* adj,int* degree,int mode,int start,int dest){
    Path result;result.length=-1;
    if(mode==0){long[N] path;bool[N] visited;for(int i=0;i<N;i++)visited[i]=false;int found=-1;if(dfs(adj,degree,start,dest,&path[0],0,&found,&visited[0])){result.length=found;for(int i=0;i<found;i++)result.nodes[i]=path[i];}return result;}
    int[N] parent;int[N] queue;for(int i=0;i<N;i++)parent[i]=-1;int head=0,tail=0;parent[start]=start;queue[tail++]=start;
    while(head<tail){int current=queue[head++];if(current==dest)break;for(int i=0;i<degree[current];i++){int next=(int)adj[current*M+i];if(parent[next]==-1){parent[next]=current;queue[tail++]=next;}}}
    if(parent[dest]==-1)return result;int[N] reverse;int count=0,current=dest;while(current!=start){reverse[count++]=current;current=parent[current];}result.length=count;for(int i=0;i<count;i++)result.nodes[i]=reverse[count-1-i];return result;
}
fn void put_i64(char* output,usz position,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)output[position+b]=(char)(bits>>(8*b));}
fn long graph_swift_directed_paths(long* input,usz length,char* output,usz capacity) @export("graph_swift_directed_paths") {
    if(input==null||length<3)return -1;long n=input[0],m=input[1];if(n<1||n>N||m<0||m>M)return -1;usz qp=2+2*(usz)m;if(length<qp+1)return -1;long q=input[qp];if(q<1||q>Q||length!=qp+1+3*(usz)q)return -1;
    long[N*M] adj;int[N] degree;for(int i=0;i<N;i++)degree[i]=0;
    for(usz i=0;i<(usz)m;i++){long u=input[2+2*i],v=input[3+2*i];if(u<0||u>=n||v<=u||v>=n)return -1;adj[(usz)u*M+(usz)degree[u]++]=v;}
    int[Q] modes,starts,dests;for(usz i=0;i<(usz)q;i++){usz p=qp+1+3*i;long mode=input[p],s=input[p+1],d=input[p+2];if(mode<0||mode>1||s<0||s>=n||d<0||d>=n)return -1;modes[i]=(int)mode;starts[i]=(int)s;dests[i]=(int)d;}
    Path[Q] paths;usz words=0;for(usz i=0;i<(usz)q;i++){paths[i]=search(&adj[0],&degree[0],modes[i],starts[i],dests[i]);words+=1+(paths[i].length>0?(usz)paths[i].length:0);}
    usz required=words*8;if(output==null||capacity<required)return -2;usz pos=0;for(usz i=0;i<(usz)q;i++){put_i64(output,pos++*8,paths[i].length);for(long j=0;j<paths[i].length;j++)put_i64(output,pos++*8,paths[i].nodes[j]);}return (long)required;
}
