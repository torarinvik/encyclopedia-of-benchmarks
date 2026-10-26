// Clean-room longest precedence chain of 2-intervals.
module two_interval_precedence_chain;
const usz N=16;const usz F=17;
fn bool before(long*v,usz a,usz b){for(usz q=0;q<4;++q){long x=v[1+4*a+q],y=v[1+4*b+q];if(x!=y)return x<y;}return a<b;}
fn bool precedes(long*v,usz a,usz b){return v[1+4*a+1]<v[1+4*b]&&v[1+4*a+3]<v[1+4*b+2];}
fn bool lexless(long[N]a,usz an,long[N]b,usz bn){usz m=an<bn?an:bn;for(usz i=0;i<m;++i)if(a[i]!=b[i])return a[i]<b[i];return an<bn;}
fn void put(char*out,usz at,long x){ulong bits=(ulong)x;for(usz i=0;i<8;++i){out[at+i]=(char)(bits&255ul);bits>>=8;}}
fn long two_interval_precedence_chain(long*v,usz n,char*out,usz cap) @export("two_interval_precedence_chain"){
 if(v==null||n<5||n>65||v[0]<1||v[0]>16)return -1;usz count=(usz)v[0];if(n!=1+4*count)return -1;for(usz i=0;i<count;++i){usz p=1+4*i;for(usz q=0;q<4;++q)if(v[p+q]<0||v[p+q]>63)return -1;if(v[p]>=v[p+1]||v[p+2]>=v[p+3]||v[p+1]>=v[p+2])return -1;}
 usz[N] order={};for(usz i=0;i<count;++i)order[i]=i;for(usz i=1;i<count;++i){usz x=order[i],j=i;while(j>0&&before(v,x,order[j-1])){order[j]=order[j-1];--j;}order[j]=x;}
 long[N][N] paths={};usz[N] lens={};for(usz i=0;i<count;++i){paths[i][0]=(long)order[i];lens[i]=1;for(usz j=0;j<i;++j)if(precedes(v,order[j],order[i])){long[N] candidate=paths[j];candidate[lens[j]]=(long)order[i];usz m=lens[j]+1;if(m>lens[i]||(m==lens[i]&&lexless(candidate,m,paths[i],lens[i]))){paths[i]=candidate;lens[i]=m;}}}
 usz best=0;for(usz i=1;i<count;++i)if(lens[i]>lens[best]||(lens[i]==lens[best]&&lexless(paths[i],lens[i],paths[best],lens[best])))best=i;long[F] fields={};fields[0]=(long)lens[best];for(usz i=0;i<lens[best];++i)fields[i+1]=paths[best][i];usz bytes=8*(lens[best]+1);if(out==null||cap<bytes)return -2;for(usz i=0;i<lens[best]+1;++i)put(out,8*i,fields[i]);return (long)bytes;
}
