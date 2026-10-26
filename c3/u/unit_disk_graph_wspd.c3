module unit_disk_graph_wspd;

const int N=8; const int PAIRS=28; const int MAX_INPUT=18;
const long INF=2305843009213693951;
struct Context { int n; int c; int count; long[64] distance; ulong[28] left; ulong[28] right; }
fn int at(int i,int j){return i*N+j;}
fn int size(ulong mask){int n=0;while(mask!=0){n+=(int)(mask&1);mask>>=1;}return n;}
fn void split(ulong mask,ulong* left,ulong* right){*left=0;*right=0;int half=size(mask)/2,seen=0;for(int i=0;i<N;i++)if((mask&((ulong)1<<i))!=0){if(seen<half)*left|=(ulong)1<<i;else *right|=(ulong)1<<i;seen++;}}
fn long diameter(Context* x,ulong mask){long best=0;for(int i=0;i<x->n;i++)if((mask&((ulong)1<<i))!=0)for(int j=i+1;j<x->n;j++)if((mask&((ulong)1<<j))!=0&&x->distance[at(i,j)]>best)best=x->distance[at(i,j)];return best;}
fn long between(Context* x,ulong a,ulong b){long best=INF;for(int i=0;i<x->n;i++)if((a&((ulong)1<<i))!=0)for(int j=0;j<x->n;j++)if((b&((ulong)1<<j))!=0&&x->distance[at(i,j)]<best)best=x->distance[at(i,j)];return best;}
fn void cross(Context* x,ulong a,ulong b){long da=diameter(x,a),db=diameter(x,b),m=da>db?da:db;if(between(x,a,b)>=(long)x->c*m){if(x->count<PAIRS){x->left[x->count]=a;x->right[x->count]=b;x->count++;}return;}if(size(a)>=size(b)&&size(a)>1){ulong l,r;split(a,&l,&r);cross(x,l,b);cross(x,r,b);}else{ulong l,r;split(b,&l,&r);cross(x,a,l);cross(x,a,r);}}
fn void visit(Context* x,ulong mask){if(size(mask)<2)return;ulong l,r;split(mask,&l,&r);visit(x,l);visit(x,r);cross(x,l,r);}
fn void put_i64(char* out,usz pos,long value){ulong bits=(ulong)value;for(usz i=0;i<8;i++){out[pos+i]=(char)(bits&255);bits>>=8;}}
fn long unit_disk_graph_wspd(long* values,usz length,char* output,usz capacity) @export("unit_disk_graph_wspd"){
 if(values==null||length<4||length>MAX_INPUT||values[0]<1||values[0]>N||values[1]<1||values[1]>8||length!=2+2*(usz)values[0])return -1;
 Context x={};x.n=(int)values[0];x.c=(int)values[1];long[8] px={};long[8] py={};
 for(int i=0;i<x.n;i++){px[i]=values[2+2*i];py[i]=values[3+2*i];if(px[i] < -8||px[i]>8||py[i] < -8||py[i]>8)return -1;for(int j=0;j<i;j++)if(px[i]==px[j]&&py[i]==py[j])return -1;}
 for(int i=0;i<x.n;i++)for(int j=0;j<x.n;j++)x.distance[at(i,j)]=i==j?0:INF;
 for(int i=0;i<x.n;i++)for(int j=i+1;j<x.n;j++){long dx=px[i]-px[j],dy=py[i]-py[j];if(dx*dx+dy*dy<=1){x.distance[at(i,j)]=1;x.distance[at(j,i)]=1;}}
 for(int k=0;k<x.n;k++)for(int i=0;i<x.n;i++)for(int j=0;j<x.n;j++){long alt=x.distance[at(i,k)]+x.distance[at(k,j)];if(alt<x.distance[at(i,j)])x.distance[at(i,j)]=alt;}
 for(int i=0;i<x.n;i++)for(int j=0;j<x.n;j++)if(x.distance[at(i,j)]>=INF/2)return -1;
 visit(&x,((ulong)1<<x.n)-1);usz bytes=8+16*(usz)x.count;char[456] staged={};put_i64(staged,0,x.count);for(int i=0;i<x.count;i++){put_i64(staged,8+16*(usz)i,(long)x.left[i]);put_i64(staged,16+16*(usz)i,(long)x.right[i]);}if(output==null||capacity<bytes)return -2;for(usz i=0;i<bytes;i++)output[i]=staged[i];return (long)bytes;
}
