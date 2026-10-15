#include <cstddef>
#include <cstdint>
namespace { constexpr double scale=1000000.0,invalid=-1.0e300; }
extern "C" double linear_regression_stochastic_gradient_descent(const std::int64_t* v,std::size_t length) noexcept {
 if(!v||length<9||length>133)return invalid;auto n=v[0],epochs=v[1],rate=v[2],m0=v[3],b0=v[4];
 if(n<2||n>64||length!=static_cast<std::size_t>(5+2*n)||epochs<1||epochs>200||rate<1||rate>10000||m0< -10000000||m0>10000000||b0< -10000000||b0>10000000)return invalid;
 for(std::int64_t i=0;i<n;i++){auto x=v[5+2*i],y=v[6+2*i];if(x< -10000000||x>10000000||y< -100000000||y>100000000)return invalid;}
 double alpha=static_cast<double>(rate)/scale,w=static_cast<double>(m0)/scale,b=static_cast<double>(b0)/scale;
 for(std::int64_t epoch=0;epoch<epochs;epoch++)for(std::int64_t i=0;i<n;i++){double x=static_cast<double>(v[5+2*i])/scale,y=static_cast<double>(v[6+2*i])/scale;double error=w*x+b-y;w-=alpha*(error*x/static_cast<double>(n));b-=alpha*(error/static_cast<double>(n));}
 return w;
}
