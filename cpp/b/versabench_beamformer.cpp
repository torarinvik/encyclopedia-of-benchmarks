#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
float add32(float a, float b) { volatile float r = a + b; return r; }
float sub32(float a, float b) { volatile float r = a - b; return r; }
float mul32(float a, float b) { volatile float r = a * b; return r; }
}
extern "C" std::int64_t versabench_beamformer(const double *input, std::size_t length,
                                               double *output, std::size_t capacity) {
    if (input == nullptr || length != 48) return -1;
    float v[48];
    for (std::size_t i=0;i<48;++i) { if (!std::isfinite(input[i]) || input[i]<-128.0 || input[i]>128.0) return -1; v[i]=static_cast<float>(input[i]); }
    float real=0.0f, imag=0.0f;
    for(std::size_t c=0;c<12;++c){const auto b=4*c;const float rr=sub32(mul32(v[b],v[b+2]),mul32(v[b+1],v[b+3]));const float ii=add32(mul32(v[b],v[b+3]),mul32(v[b+1],v[b+2]));real=add32(real,rr);imag=add32(imag,ii);}
    if(output==nullptr||capacity<2)return -2;output[0]=static_cast<double>(real);output[1]=static_cast<double>(imag);return 2;
}
