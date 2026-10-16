#include <cmath>
#include <cstddef>
#include <cstdint>
namespace { constexpr double bad=-1.0e300; double fact(std::int64_t n){double f=1;for(std::int64_t i=2;i<=n;++i)f*=double(i);return f;} double term(std::int64_t m,double x,std::int64_t i){std::int64_t e;double s=1;if(m==0)e=i;else if(m==1){e=2*i+1;if(i%2)s=-1;}else{e=2*i;if(i%2)s=-1;}return m==0?std::pow(x,double(e))/fact(e):s/fact(e)*std::pow(x,double(e));} }
extern "C" double maclaurin(const std::int64_t*v,std::size_t n) noexcept {
 if(!v||n!=3)return bad;auto m=v[0],xm=v[1],em=v[2];if(m<0||m>2||xm< -2000||xm>2000||em<1||em>250)return bad;
 double x=double(xm)/1000.0,error=double(em)/1000.0,coefficient=0,result=0;
 for(std::int64_t i=0;i<32;++i){result+=coefficient;coefficient=term(m,x,i);if(std::abs(coefficient)<=error)return result;}return bad;
}
