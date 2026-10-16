#include <cstddef>
#include <cstdint>
namespace { constexpr std::int64_t SCALE=1'000'000, MAX_COUNT=64, MAX_PARSED_COUNT=65, MAX_SAMPLE=1'000'000'000, MAX_DELTA=1'000'000'000; constexpr std::size_t MAX_INPUT_LENGTH=133; constexpr double INVALID_RESULT=-1.0e300; }
extern "C" double huber_loss_math(const std::int64_t* v,std::size_t n) noexcept {
 if(v==nullptr||n<3||n>MAX_INPUT_LENGTH)return INVALID_RESULT;
 auto d=v[0],ac=v[1],pc=v[2];
 if(d<0||d>MAX_DELTA||ac<0||ac>MAX_PARSED_COUNT||pc<0||pc>MAX_PARSED_COUNT||n!=static_cast<std::size_t>(3+ac+pc)||ac>MAX_COUNT||pc>MAX_COUNT)return INVALID_RESULT;
 auto a=static_cast<std::size_t>(ac),p=static_cast<std::size_t>(pc);
 for(std::size_t i=0;i<a+p;++i)if(v[3+i]<-MAX_SAMPLE||v[3+i]>MAX_SAMPLE)return INVALID_RESULT;
 double delta=static_cast<double>(d)/SCALE,total=0.0; auto pairs=a<p?a:p;
 for(std::size_t i=0;i<pairs;++i){double diff=static_cast<double>(v[3+i])/SCALE-static_cast<double>(v[3+a+i])/SCALE;double residual=diff<0.0?-diff:diff;if(residual<=delta)total+=0.5*(diff*diff);else total+=delta*residual-0.5*delta;}
 return total;
}
