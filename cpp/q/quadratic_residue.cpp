#include <cstddef>
#include <cstdint>
static bool is_prime_domain(std::int64_t p){for(auto q:{3,5,7,11,13,17,19,23,29,31,37,41,43,47,53})if(p==q)return true;return false;}
extern "C" std::int64_t quadratic_residue(const std::int64_t* in,std::size_t n) noexcept {if(!in||n!=2)return -1;auto a=in[0],p=in[1];if(!is_prime_domain(p)||a<0||a>=p)return -1;if(a==0)return 0;std::int64_t r=1,b=a,e=(p-1)/2;while(e){if(e&1)r=r*b%p;b=b*b%p;e>>=1;}return r==1?1:-1;}
