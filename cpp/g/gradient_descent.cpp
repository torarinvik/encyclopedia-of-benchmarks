#include <cstddef>
#include <cstdint>
extern "C" double gradient_descent(const std::int64_t *v, std::size_t n) noexcept {
 constexpr double invalid=-1.0e300; constexpr std::int64_t max_dim=64;
 if(!v || n<5 || n>68) return invalid; auto d=v[0], selected=v[1], rate=v[2], iterations=v[3];
 if(d<1 || d>max_dim || selected<0 || selected>=d || n!=static_cast<std::size_t>(4+d) || rate<1 || rate>500000 || iterations<0 || iterations>10000) return invalid;
 double x[64]; for(std::int64_t i=0;i<d;i++){if(v[4+i]<-10 || v[4+i]>10)return invalid; x[i]=static_cast<double>(v[4+i]);}
 const double alpha=static_cast<double>(rate)/1000000.0;
 for(std::int64_t k=0;k<iterations;k++){double g[64];for(std::int64_t i=0;i<d;i++)g[i]=2.0*x[i];for(std::int64_t i=0;i<d;i++)x[i]-=alpha*g[i];}
 return x[selected];
}
