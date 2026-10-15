module all_paths_from_source_to_target;
const MAX_V = 8; const MAX_E = 24; const MAX_P = 1000; const MAX_OUT = 72008;
fn void put_i64(char* out, usz at, long value) { ulong bits=(ulong)value; for(usz b=0;b<8;b++){out[at+b]=(char)(bits&255);bits>>=8;} }
fn void dfs(long* adj,long* degree,bool* visited,long* path,usz depth,long target,long* count,char* out,usz* at,bool* overflow) {
    if(overflow[0])return;
    long u=path[depth-1];
    if(u==target){if(count[0]>=MAX_P){overflow[0]=true;return;}put_i64(out,at[0],(long)depth);at[0]+=8;for(usz i=0;i<depth;i++){put_i64(out,at[0],path[i]);at[0]+=8;}count[0]++;return;}
    visited[u]=true;
    for(usz i=0;i<(usz)degree[u]&&!overflow[0];i++){long v=adj[u*MAX_E+i];if(!visited[v]){path[depth]=v;dfs(adj,degree,visited,path,depth+1,target,count,out,at,overflow);}}
    visited[u]=false;
}
fn long all_paths_from_source_to_target(long* v,usz n,char* output,usz capacity) @export("all_paths_from_source_to_target") {
    if(v==null||n<4||n>52||v[0]<1||v[0]>MAX_V||v[1]<0||v[1]>MAX_E)return -1;
    long nv=v[0],ne=v[1];if(v[2]<0||v[2]>=nv||v[3]<0||v[3]>=nv||n!=4+2*(usz)ne)return -1;
    long adj[MAX_V*MAX_E]={},degree[MAX_V]={};for(usz e=0;e<(usz)ne;e++){long a=v[4+2*e],b=v[5+2*e];if(a<0||a>=nv||b<0||b>=nv)return -1;adj[a*MAX_E+degree[a]++]=b;}
    char temp[MAX_OUT]={};bool visited[MAX_V]={};long path[MAX_V]={};path[0]=v[2];long count=0;usz at=8;bool overflow=false;
    dfs(adj,degree,visited,path,1,v[3],&count,temp,&at,&overflow);if(overflow)return -2;put_i64(temp,0,count);if(output==null||capacity<at)return -2;for(usz i=0;i<at;i++)output[i]=temp[i];return (long)at;
}
