#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" int64_t cbench_rsynth_natural_glottal_sample(const double *input, size_t n, double *output, size_t cap) {
    if (!input || n==0 || n>3) return -1;
    for(size_t i=0;i<n;++i) if(!std::isfinite(input[i])) return -1;
    if(n!=2 || input[0]<40.0 || input[0]>263.0 || std::trunc(input[0])!=input[0] ||
       input[1]<0.0 || input[1]>299.0 || std::trunc(input[1])!=input[1]) return -1;
    const long nopen=static_cast<long>(input[0]), index=static_cast<long>(input[1]);
    float result=0.0f;
    if(index<nopen){
        const int b_int=1920000/static_cast<int>(nopen*nopen);
        const float b=static_cast<float>(b_int);
        float a=static_cast<float>(static_cast<float>(b*static_cast<float>(nopen))*0.333);
        float vwave=0.0f;
        for(long nper=0;nper<=index;++nper){a=a-b;vwave=vwave+a;}
        result=static_cast<float>(static_cast<double>(vwave)*0.028);
    }
    if(!output || cap<1) return -2;
    output[0]=static_cast<double>(result); return 1;
}
