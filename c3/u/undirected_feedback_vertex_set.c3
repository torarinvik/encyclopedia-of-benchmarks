// Clean-room bounded iterative-compression feedback vertex set profile.
module undirected_feedback_vertex_set;
const N:usz=8,MAX_INPUT:usz=59;const FAILURE:ulong=0xFFFFFFFFFFFFFFFFul;
fn usz bit_count(ulong x){usz n=0;while(x!=0){n+=x&1ul;x>>=1;}return n;}
fn usz root(usz* parent,usz x){while(parent[x]!=x){parent[x]=parent[parent[x]];x=parent[x];}return x;}
fn bool forest(bool* g,usz n,ulong vertices){usz[N] parent={};for(usz i=0;i<n;++i)parent[i]=i;for(usz u=0;u<n;++u){if((vertices>>u)&1ul){for(usz v=u+1;v<n;++v){if(((vertices>>v)&1ul)&&g[u*N+v]){usz a=root(&parent[0],u),b=root(&parent[0],v);if(a==b)return false;parent[a]=b;}}}}return true;}
fn ulong compress(bool* g,usz n,ulong prefix,usz k,ulong current){ulong x=current;while(true){usz cx=bit_count(x);ulong excluded=current&~x;if(cx<=k&&forest(g,n,excluded)){ulong eligible=prefix&~current;ulong s=eligible;while(true){if(bit_count(s)<=k-cx&&forest(g,n,prefix&~(x|s)))return x|s;if(s==0)break;s=(s-1)&eligible;}}if(x==0)break;x=(x-1)&current;}return FAILURE;}
fn ulong solve_budget(bool* g,usz n,usz k){ulong fvs=0;for(usz i=0;i<n;++i){ulong prefix=(1ul<<(i+1))-1;ulong candidate=fvs|(1ul<<i);if(bit_count(candidate)<=k){fvs=candidate;continue;}fvs=compress(g,n,prefix,k,candidate);if(fvs==FAILURE)return FAILURE;}return fvs;}
fn long minimum_fvs(bool* g,usz n,usz limit){for(usz k=0;k<=limit;++k){if(solve_budget(g,n,k)!=FAILURE)return (long)k;}return -1;}
fn void put(char* out,usz at,long x){ulong b=(ulong)x;for(usz i=0;i<8;++i){out[at+i]=(char)(b&255ul);b>>=8;}}
fn long undirected_feedback_vertex_set(long* input,usz length,char* output,usz capacity) @export("undirected_feedback_vertex_set"){
 if(input==null||length<3||length>MAX_INPUT)return -1;long n64=input[0],m64,limit; m64=input[1];limit=input[2];if(n64<1||n64>8||m64<0||m64>28||limit<0||limit>4||length!=3+2*(usz)m64)return -1;usz n=(usz)n64,m=(usz)m64;bool[N*N] g={};long pu=-1,pv=-1;for(usz e=0;e<m;++e){long u=input[3+2*e],v=input[4+2*e];if(u<0||v<=u||v>=n64||u<pu||(u==pu&&v<=pv))return -1;g[(usz)u*N+(usz)v]=true;g[(usz)v*N+(usz)u]=true;pu=u;pv=v;}if(output==null||capacity<16)return -2;long minimum=minimum_fvs(&g[0],n,(usz)limit);put(output,0,minimum<0?0:1);put(output,8,minimum);return 16;
}
