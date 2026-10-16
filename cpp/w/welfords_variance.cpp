#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t MAX_LENGTH=64; constexpr std::int64_t MAX_ABS_VALUE=1'000'000; constexpr double INVALID_RESULT=-1.0e300; }
extern "C" double welfords_variance(const std::int64_t* values,std::size_t length) noexcept {
 if(!values||length<2||length>MAX_LENGTH)return INVALID_RESULT;double mean=0.0,m2=0.0;for(std::size_t i=0;i<length;++i){auto x=values[i];if(x < -MAX_ABS_VALUE||x>MAX_ABS_VALUE)return INVALID_RESULT;double delta=static_cast<double>(x)-mean;mean+=delta/static_cast<double>(i+1);m2+=delta*(static_cast<double>(x)-mean);}return m2/static_cast<double>(length-1);
}
