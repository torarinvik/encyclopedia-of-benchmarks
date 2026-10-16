#include <array>
#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t max_window=8, max_series=16; constexpr double invalid=-1.0e300; }
extern "C" double fractional_differentiation(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length < 4 || length > 18) return invalid;
    const auto d_units=values[0], window=values[1]; const std::size_t count=length-2;
    if (d_units<0 || d_units>1000000 || window<1 || window>static_cast<std::int64_t>(max_window) || count<=static_cast<std::size_t>(window) || count>max_series) return invalid;
    for(std::size_t i=0;i<count;++i) if(values[i+2]<-1000000 || values[i+2]>1000000) return invalid;
    const double d=static_cast<double>(d_units)/1000000.0; std::array<double,max_window> weights{}; weights[0]=1.0;
    for(std::size_t k=1;k<static_cast<std::size_t>(window);++k) weights[k]=-weights[k-1]*(d-static_cast<double>(k)+1.0)/static_cast<double>(k);
    double result=0.0; for(std::size_t j=0;j<static_cast<std::size_t>(window);++j) result+=weights[j]*(static_cast<double>(values[2+count-1-j])/1000.0);
    return result;
}
