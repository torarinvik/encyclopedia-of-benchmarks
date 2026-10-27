#include <cstddef>
#include <cstdint>
namespace {constexpr int N=8,M=12,P=8,H=56,MAX_INPUT=99;
bool parse(const std::int64_t*a,std::size_t len,int&n,int&m,int&p,int u[M],int v[M],int plen[P],int path[P][N]){
 if(!a||len<3||len>MAX_INPUT)return false;auto n0=a[0],m0=a[1],p0=a[2];if(n0<2||n0>N||m0<1||m0>M||p0<1||p0>P)return false;n=(int)n0;m=(int)m0;p=(int)p0;std::size_t at=3;if(at+2*(std::size_t)m>len)return false;bool seen[M][M]{};
 for(int e=0;e<m;e++){auto x=a[at++],y=a[at++];if(x<0||x>=n||y<0||y>=n||x==y)return false;int lo=(int)(x<y?x:y),hi=(int)(x<y?y:x);if(seen[lo][hi])return false;seen[lo][hi]=true;u[e]=(int)x;v[e]=(int)y;}
 for(int q=0;q<p;q++){if(at+2>len)return false;auto start=a[at++],k=a[at++];if(start<0||start>=n||k<1||k>n-1||at+(std::size_t)k>len)return false;plen[q]=(int)k;bool used_v[N]{},used_e[M]{};int cur=(int)start;used_v[cur]=true;for(int j=0;j<plen[q];j++){auto e0=a[at++];if(e0<0||e0>=m)return false;int e=(int)e0;if(used_e[e])return false;used_e[e]=true;path[q][j]=e;int next=-1;if(u[e]==cur)next=v[e];else if(v[e]==cur)next=u[e];else return false;if(used_v[next])return false;used_v[next]=true;cur=next;}}
 return at==len;
}
void put(std::uint8_t*out,const std::int64_t*words,std::size_t n){for(std::size_t i=0;i<n;i++){auto x=(std::uint64_t)words[i];for(int b=0;b<8;b++)out[i*8+b]=(std::uint8_t)(x>>(8*b));}}
}
extern "C" std::int64_t packet_routing_work_conserving_schedule(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
 int n,m,p,u[M]{},v[M]{},plen[P]{},path[P][N]{};if(!parse(input,length,n,m,p,u,v,plen,path))return -1;int pos[P]{},tt[H]{},te[H]{},tp[H]{},count=0,time=0;
 for(;;){int active=0,chosen[M];for(int e=0;e<m;e++)chosen[e]=-1;for(int q=0;q<p;q++)if(pos[q]<plen[q]){active=1;int e=path[q][pos[q]];if(chosen[e]<0)chosen[e]=q;}if(!active)break;for(int e=0;e<m;e++)if(chosen[e]>=0){if(count>=H)return -1;tt[count]=time;te[count]=e;tp[count]=chosen[e];count++;pos[chosen[e]]++;}time++;if(time>N*P)return -1;}
 std::int64_t words[2+3*H]{};words[0]=time;words[1]=count;for(int i=0;i<count;i++){words[2+3*i]=tt[i];words[3+3*i]=te[i];words[4+3*i]=tp[i];}std::size_t nw=2+3*(std::size_t)count,bytes=nw*8;if(!output||capacity<bytes)return -2;put(output,words,nw);return (std::int64_t)bytes;
}
