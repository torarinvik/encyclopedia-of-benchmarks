module dense_graph_bipartiteness_tester;
const int MAX_N=64;const int MAX_Q=16;const int MAX_INPUT=82;const int MAX_OUTPUT=16;
fn bool has_edge(long row,usz vertex){ulong bits=(ulong)row;return ((bits>>vertex)&1)!=0;}
fn void put_i64(char* out,usz offset,long value){ulong bits=(ulong)value;for(usz i=0;i<8;i++){out[offset+i]=(char)(bits&255);bits>>=8;}}
fn long dense_graph_bipartiteness_tester(long* v,usz length,char* output,usz capacity) @export("dense_graph_bipartiteness_tester") {
 if(v==null||length<4||length>MAX_INPUT||v[0]<1||v[0]>64||v[1]<1||v[1]>16)return -1;int n=(int)v[0],q=(int)v[1];if(q>n||length!=(usz)(2+n+q))return -1;
 for(int i=0;i<n;i++){long row=v[2+i];if((n<64&&(row<0||((ulong)row>>n)!=0))||has_edge(row,(usz)i))return -1;for(int j=i+1;j<n;j++)if(has_edge(row,(usz)j)!=has_edge(v[2+j],(usz)i))return -1;}
 int[MAX_N] remaining={};int[MAX_Q] sample={};for(int i=0;i<n;i++)remaining[i]=i;
 for(int i=0;i<q;i++){long draw=v[2+n+i];if(draw<0||draw>=n-i)return -1;int selected=i+(int)draw,temp=remaining[i];remaining[i]=remaining[selected];remaining[selected]=temp;sample[i]=remaining[i];}
 bool[MAX_Q*MAX_Q] adjacent={};for(int i=0;i<q;i++)for(int j=i+1;j<q;j++){bool edge=has_edge(v[2+sample[i]],(usz)sample[j]);adjacent[i*MAX_Q+j]=edge;adjacent[j*MAX_Q+i]=edge;}
 int[MAX_Q] color={};for(int i=0;i<q;i++)color[i]=-1;int accepted=1;
 for(int start=0;start<q;start++){if(color[start]!=-1)continue;int[MAX_Q] queue={};int head=0,tail=0;queue[tail++]=start;color[start]=0;while(head<tail){int vertex=queue[head++];for(int neighbor=0;neighbor<q;neighbor++){if(!adjacent[vertex*MAX_Q+neighbor])continue;if(color[neighbor]==-1){color[neighbor]=color[vertex]^1;queue[tail++]=neighbor;}else if(color[neighbor]==color[vertex])accepted=0;}}}
 if(output==null||capacity<MAX_OUTPUT)return -2;char[MAX_OUTPUT] staged={};put_i64(staged,0,accepted);put_i64(staged,8,q*(q-1)/2);for(usz i=0;i<MAX_OUTPUT;i++)output[i]=staged[i];return MAX_OUTPUT;
}
