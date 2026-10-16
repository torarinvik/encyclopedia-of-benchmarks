#include <cstddef>
#include <cstdint>
static bool is_prime(std::int64_t n) { if(n<2)return false; for(std::int64_t d=2;d*d<=n;++d)if(n%d==0)return false;return true; }
static std::int64_t modpow(std::int64_t b,std::int64_t e,std::int64_t p){std::int64_t r=1%p;while(e){if(e&1)r=r*b%p;b=b*b%p;e>>=1;}return r;}
extern "C" std::int64_t diffie_hellman(const std::int64_t* v,std::size_t n){if(!v||n!=4)return -1;auto g=v[0],a=v[1],b=v[2],p=v[3];if(p<2||p>6700417||!is_prime(p)||g<1||g>=p||a<1||a>=p||b<1||b>=p)return -1;return modpow(modpow(g,a,p),b,p);}
