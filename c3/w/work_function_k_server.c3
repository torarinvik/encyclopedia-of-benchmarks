module work_function_k_server;
const MAX_P: usz=6, MAX_K: usz=3, MAX_R: usz=8, MAX_CONFIGS: usz=20, MAX_INPUT: usz=50;

fn void store_i64_le(char* o, usz at, long x){ulong b=(ulong)x;for(usz j=0;j<8;++j){o[at+j]=(char)(b&255ul);b>>=8;}}
fn void sort_cfg(long* x,usz k){for(usz i=0;i<k;++i)for(usz j=i+1;j<k;++j)if(x[j]<x[i]){long t=x[i];x[i]=x[j];x[j]=t;}}
fn usz find_cfg(long* cfg,usz count,long* x,usz k){for(usz i=0;i<count;++i){usz j=0;while(j<k&&cfg[i*MAX_K+j]==x[j])++j;if(j==k)return i;}return count;}
fn long cfg_dist(long* a,long* b,usz k,long* d,usz p){
 if(k==1)return d[(usz)a[0]*p+(usz)b[0]];
 if(k==2){long x=d[(usz)a[0]*p+(usz)b[0]]+d[(usz)a[1]*p+(usz)b[1]];long y=d[(usz)a[0]*p+(usz)b[1]]+d[(usz)a[1]*p+(usz)b[0]];return x<y?x:y;}
 usz[6][3] q={{0,1,2},{0,2,1},{1,0,2},{1,2,0},{2,0,1},{2,1,0}};long best=0x7FFFFFFFFFFFFFFF;
 for(usz z=0;z<6;++z){long v=d[(usz)a[0]*p+(usz)b[q[z][0]]]+d[(usz)a[1]*p+(usz)b[q[z][1]]]+d[(usz)a[2]*p+(usz)b[q[z][2]]];if(v<best)best=v;}return best;
}

fn long work_function_k_server(long* input,usz length,char* output,usz capacity) @export("work_function_k_server"){
 if(input==null||length<3||length>MAX_INPUT)return -1;long p64=input[0],k64=input[1],n64=input[2];
 if(p64<2||p64>6||k64<1||k64>3||k64>p64||n64<0||n64>8)return -1;usz p=(usz)p64,k=(usz)k64,n=(usz)n64;
 usz initial_at=3+p*p,req_at=initial_at+k;if(length!=req_at+n)return -1;
 long[36] d;for(usz i=0;i<p;++i)for(usz j=0;j<p;++j){long x=input[3+i*p+j];if(x<0||x>1000||(i==j&&x!=0)||(i!=j&&x==0))return -1;d[i*p+j]=x;}
 for(usz i=0;i<p;++i)for(usz j=0;j<p;++j){if(d[i*p+j]!=d[j*p+i])return -1;for(usz z=0;z<p;++z)if(d[i*p+j]>d[i*p+z]+d[z*p+j])return -1;}
 long[MAX_K] initial={};for(usz i=0;i<k;++i){long x=input[initial_at+i];if(x<0||x>=p64)return -1;initial[i]=x;for(usz j=0;j<i;++j)if(initial[j]==x)return -1;}sort_cfg(&initial[0],k);
 long[MAX_R] requests={};for(usz t=0;t<n;++t){long x=input[req_at+t];if(x<0||x>=p64)return -1;requests[t]=x;}
 usz output_bytes=8*(2+n*k);if(output==null||capacity<output_bytes)return -2;
 long[MAX_CONFIGS*MAX_K] cfg={};usz count=0;
 for(usz a=0;a<p;++a){if(k==1){cfg[count*MAX_K]=a;++count;continue;}for(usz b=a+1;b<p;++b){if(k==2){cfg[count*MAX_K]=a;cfg[count*MAX_K+1]=b;++count;continue;}for(usz c=b+1;c<p;++c){cfg[count*MAX_K]=a;cfg[count*MAX_K+1]=b;cfg[count*MAX_K+2]=c;++count;}}}
 long[MAX_CONFIGS] work={},next={};for(usz x=0;x<count;++x)work[x]=cfg_dist(&initial[0],&cfg[x*MAX_K],k,&d[0],p);
 long[2+MAX_R*MAX_K] staged={};staged[0]=(long)n;staged[1]=(long)k;long[MAX_K] current={};for(usz j=0;j<k;++j)current[j]=initial[j];
 for(usz t=0;t<n;++t){long r=requests[t];for(usz x=0;x<count;++x){next[x]=0x7FFFFFFFFFFFFFFF;for(usz y=0;y<count;++y){bool has=false;for(usz j=0;j<k;++j)if(cfg[y*MAX_K+j]==r)has=true;if(!has)continue;long v=work[y]+cfg_dist(&cfg[y*MAX_K],&cfg[x*MAX_K],k,&d[0],p);if(v<next[x])next[x]=v;}}
  long best=0x7FFFFFFFFFFFFFFF;usz best_slot=0;long[MAX_K] chosen={};bool already=false;for(usz j=0;j<k;++j){chosen[j]=current[j];if(current[j]==r)already=true;}if(!already){for(usz slot=0;slot<k;++slot){long[MAX_K] cand={};for(usz j=0;j<k;++j)cand[j]=j==slot?r:current[j];sort_cfg(&cand[0],k);usz ix=find_cfg(&cfg[0],count,&cand[0],k);long score=work[ix]+d[(usz)current[slot]*p+(usz)r];if(score<best||(score==best&&slot<best_slot)){best=score;best_slot=slot;for(usz j=0;j<k;++j)chosen[j]=cand[j];}}}
  for(usz j=0;j<k;++j){staged[2+t*k+j]=chosen[j];current[j]=chosen[j];}for(usz x=0;x<count;++x)work[x]=next[x];
 }
 for(usz i=0;i<2+n*k;++i)store_i64_le(output,8*i,staged[i]);return (long)output_bytes;
}
