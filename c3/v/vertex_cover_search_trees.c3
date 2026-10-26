// Clean-room exact branch-and-search vertex-cover profile.
module vertex_cover_search_trees;
const MAX_N:usz=16,MAX_INPUT:usz=131;
fn usz count_bits(ulong value){usz count=0;while(value!=0){count+=value&1ul;value>>=1;}return count;}
fn ulong search(bool* adj,usz n,ulong active){
 usz chosen=n,best_degree=0;bool any=false;
 for(usz u=0;u<n;++u){if((active>>u)&1ul){usz degree=0;for(usz v=0;v<n;++v){if(((active>>v)&1ul)&&adj[u*MAX_N+v])++degree;}if(degree>0){any=true;if(chosen==n||degree>best_degree){chosen=u;best_degree=degree;}}}}
 if(!any)return 0;ulong bit=1ul<<chosen;ulong first=bit|search(adj,n,active&~bit);ulong neighbors=0;for(usz v=0;v<n;++v){if(((active>>v)&1ul)&&adj[chosen*MAX_N+v])neighbors|=1ul<<v;}ulong second=neighbors|search(adj,n,active&~(neighbors|bit));usz a=count_bits(first),b=count_bits(second);if(a<b)return first;if(b<a)return second;return first<second?first:second;
}
fn void put(char* out,usz at,long x){ulong bits=(ulong)x;for(usz b=0;b<8;++b){out[at+b]=(char)(bits&255ul);bits>>=8;}}
fn long vertex_cover_search_trees(long* input,usz length,char* output,usz capacity) @export("vertex_cover_search_trees"){
 if(input==null||length<3||length>MAX_INPUT)return -1;long n64=input[0],m64=input[1],k=input[2];if(n64<1||n64>16||m64<0||m64>64||k<0||k>n64||length!=3+2*(usz)m64)return -1;usz n=(usz)n64,m=(usz)m64;
 bool[MAX_N*MAX_N] adj={};long pu=-1,pv=-1;for(usz e=0;e<m;++e){long u=input[3+2*e],v=input[4+2*e];if(u<0||v<=u||v>=n64||u<pu||(u==pu&&v<=pv))return -1;adj[(usz)u*MAX_N+(usz)v]=true;adj[(usz)v*MAX_N+(usz)u]=true;pu=u;pv=v;}
 if(output==null||capacity<24)return -2;ulong cover=search(&adj[0],n,(1ul<<n)-1);long count=(long)count_bits(cover);put(output,0,count<=k?1:0);put(output,8,count);put(output,16,(long)cover);return 24;
}
