#include <cstdint>
#include <cstddef>
#define MAX_SAMPLES 15
extern "C" int64_t ewma_change_detector(const int64_t *v,size_t n){if(!v||n<1||n>MAX_SAMPLES+1)return -1;int64_t count=v[0];if(count<0||count>MAX_SAMPLES||n!=(size_t)count+1)return -1;int64_t exponent=0,numerator=0,packed=0;for(int64_t i=0;i<count;i++){int64_t sample=v[i+1];if(sample < -8||sample>8)return -1;exponent++;numerator+=sample*(INT64_C(1)<<(exponent-1));int64_t signal=0;if(3*numerator*numerator>((INT64_C(1)<<(2*exponent))-1)){signal=numerator>0?1:2;exponent=0;numerator=0;}packed=packed*4+signal;}return packed;}
