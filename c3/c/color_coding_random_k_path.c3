module color_coding_random_k_path;
const int MAX_N=12;const int MAX_M=66;const int MAX_K=6;const int MAX_TRIALS=8;const int MAX_INPUT=232;const int MAX_OUTPUT=64;
fn void put_i64(char*out,usz at,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++){out[at+b]=(char)(bits&255);bits>>=8;}}
fn bool path_less(int *a,int *b,int length){for(int i=0;i<length;i++){if(a[i]!=b[i])return a[i]<b[i];}return false;}
fn long color_coding_random_k_path(long*input,usz length,char*output,usz capacity) @export("color_coding_random_k_path"){
 if(input==null||length<(usz)4||length>(usz)MAX_INPUT)return -1;
 if(input[0]<1||input[0]>MAX_N||input[1]<0||input[1]>MAX_M||input[2]<1||input[2]>MAX_K||input[2]>input[0]||input[3]<1||input[3]>MAX_TRIALS)return -1;
 int n=(int)input[0],m=(int)input[1],k=(int)input[2],trials=(int)input[3];usz edge_start=4,color_start=edge_start+2*(usz)m;if(length!=color_start+(usz)(trials*n))return -1;
 ulong[MAX_N] adj=zeroed;
 for(int e=0;e<m;e++){long av=input[edge_start+2*(usz)e],bv=input[edge_start+2*(usz)e+1];if(av<0||bv<0||av>=n||bv>=n||av==bv)return -1;usz a=(usz)av,b=(usz)bv;if((adj[a]&(1ul<<b))!=0)return -1;adj[a]|=1ul<<b;adj[b]|=1ul<<a;}
 for(int t=0;t<trials;t++)for(int v=0;v<n;v++){long c=input[color_start+(usz)(t*n+v)];if(c<0||c>=k)return -1;}
 int full=(1<<k)-1;
 for(int trial=0;trial<trials;trial++){
  int[MAX_N] colors=zeroed;for(int v=0;v<n;v++)colors[v]=(int)input[color_start+(usz)(trial*n+v)];
  bool[1<<MAX_K][MAX_N] reachable=zeroed;int[1<<MAX_K][MAX_N][MAX_K] paths=zeroed;
  for(int mask=0;mask<=full;mask++)for(int v=0;v<n;v++)for(int j=0;j<k;j++)paths[mask][v][j]=-1;
  for(int v=0;v<n;v++){int mask=1<<colors[v];reachable[mask][v]=true;paths[mask][v][0]=v;}
  for(int mask=1;mask<=full;mask++){int plen=0;for(int x=mask;x!=0;x&=x-1)plen++;for(int v=0;v<n;v++)if(reachable[mask][v]&&mask!=full)for(int u=0;u<n;u++){int cb=1<<colors[u];if((adj[v]&(1ul<<(ulong)u))==0||(mask&cb)!=0)continue;int next=mask|cb;int[MAX_K] candidate=zeroed;for(int j=0;j<plen;j++)candidate[j]=paths[mask][v][j];candidate[plen]=u;if(!reachable[next][u]||path_less(&candidate[0],&paths[next][u][0],plen+1)){reachable[next][u]=true;for(int j=0;j<=plen;j++)paths[next][u][j]=candidate[j];}}}
  int best=-1;for(int v=0;v<n;v++)if(reachable[full][v]&&(best<0||path_less(&paths[full][v][0],&paths[full][best][0],k)))best=v;
  if(best>=0){usz bytes=(usz)(8*(k+2));if(output==null||capacity<bytes)return -2;char[MAX_OUTPUT] staged=zeroed;put_i64(&staged[0],0,1);put_i64(&staged[0],8,trial+1);for(int j=0;j<k;j++)put_i64(&staged[0],(usz)(8*(j+2)),paths[full][best][j]);for(usz i=0;i<bytes;i++)output[i]=staged[i];return (long)bytes;}
 }
 if(output==null||capacity<(usz)16)return -2;char[16] staged=zeroed;put_i64(&staged[0],0,0);put_i64(&staged[0],8,0);for(usz i=0;i<(usz)16;i++)output[i]=staged[i];return 16;
}
