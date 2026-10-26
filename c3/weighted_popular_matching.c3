// Clean-room exhaustive solver for bounded weighted popular matchings.
module weighted_popular_matching;
const usz N=4;const usz F=6;
fn bool decode(usz code0,usz n,usz m,long[N]*a){usz code=code0;uint used=0;for(usz i=0;i<n;++i){usz digit=code%(m+1);code/=(m+1);a[i]=(long)digit-1;if(digit>0){uint bit=1u<<(digit-1);if((used&bit)!=0)return false;used|=bit;}}return true;}
fn bool lexless(long[N]a,long[N]b,usz n){for(usz i=0;i<n;++i)if(a[i]!=b[i])return a[i]<b[i];return false;}
fn void put(char*out,usz at,long x){ulong bits=(ulong)x;for(usz i=0;i<8;++i){out[at+i]=(char)(bits&255ul);bits>>=8;}}
fn long weighted_popular_matching(long*v,usz length,char*out,usz capacity) @export("weighted_popular_matching"){
 if(v==null||length<4||length>22||v[0]<1||v[0]>4||v[1]<1||v[1]>4)return -1;usz n=(usz)v[0],m=(usz)v[1];if(length!=2+n+n*m)return -1;for(usz i=0;i<n;++i){if(v[2+i]<1||v[2+i]>1000)return -1;uint seen=0;for(usz j=0;j<m;++j){long rank=v[2+n+i*m+j];if(rank<0||rank>=(long)m||(seen&(1u<<(uint)rank))!=0)return -1;seen|=1u<<(uint)rank;}}
 usz total=1;for(usz i=0;i<n;++i)total*=m+1;long best_card=-1;long[N] best={};for(usz i=0;i<N;++i)best[i]=-1;
 for(usz code=0;code<total;++code){long[N] cand={};if(!decode(code,n,m,&cand))continue;bool popular=true;for(usz oc=0;oc<total&&popular;++oc){long[N] other={};if(!decode(oc,n,m,&other))continue;long score=0;for(usz i=0;i<n;++i){long rc=cand[i]<0?(long)m:v[2+n+i*m+(usz)cand[i]],ro=other[i]<0?(long)m:v[2+n+i*m+(usz)other[i]];if(ro<rc)score+=v[2+i];else if(ro>rc)score-=v[2+i];}if(score>0)popular=false;}
  if(popular){long card=0;for(usz i=0;i<n;++i)if(cand[i]>=0)++card;if(card>best_card||(card==best_card&&lexless(cand,best,n))){best_card=card;best=cand;}}
 }
 long[F] fields={};fields[0]=best_card<0?0:1;fields[1]=best_card<0?0:best_card;for(usz i=0;i<n;++i)fields[2+i]=best_card<0?-1:best[i];usz bytes=8*(n+2);if(out==null||capacity<bytes)return -2;for(usz i=0;i<n+2;++i)put(out,8*i,fields[i]);return (long)bytes;
}
