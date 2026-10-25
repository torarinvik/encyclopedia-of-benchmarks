// Rodinia SRAD v2 kernel profile; source and license provenance: benchmarks/r/rodinia_srad_v2.
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t pixels = 256;
constexpr std::size_t input_count = pixels + 2;
constexpr std::uint32_t lambda_min = 0x3c23d70aU, lambda_max = 0x3dcccccdU;
constexpr std::uint32_t q0_min = 0x3c23d70aU, q0_max = 0x3f800000U;
constexpr std::uint32_t j_min = 0x3f800000U, j_max = 0x3fa00000U;
float from_bits(std::uint32_t bits) { float value; std::memcpy(&value, &bits, sizeof(value)); return value; }
float add32(float a,float b) { volatile float x=a+b; return x; }
float sub32(float a,float b) { volatile float x=a-b; return x; }
float mul32(float a,float b) { volatile float x=a*b; return x; }
float div32(float a,float b) { volatile float x=a/b; return x; }
}

extern "C" std::int64_t rodinia_srad_v2(const std::int64_t* values, std::size_t length) {
    if (values == nullptr || length != input_count) return -1;
    for (std::size_t i=0;i<length;++i) if (values[i]<0 || static_cast<std::uint64_t>(values[i])>UINT32_MAX) return -1;
    const auto lambda_bits=static_cast<std::uint32_t>(values[0]);
    const auto q0_bits=static_cast<std::uint32_t>(values[1]);
    if (lambda_bits<lambda_min || lambda_bits>lambda_max || q0_bits<q0_min || q0_bits>q0_max) return -1;
    const float lambda=from_bits(lambda_bits), q0sqr=from_bits(q0_bits);
    float image[pixels], coeff[pixels], north[pixels], south[pixels], west[pixels], east[pixels];
    for (std::size_t i=0;i<pixels;++i) {
        const auto bits=static_cast<std::uint32_t>(values[i+2]);
        if (bits<j_min || bits>j_max) return -1;
        image[i]=from_bits(bits);
    }
    for (std::size_t row=0;row<16;++row) for (std::size_t col=0;col<16;++col) {
        const std::size_t i=row*16+col;
        const float jc=image[i];
        const float n=sub32(image[(row?row-1:row)*16+col],jc);
        const float s=sub32(image[(row<15?row+1:row)*16+col],jc);
        const float w=sub32(image[row*16+(col?col-1:col)],jc);
        const float e=sub32(image[row*16+(col<15?col+1:col)],jc);
        north[i]=n; south[i]=s; west[i]=w; east[i]=e;
        float gradient=add32(add32(add32(mul32(n,n),mul32(s,s)),mul32(w,w)),mul32(e,e));
        gradient=div32(gradient,mul32(jc,jc));
        const float laplacian=div32(add32(add32(add32(n,s),w),e),jc);
        const float lap_sq=mul32(laplacian,laplacian);
        const float num=static_cast<float>(0.5*static_cast<double>(gradient)-(1.0/16.0)*static_cast<double>(lap_sq));
        float den=static_cast<float>(1.0+0.25*static_cast<double>(laplacian));
        if (den==0.0f) return -1;
        const float qsqr=div32(num,mul32(den,den));
        den=div32(sub32(qsqr,q0sqr),mul32(q0sqr,add32(1.0f,q0sqr)));
        if (den==-1.0f) return -1;
        float c=static_cast<float>(1.0/(1.0+static_cast<double>(den)));
        if (!std::isfinite(c)) return -1;
        coeff[i]=c<0.0f?0.0f:c>1.0f?1.0f:c;
    }
    std::int64_t checksum=0;
    for (std::size_t row=0;row<16;++row) for (std::size_t col=0;col<16;++col) {
        const std::size_t i=row*16+col;
        const float cc=coeff[i];
        const float cs=coeff[(row<15?row+1:row)*16+col];
        const float ce=coeff[row*16+(col<15?col+1:col)];
        const float divergence=add32(add32(add32(mul32(cc,north[i]),mul32(cs,south[i])),mul32(cc,west[i])),mul32(ce,east[i]));
        const float updated=static_cast<float>(static_cast<double>(image[i])+0.25*static_cast<double>(lambda)*static_cast<double>(divergence));
        if (!std::isfinite(updated)||updated<0.0f) return -1;
        checksum+=static_cast<std::int64_t>(static_cast<double>(updated)*1000000.0+0.5);
    }
    return checksum;
}
