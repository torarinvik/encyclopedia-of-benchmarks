// Clean-room high-/low-degree vertex-cover reduction profile.
module vertex_cover_kernelization;

const MAX_N: usz=16, MAX_M: usz=64, MAX_INPUT: usz=131, MAX_FIELDS: usz=133;

fn void put_i64(char* output,usz at,long value){ulong bits=(ulong)value;for(usz b=0;b<8;++b){output[at+b]=(char)(bits&255ul);bits>>=8;}}

fn long vertex_cover_kernelization(long* input,usz length,char* output,usz capacity) @export("vertex_cover_kernelization") {
 if(input==null||length<3||length>MAX_INPUT)return -1;
 long n64=input[0],m64=input[1],k=input[2];
 if(n64<1||n64>16||m64<0||m64>64||k<0||k>16||length!=3+2*(usz)m64)return -1;
 usz n=(usz)n64,m=(usz)m64;
 bool[MAX_N*MAX_N] edge={};long previous_u=-1,previous_v=-1;
 for(usz e=0;e<m;++e){long u=input[3+2*e],v=input[4+2*e];if(u<0||v<=u||v>=n64||u<previous_u||(u==previous_u&&v<=previous_v))return -1;edge[(usz)u*MAX_N+(usz)v]=true;edge[(usz)v*MAX_N+(usz)u]=true;previous_u=u;previous_v=v;}
 if(output==null)return -2;
 bool[MAX_N] active={};for(usz i=0;i<n;++i)active[i]=true;ulong forced=0;bool infeasible=false;
 while(true){if(k<0){infeasible=true;break;}usz chosen=n,neighbor=n;usz kind=0;
  for(usz u=0;u<n;++u){if(active[u]){usz degree=0;for(usz v=0;v<n;++v){if(edge[u*MAX_N+v])++degree;}if(degree==0){chosen=u;kind=1;break;}}}
  if(kind==1){active[chosen]=false;continue;}
  for(usz u=0;u<n;++u){if(active[u]){usz degree=0,only=n;for(usz v=0;v<n;++v){if(edge[u*MAX_N+v]){++degree;only=v;}}if(degree==1){chosen=u;neighbor=only;kind=2;break;}}}
  if(kind==0){for(usz u=0;u<n;++u){if(active[u]){usz degree=0;for(usz v=0;v<n;++v){if(edge[u*MAX_N+v])++degree;}if((long)degree>k){chosen=u;kind=3;break;}}}}
  if(kind==0)break;usz f=kind==2?neighbor:chosen;forced|=1ul<<f;active[f]=false;--k;for(usz v=0;v<n;++v){edge[f*MAX_N+v]=false;edge[v*MAX_N+f]=false;}
 }
 long[MAX_FIELDS] staged={};usz count=0;staged[count++]=infeasible?0:1;staged[count++]=k;staged[count++]=(long)forced;ulong active_mask=0;for(usz v=0;v<n;++v){if(active[v])active_mask|=1ul<<v;}staged[count++]=(long)active_mask;
 usz remaining=0;for(usz u=0;u<n;++u){for(usz v=u+1;v<n;++v){if(edge[u*MAX_N+v])++remaining;}}staged[count++]=(long)remaining;
 for(usz u=0;u<n;++u){for(usz v=u+1;v<n;++v){if(edge[u*MAX_N+v]){staged[count++]=(long)u;staged[count++]=(long)v;}}}
 if(capacity<8*count)return -2;for(usz i=0;i<count;++i)put_i64(output,8*i,staged[i]);return (long)(8*count);
}
