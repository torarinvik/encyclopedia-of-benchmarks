module bidirectional_bfs;
const usz N=64; const usz MAX_ARCS=4096;
fn void put(char* out,usz slot,long v){ulong bits=(ulong)v;for(usz i=0;i<8;i++)out[slot*8+i]=(char)(bits>>(i*8));}
fn long bidirectional_bfs(long* input,usz length,char* output,usz capacity) @export("bidirectional_bfs") {
 if(input==null||length<4)return -1;if(input[0]<1||input[0]>(long)N||input[1]<0||input[1]>(long)MAX_ARCS||input[2]<0||input[2]>=input[0]||input[3]<0||input[3]>=input[0]||length!=4+2*(usz)input[1])return -1;usz n=(usz)input[0],m=(usz)input[1];bool[N][N] edge = zeroed;int[N][N] adj;usz[N] deg = zeroed;
 for(usz i=0;i<m;i++){long u=input[4+2*i],v=input[5+2*i];if(u<0||u>=(long)n||v<0||v>=(long)n)return -1;if(!edge[(usz)u][(usz)v]){edge[(usz)u][(usz)v]=true;adj[(usz)u][deg[(usz)u]]=(int)v;deg[(usz)u]++;}}for(usz u=0;u<n;u++)for(usz v=0;v<n;v++)if(edge[u][v]!=edge[v][u])return -1;
 int start=(int)input[2],target=(int)input[3],path[N];usz pc=0;if(start==target)path[pc++]=start;else{bool[2][N] seen = zeroed;int[2][N] parent;int[2][N] q;usz[2] head,tail;for(usz s=0;s<2;s++)for(usz i=0;i<n;i++)parent[s][i]= -1;seen[0][(usz)start]=true;seen[1][(usz)target]=true;q[0][tail[0]++]=start;q[1][tail[1]++]=target;int meet= -1;
  while(tail[0]>head[0]&&tail[1]>head[1]&&meet<0){usz end=tail[0];for(;head[0]<end;head[0]++){int u=q[0][head[0]];for(usz j=0;j<deg[(usz)u];j++){int v=adj[(usz)u][j];if(seen[0][(usz)v])continue;seen[0][(usz)v]=true;parent[0][(usz)v]=u;q[0][tail[0]++]=v;}}for(usz v=0;v<n;v++)if(seen[0][v]&&seen[1][v]){meet=(int)v;break;}if(meet>=0)break;end=tail[1];for(;head[1]<end;head[1]++){int u=q[1][head[1]];for(usz j=0;j<deg[(usz)u];j++){int v=adj[(usz)u][j];if(seen[1][(usz)v])continue;seen[1][(usz)v]=true;parent[1][(usz)v]=u;q[1][tail[1]++]=v;}}for(usz v=0;v<n;v++)if(seen[0][v]&&seen[1][v]){meet=(int)v;break;}}
  if(meet>=0){int rev[N];usz k=0;for(int v=meet;v!= -1;v=parent[0][(usz)v])rev[k++]=v;while(k>0)path[pc++]=rev[--k];for(int v=parent[1][(usz)meet];v!= -1;v=parent[1][(usz)v])path[pc++]=v;}}
 usz bytes=(1+pc)*8;if(output==null||capacity<bytes)return -2;put(output,0,(long)pc);for(usz i=0;i<pc;i++)put(output,1+i,(long)path[i]);return (long)bytes;
}
