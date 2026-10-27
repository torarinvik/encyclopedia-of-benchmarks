module st_planar_leftmost_augmenting_flow;
const int N=6,M=10,MAX_INPUT=60;
fn void put_i64(char* out,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)out[b]=(char)((bits>>(8*b))&255);}
fn long st_planar_leftmost_augmenting_flow(long* input,usz input_length,char* output,usz output_capacity) @export("st_planar_leftmost_augmenting_flow") {
 if(input==null||input_length<4||input_length>MAX_INPUT)return -1;
 long n0=input[0],m0=input[1],s0=input[2],t0=input[3];if(n0<2||n0>N||m0<1||m0>M||s0<0||s0>=n0||t0<0||t0>=n0||s0==t0)return -1;
 int n=(int)n0,m=(int)m0,s=(int)s0,t=(int)t0;if(input_length<(usz)(4+3*m))return -1;
 int[M] eu={0},ev={0},caps={0};bool[N][N] pairs={false};usz at=4;
 for(int e=0;e<m;e++){long u0=input[at++],v0=input[at++],c0=input[at++];if(u0<0||u0>=n0||v0<0||v0>=n0||u0==v0||c0<0||c0>5)return -1;int u=(int)u0,v=(int)v0;if(pairs[u][v]||pairs[v][u])return -1;pairs[u][v]=pairs[v][u]=true;eu[e]=u;ev[e]=v;caps[e]=(int)c0;}
 int[N] degree={0};int[N][N] rot={0};int[M][2] occ={0};bool[N][M] used={false};
 for(int x=0;x<n;x++){if(at>=input_length)return -1;long d0=input[at++];if(d0<0||d0>=n||at+(usz)d0>input_length)return -1;int d=(int)d0;degree[x]=d;for(int j=0;j<d;j++){long e0=input[at++];if(e0<0||e0>=m0)return -1;int e=(int)e0;if(used[x][e])return -1;used[x][e]=true;rot[x][j]=e;if(eu[e]==x)occ[e][0]++;else if(ev[e]==x)occ[e][1]++;else return -1;}}
 if(at!=input_length)return -1;for(int e=0;e<m;e++)if(occ[e][0]!=1||occ[e][1]!=1)return -1;
 bool[N] connected={false};int[N] queue={0};int head=0,tail=0;connected[s]=true;queue[tail++]=s;while(head<tail){int x=queue[head++];for(int e=0;e<m;e++){int y=-1;if(eu[e]==x)y=ev[e];else if(ev[e]==x)y=eu[e];if(y>=0&&!connected[y]){connected[y]=true;queue[tail++]=y;}}}for(int x=0;x<n;x++)if(!connected[x])return -1;
 int[M] flow={0};int total=0;
 while(true){bool[N] seen={false};int[N] parent={0},pe={0},pdir={0},next={0};for(int x=0;x<n;x++){parent[x]=-1;pe[x]=-1;}int[N] stack={0};int top=0;seen[s]=true;stack[top++]=s;
  while(top>0&&!seen[t]){int x=stack[top-1];if(next[x]>=degree[x]){top--;continue;}int e=rot[x][next[x]++],y=eu[e],rem=flow[e],dir=-1;if(eu[e]==x){y=ev[e];rem=caps[e]-flow[e];dir=1;}if(rem>0&&!seen[y]){seen[y]=true;parent[y]=x;pe[y]=e;pdir[y]=dir;stack[top++]=y;}}
  if(!seen[t])break;int delta=1000000;for(int y=t;y!=s;y=parent[y]){int x=parent[y],e=pe[y],r=flow[e];if(eu[e]==x)r=caps[e]-flow[e];if(r<delta)delta=r;}for(int y=t;y!=s;y=parent[y])flow[pe[y]]+=pdir[y]*delta;total+=delta;
 }
 if(output==null||output_capacity<8)return -2;put_i64(output,total);return 8;
}
