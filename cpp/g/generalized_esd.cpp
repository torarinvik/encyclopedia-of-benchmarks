#include <cstddef>
#include <cstdint>
#include <cmath>
namespace { constexpr double critical[9]={0,0,0,1.1543048513440384,1.48125,1.715037312343363,1.887145117783933,2.0199685076795957,2.126645087195462}; }
extern "C" std::int64_t generalized_esd(const std::int64_t *v,std::size_t length) noexcept {
 if(!v||length<5)return -1; auto n=v[0],limit=v[1];
 if(n<3||n>8||limit<1||limit>3||limit>n-2||length!=static_cast<std::size_t>(n)+2)return -1;
 double x[8];int idx[8];for(int i=0;i<n;i++){if(v[i+2]<-10000||v[i+2]>10000)return -1;x[i]=static_cast<double>(v[i+2]);idx[i]=i;}
 int remaining=static_cast<int>(n),accepted=0,removed[3]={0};
 for(int step=1;step<=limit;step++){double mean=0;for(int i=0;i<remaining;i++)mean+=x[i];mean/=remaining;double ss=0;for(int i=0;i<remaining;i++){double d=x[i]-mean;ss+=d*d;}double sd=std::sqrt(ss/(remaining-1));if(sd==0)break;int worst=0;double largest=-1;for(int i=0;i<remaining;i++){double d=std::abs(x[i]-mean);if(d>largest){largest=d;worst=i;}}removed[step-1]=idx[worst];if(largest/sd>critical[remaining])accepted=step;remaining--;x[worst]=x[remaining];idx[worst]=idx[remaining];}
 std::int64_t mask=0;for(int i=0;i<accepted;i++)mask|=INT64_C(1)<<removed[i];return mask;
}
