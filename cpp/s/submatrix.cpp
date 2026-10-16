#include <cstddef>
#include <cstdint>
static std::uint64_t feed(std::uint64_t h,std::int64_t x){auto u=static_cast<std::uint64_t>(x);for(unsigned b=0;b<8;++b){h^=static_cast<std::uint8_t>(u>>(8*b));h*=0x100000001b3ULL;}return h;}
extern "C" std::int64_t submatrix(const std::int64_t*v,std::size_t n) noexcept{
 if(!v||n<6||n>70)return -1;auto rows=v[0],cols=v[1],rs=v[2],cs=v[3],nr=v[4],nc=v[5];if(rows<1||rows>8||cols<1||cols>8||rows*cols>64||n!=static_cast<std::size_t>(6+rows*cols))return -1;if(rs<0||rs>rows||cs<0||cs>cols||nr<0||nr>rows||nc<0||nc>cols||rs+nr>rows||cs+nc>cols)return -1;for(std::size_t i=6;i<n;++i)if(v[i]<-2147483648LL||v[i]>2147483647LL)return -1;
 std::uint64_t h=0xcbf29ce484222325ULL;h=feed(h,nr);h=feed(h,nc);for(std::int64_t r=0;r<nr;++r)for(std::int64_t c=0;c<nc;++c)h=feed(h,v[6+(rs+r)*cols+cs+c]);return static_cast<std::int64_t>(h);
}
