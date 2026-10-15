module bfs_graph_coloring;

const int MAX_VERTICES = 64;
const int MAX_EDGES = 2016;
const int MAX_OUTPUT_VALUES = 66;
fn void put_i64(char* output, usz offset, long value) { ulong bits=(ulong)value;for(usz b=0;b<8;b++)output[offset+b]=(char)(bits>>(8*b)); }
fn long bfs_graph_coloring(long* input, usz length, char* output, usz capacity) @export("bfs_graph_coloring") {
    if(input==null||length<2)return -1;
    long nv=input[0],mv=input[1];if(nv<0||nv>MAX_VERTICES||mv<0||mv>MAX_EDGES||length!=2+2*(usz)mv)return -1;
    int n=(int)nv,m=(int)mv;bool[MAX_VERTICES*MAX_VERTICES] adjacency;int[MAX_VERTICES] degree;
    for(int i=0;i<MAX_VERTICES*MAX_VERTICES;i++)adjacency[i]=false;
    for(int i=0;i<MAX_VERTICES;i++)degree[i]=0;
    for(int edge=0;edge<m;edge++){
        long uv=input[2+2*edge],vv=input[3+2*edge];if(uv<0||uv>=n||vv<0||vv>=n||uv==vv)return -1;
        int u=(int)uv,v=(int)vv;int a=u*MAX_VERTICES+v,b=v*MAX_VERTICES+u;if(adjacency[a])return -1;adjacency[a]=true;adjacency[b]=true;degree[u]++;degree[v]++;
    }
    bool[MAX_VERTICES] visited;for(int i=0;i<MAX_VERTICES;i++)visited[i]=false;int[MAX_VERTICES] queue;
    for(int start=0;start<n;start++){
        if(visited[start])continue;int head=0,tail=0,high=0;visited[start]=true;queue[tail++]=start;
        while(head<tail){int vertex=queue[head++];if(degree[vertex]>1)high++;for(int nb=0;nb<n;nb++)if(adjacency[vertex*MAX_VERTICES+nb]&&!visited[nb]){visited[nb]=true;queue[tail++]=nb;}}
        if(high>1)return -1;
    }
    long[MAX_VERTICES] colors;for(int i=0;i<n;i++)colors[i]=1;for(int i=0;i<MAX_VERTICES;i++)visited[i]=false;
    for(int start=0;start<n;start++){
        if(visited[start])continue;int head=0,tail=0;visited[start]=true;queue[tail++]=start;
        while(head<tail){int front=queue[head++];for(int nb=0;nb<n;nb++){if(!adjacency[front*MAX_VERTICES+nb])continue;if(colors[nb]==colors[front])colors[nb]++;if(!visited[nb]){visited[nb]=true;queue[tail++]=nb;}}}
    }
    long[MAX_OUTPUT_VALUES] packed;packed[0]=n;long colors_used=0;for(int i=0;i<n;i++){packed[i+1]=colors[i];if(colors[i]>colors_used)colors_used=colors[i];}packed[n+1]=colors_used;
    usz used=(usz)n+2,required=used*8;if(output==null||capacity<required)return -2;for(usz i=0;i<used;i++)put_i64(output,i*8,packed[i]);return (long)required;
}
