#include <cstddef>
#include <cstdint>
extern "C" double ic_555_timer(const std::int64_t*v,std::size_t n){if(!v||n!=4)return -1e300;auto m=v[0],a=v[1],b=v[2],c=v[3];if((m!=0&&m!=1)||a<1||a>1000000||b<1||b>1000000||(m==0&&(c<1||c>1000000))||(m==1&&(c<0||c>1000000)))return -1e300;if(m==0)return (1.44/((a+2*b)*static_cast<double>(c)))*1e6;return (static_cast<double>(a+b)/static_cast<double>(a+2*b))*100.0;}
