module bidirectional_search;
const usz N=64; const usz MAX_ARCS=N*(N-1);
fn void put(char* out,usz slot,long v){ulong b=(ulong)v;for(usz i=0;i<8;i++)out[slot*8+i]=(char)(b>>(i*8));}
fn long bidirectional_search(long* input,usz length,char* output,usz capacity) @export("bidirectional_search") {
 if(input==null||length<4||input[0]<1||input[0]>(long)N)return -1;usz n=(usz)input[0];if(input[1]<0||input[1]>=(long)n||input[2]<0||input[2]>=(long)n||input[3]<0||input[3]>(long)MAX_ARCS||length!=4+2*(usz)input[3])return -1;usz m=(usz)input[3];int[N][N-1] adj;usz[N] deg;bool[N][N] edge;
 for(usz i=0;i<m;i++){long u=input[4+2*i],v=input[5+2*i];if(u<0||u>=(long)n||v<0||v>=(long)n||u==v||edge[(usz)u][(usz)v])return -1;edge[(usz)u][(usz)v]=true;adj[(usz)u][deg[(usz)u]]=(int)v;deg[(usz)u]++;}for(usz u=0;u<n;u++)for(usz v=0;v<n;v++)if(edge[u][v]!=edge[v][u])return -1;
 int[N] path;usz pc=0;int start=(int)input[1],goal=(int)input[2];if(start==goal)path[pc++]=start;else{int[2][N] parent;for(usz s=0;s<2;s++)for(usz i=0;i<n;i++)parent[s][i]= -2;int[2][N] q;usz[2] head,tail;parent[0][(usz)start]= -1;parent[1][(usz)goal]= -1;q[0][tail[0]++]=start;q[1][tail[1]++]=goal;int meet= -1;while(head[0]<tail[0]&&head[1]<tail[1]&&meet<0){for(usz s=0;s<2&&meet<0;s++){int cur=q[s][head[s]++];for(usz j=0;j<deg[(usz)cur];j++){int v=adj[(usz)cur][j];if(parent[s][(usz)v]!= -2)continue;parent[s][(usz)v]=cur;q[s][tail[s]++]=v;if(parent[1-s][(usz)v]!= -2){meet=v;break;}}}}if(meet>=0){int[N] rev;usz k=0;for(int v=meet;v!= -1;v=parent[0][(usz)v])rev[k++]=v;while(k>0)path[pc++]=rev[--k];for(int v=parent[1][(usz)meet];v!= -1;v=parent[1][(usz)v])path[pc++]=v;}}
 usz bytes=(1+pc)*8;if(output==null||capacity<bytes)return -2;put(output,0,(long)pc);for(usz i=0;i<pc;i++)put(output,1+i,(long)path[i]);return (long)bytes;
}
