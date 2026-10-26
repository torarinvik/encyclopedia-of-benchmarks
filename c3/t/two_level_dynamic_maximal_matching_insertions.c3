module two_level_dynamic_maximal_matching_insertions;
fn void put64(char*o,int at,long x){ulong b=(ulong)x;for(int i=0;i<8;i++)o[at+i]=(char)(b>>(8*i));}
fn int owned(bool*g,int*level,int n,int u,int*out){int z=0;for(int v=0;v<n;v++)if(g[u*9+v]&&level[u]==0&&level[v]==0)out[z++]=v;return z;}
fn void repair(bool*g,int*level,int*mate,int n,int u){if(u<0||level[u]!=0||mate[u]>=0)return;for(int v=0;v<n;v++)if(g[u*9+v]&&level[v]==0&&mate[v]<0){mate[u]=v;mate[v]=u;return;}}
fn bool promote(bool*g,int*level,int*mate,int n,int u,int*tape,int r,int*used){int[9] list;int count=owned(g,level,n,u,&list[0]);if(count==0||*used>=r||tape[*used]>=count)return false;int y=list[tape[*used]];*used+=1;int w=mate[u],x=mate[y];if(w>=0){mate[w]=-1;mate[u]=-1;}if(x>=0){mate[x]=-1;mate[y]=-1;}level[u]=1;level[y]=1;mate[u]=y;mate[y]=u;if(w>=0)repair(g,level,mate,n,w);if(x>=0&&x!=w)repair(g,level,mate,n,x);return true;}
long two_level_dynamic_maximal_matching_insertions(long*input,usz length,char*output,usz capacity) @export("two_level_dynamic_maximal_matching_insertions") {
 if(input==null||length<3||length>55)return -1;long n0=input[0],q0=input[1];if((n0!=4&&n0!=9)||q0<0||q0>24||q0>n0*(n0-1)/2)return -1;int n=(int)n0,q=(int)q0;int[24] us,vs;bool[81] seen=zeroed;usz p=2;
 for(int e=0;e<q;e++){long u0=input[p++],v0=input[p++];if(u0<0||v0<=u0||v0>=n0||seen[(int)u0*9+(int)v0])return -1;seen[(int)u0*9+(int)v0]=true;us[e]=(int)u0;vs[e]=(int)v0;}
 if(p>=length)return -1;long r0=input[p++];if(r0<0||r0>4||length!=p+(usz)r0)return -1;int r=(int)r0;int[4] tape;for(int i=0;i<r;i++){long x=input[p++];if(x<0||x>=n0)return -1;tape[i]=(int)x;}
 bool[81] graph=zeroed;int[9] level=zeroed;int[9] mate;for(int i=0;i<n;i++)mate[i]=-1;int used=0,t=(n==4?2:3);
 for(int e=0;e<q;e++){int u=us[e],v=vs[e];graph[u*9+v]=true;graph[v*9+u]=true;if(level[u]==1||level[v]==1)continue;if(mate[u]<0&&mate[v]<0){mate[u]=v;mate[v]=u;}int[9] a,b;int da=owned(&graph[0],&level[0],n,u,&a[0]),db=owned(&graph[0],&level[0],n,v,&b[0]);int who=(da>db||(da==db&&u<v))?u:v;int[9] c;int dc=owned(&graph[0],&level[0],n,who,&c[0]);if(dc>=t&&!promote(&graph[0],&level[0],&mate[0],n,who,&tape[0],r,&used))return -1;}
 if(used!=r)return -1;usz bytes=8*(usz)(1+2*n);if(output==null||capacity<bytes)return -2;put64(output,0,n);for(int i=0;i<n;i++)put64(output,8+8*i,level[i]);for(int i=0;i<n;i++)put64(output,8+8*n+8*i,mate[i]);return (long)bytes;
}
