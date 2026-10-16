#include <cmath>
#include <cstddef>
#include <cstdint>
#define INVALID_RESULT (-1.0e300)
extern "C" double simple_neural_network(const std::int64_t *values,std::size_t length){if(values==NULL||length!=3)return INVALID_RESULT;std::int64_t expected=values[0],weight_i=values[1],count=values[2];if(expected<0||expected>100||weight_i<1||weight_i>199||weight_i%2!=1||count<1||count>65536)return INVALID_RESULT;double weight=(double)weight_i,target=(double)expected/100.0,layer=0.0;for(std::int64_t i=0;i<count;i++){layer=1.0/(1.0+std::exp(-0.02*weight));double error=target-layer;double delta=error*layer*(1.0-layer);weight+=0.02*delta;}return layer*100.0;}
