#include <cstddef>
#include <cstdint>
extern "C" double half_wave_rectifier(const std::int64_t*a,std::size_t n){constexpr double bad=-1.0e300;if(!a||n!=5)return bad;for(std::size_t i=1;i<5;i++)if(a[i]<-1000000||a[i]>1000000)return bad;switch(a[0]){case 0:if(a[1]<0||a[2]<0||a[3]<0||(a[1]==0&&a[2]==0&&a[3]==0))return bad;return double(a[4])/double(a[1]+a[2]+a[3]);case 1:case 2:if(a[2]||a[3]||a[4])return bad;return double(a[1])*0.318;case 3:if(a[2]<=0||a[3]||a[4])return bad;return double(a[1])/double(a[2]);case 4:case 5:if(a[2]||a[3]||a[4])return bad;return double(a[1])/2.0;default:return bad;}}
