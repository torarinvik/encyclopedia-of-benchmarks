#include <cstddef>
#include <cstdint>
#include <climits>
namespace {
constexpr std::size_t T=8,M=7,INPUT=75;
void put(std::uint8_t* o,std::size_t at,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t i=0;i<8;++i){o[at+i]=static_cast<std::uint8_t>(b&255U);b>>=8;}}
bool lexLess(std::uint32_t a,std::uint32_t b,std::size_t m){std::size_t i=0,j=0;for(;;){while(i<m&&!(a&(1U<<i)))++i;while(j<m&&!(b&(1U<<j)))++j;if(i==m||j==m)return i==m&&j!=m;if(i!=j)return i<j;++i;++j;}}
std::int64_t objective(std::size_t n,std::size_t m,const std::int64_t d[T][T],const std::int64_t* fee,std::uint32_t mask){std::int64_t x=0;for(std::size_t j=0;j<m;++j)if(mask&(1U<<j))x+=fee[j];for(std::size_t u=0;u<n;++u){std::int64_t best=INT64_MAX;for(std::size_t j=0;j<m;++j)if((mask&(1U<<j))&&d[u][n+j]<best)best=d[u][n+j];x+=best;}return x;}
void consider(std::uint32_t c,std::size_t n,std::size_t m,const std::int64_t d[T][T],const std::int64_t* fee,std::uint32_t& best,std::int64_t& bestCost){auto v=objective(n,m,d,fee,c);if(v<bestCost||(v==bestCost&&lexLess(c,best,m))){best=c;bestCost=v;}}
}
extern "C" std::int64_t facility_location_add_delete_swap(const std::int64_t* in,std::size_t len,std::uint8_t* out,std::size_t cap) noexcept{
 if(!in||len<4||len>INPUT)return -1;auto n0=in[0],m0=in[1];if(n0<1||m0<1||n0+m0>8||n0>7||m0>7)return -1;auto n=static_cast<std::size_t>(n0),m=static_cast<std::size_t>(m0),q=n+m;if(len!=2+q*q+m+1)return -1;
 std::int64_t d[T][T]{},fee[M]{};std::size_t p=2;for(std::size_t i=0;i<q;++i)for(std::size_t j=0;j<q;++j){auto v=in[p++];if(v<0||v>1000)return -1;d[i][j]=v;}
 for(std::size_t i=0;i<q;++i){if(d[i][i]!=0)return -1;for(std::size_t j=0;j<q;++j){if(i!=j&&d[i][j]<=0)return -1;if(d[i][j]!=d[j][i])return -1;for(std::size_t k=0;k<q;++k)if(d[i][j]>d[i][k]+d[k][j])return -1;}}
 for(std::size_t j=0;j<m;++j){fee[j]=in[p++];if(fee[j]<0||fee[j]>1000)return -1;}auto raw=in[p];if(raw<=0||static_cast<std::uint64_t>(raw)>=(1ULL<<m))return -1;auto current=static_cast<std::uint32_t>(raw);auto currentCost=objective(n,m,d,fee,current);
 for(std::size_t pass=0;pass<(1U<<m);++pass){auto best=current;auto bestCost=currentCost;for(std::size_t j=0;j<m;++j){auto bit=1U<<j;if(!(current&bit))consider(current|bit,n,m,d,fee,best,bestCost);else if(current&~bit){consider(current&~bit,n,m,d,fee,best,bestCost);for(std::size_t k=0;k<m;++k){auto other=1U<<k;if(!(current&other))consider((current&~bit)|other,n,m,d,fee,best,bestCost);}}}if(bestCost*10>=currentCost*9)break;current=best;currentCost=bestCost;}
 std::size_t count=0;for(std::size_t j=0;j<m;++j)if(current&(1U<<j))++count;auto outBytes=8*(2+n+count);if(!out||cap<outBytes)return -2;put(out,0,currentCost);put(out,8,static_cast<std::int64_t>(count));std::size_t at=16;for(std::size_t j=0;j<m;++j)if(current&(1U<<j)){put(out,at,static_cast<std::int64_t>(j));at+=8;}for(std::size_t u=0;u<n;++u){std::size_t best=0;auto dist=INT64_MAX;for(std::size_t j=0;j<m;++j)if((current&(1U<<j))&&d[u][n+j]<dist){dist=d[u][n+j];best=j;}put(out,at,static_cast<std::int64_t>(best));at+=8;}return static_cast<std::int64_t>(at);
}
