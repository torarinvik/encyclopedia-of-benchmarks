#include <cstddef>
#include <cstdint>
#include <climits>

namespace {
constexpr std::size_t N=5,F=5,Q=8,P=10,PARSE=128;
void put(std::uint8_t* out,std::size_t at,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t i=0;i<8;++i){out[at+i]=static_cast<std::uint8_t>(bits&255U);bits>>=8;}}
std::int64_t stateCost(std::size_t n,std::size_t f,const std::int64_t d[P][P],const std::int64_t* demand,const std::int64_t* assignment,const std::int64_t* fee,std::uint32_t mask){std::int64_t total=0;for(std::size_t s=0;s<f;++s)if(mask&(1U<<s))total+=fee[s];for(std::size_t j=0;j<n;++j)total+=demand[j]*d[j][n+static_cast<std::size_t>(assignment[j])];return total;}
}
extern "C" std::int64_t facility_location_randomized_add_delete_many(const std::int64_t* in,std::size_t len,std::uint8_t* out,std::size_t cap) noexcept{
 if(!in||len<12||len>PARSE)return -1;auto n0=in[0],f0=in[1],q0=in[2],raw=in[3];if(n0<1||n0>5||f0<1||f0>5||q0<1||q0>8||raw<=0||static_cast<std::uint64_t>(raw)>=(1ULL<<f0))return -1;
 auto n=static_cast<std::size_t>(n0),f=static_cast<std::size_t>(f0),q=static_cast<std::size_t>(q0),p=n+f;if(len!=4+2*n+p*p+f+q)return -1;auto mask=static_cast<std::uint32_t>(raw);
 std::int64_t assignment[N]{},demand[N]{},d[P][P]{},fee[F]{},tape[Q]{};std::size_t at=4;
 for(std::size_t j=0;j<n;++j){assignment[j]=in[at++];if(assignment[j]<0||assignment[j]>=f0||!(mask&(1U<<assignment[j])))return -1;}
 for(std::size_t j=0;j<n;++j){demand[j]=in[at++];if(demand[j]<1||demand[j]>10)return -1;}
 for(std::size_t i=0;i<p;++i)for(std::size_t j=0;j<p;++j){auto x=in[at++];if(x<0||x>1000)return -1;d[i][j]=x;}
 for(std::size_t i=0;i<p;++i){if(d[i][i]!=0)return -1;for(std::size_t j=0;j<p;++j){if(i!=j&&d[i][j]==0)return -1;if(d[i][j]!=d[j][i])return -1;for(std::size_t k=0;k<p;++k)if(d[i][j]>d[i][k]+d[k][j])return -1;}}
 for(std::size_t s=0;s<f;++s){fee[s]=in[at++];if(fee[s]<0||fee[s]>1000)return -1;}for(std::size_t t=0;t<q;++t){tape[t]=in[at++];if(tape[t]<0||tape[t]>=f0)return -1;}
 std::int64_t costs[Q]{},accepted[Q]{},current=stateCost(n,f,d,demand,assignment,fee,mask),count=0;
 for(std::size_t step=0;step<q;++step){auto candidate=static_cast<std::size_t>(tape[step]);auto bit=1U<<candidate;std::int64_t did=0;if(!(mask&bit)){bool closer[N]{};std::int64_t gain=-fee[candidate];for(std::size_t j=0;j<n;++j){auto old=static_cast<std::size_t>(assignment[j]);if(d[j][n+candidate]<d[j][n+old]){closer[j]=true;gain+=demand[j]*(d[j][n+old]-d[j][n+candidate]);}}
 std::uint32_t drop=0;for(std::size_t s=0;s<f;++s)if(mask&(1U<<s)){std::int64_t cg=fee[s];for(std::size_t j=0;j<n;++j)if(static_cast<std::size_t>(assignment[j])==s&&!closer[j])cg+=demand[j]*(d[j][n+s]-d[j][n+candidate]);if(cg>0){drop|=1U<<s;gain+=cg;}}
 if(gain>0){mask=(mask|bit)&~drop;for(std::size_t j=0;j<n;++j)if(closer[j]||(drop&(1U<<static_cast<std::size_t>(assignment[j]))))assignment[j]=static_cast<std::int64_t>(candidate);current=stateCost(n,f,d,demand,assignment,fee,mask);did=1;++count;}}costs[step]=current;accepted[step]=did;}
 auto bytes=8*(2*q+3+n);if(!out||cap<bytes)return -2;at=0;for(std::size_t t=0;t<q;++t){put(out,at,costs[t]);at+=8;}for(std::size_t t=0;t<q;++t){put(out,at,accepted[t]);at+=8;}put(out,at,current);at+=8;put(out,at,mask);at+=8;for(std::size_t j=0;j<n;++j){put(out,at,assignment[j]);at+=8;}put(out,at,count);at+=8;return static_cast<std::int64_t>(at);
}
