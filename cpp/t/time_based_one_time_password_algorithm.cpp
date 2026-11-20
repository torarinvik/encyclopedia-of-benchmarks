#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_key=64, max_words=67, out_bytes=6;
std::uint32_t rol(std::uint32_t x,unsigned n){return (x<<n)|(x>>(32u-n));}
void compress(std::array<std::uint32_t,5>& h,const std::array<std::uint8_t,64>& block){
    std::array<std::uint32_t,80>w{};
    for(std::size_t i=0;i<16;++i){const auto j=4*i;w[i]=(std::uint32_t(block[j])<<24)|(std::uint32_t(block[j+1])<<16)|(std::uint32_t(block[j+2])<<8)|block[j+3];}
    for(std::size_t i=16;i<80;++i)w[i]=rol(w[i-3]^w[i-8]^w[i-14]^w[i-16],1);
    auto a=h[0],b=h[1],c=h[2],d=h[3],e=h[4];
    for(std::size_t i=0;i<80;++i){std::uint32_t f,k;if(i<20){f=(b&c)|(~b&d);k=0x5a827999u;}else if(i<40){f=b^c^d;k=0x6ed9eba1u;}else if(i<60){f=(b&c)|(b&d)|(c&d);k=0x8f1bbcdcu;}else{f=b^c^d;k=0xca62c1d6u;}const auto t=rol(a,5)+f+e+k+w[i];e=d;d=c;c=rol(b,30);b=a;a=t;}
    h[0]+=a;h[1]+=b;h[2]+=c;h[3]+=d;h[4]+=e;
}
void reset(std::array<std::uint32_t,5>&h){h={0x67452301u,0xefcdab89u,0x98badcfeu,0x10325476u,0xc3d2e1f0u};}
void serialize(const std::array<std::uint32_t,5>&h,std::array<std::uint8_t,20>&out){for(std::size_t i=0;i<5;++i){out[4*i]=std::uint8_t(h[i]>>24);out[4*i+1]=std::uint8_t(h[i]>>16);out[4*i+2]=std::uint8_t(h[i]>>8);out[4*i+3]=std::uint8_t(h[i]);}}
void compute(const std::int64_t* in,std::size_t key_len,std::array<std::uint8_t,6>&out){
    std::array<std::uint8_t,64> key{},block{};std::array<std::uint8_t,20> inner{};std::array<std::uint32_t,5>h{};
    for(std::size_t i=0;i<key_len;++i)key[i]=std::uint8_t(in[i+1]);
    for(std::size_t i=0;i<64;++i)block[i]=std::uint8_t(key[i]^0x36u);
    reset(h);compress(h,block);block.fill(0);
    const auto counter=std::uint64_t(in[key_len+1])/30u;for(std::size_t i=0;i<8;++i)block[i]=std::uint8_t(counter>>(56-8*i));
    block[8]=0x80;block[62]=0x02;block[63]=0x40;compress(h,block);serialize(h,inner);
    for(std::size_t i=0;i<64;++i)block[i]=std::uint8_t(key[i]^0x5cu);
    reset(h);compress(h,block);block.fill(0);for(std::size_t i=0;i<20;++i)block[i]=inner[i];
    block[20]=0x80;block[62]=0x02;block[63]=0xa0;compress(h,block);serialize(h,inner);
    const auto off=std::size_t(inner[19]&15u);std::uint32_t bin=(std::uint32_t(inner[off])<<24)|(std::uint32_t(inner[off+1])<<16)|(std::uint32_t(inner[off+2])<<8)|inner[off+3];
    auto value=(bin&0x7fffffffu)%1000000u;for(int i=5;i>=0;--i){out[std::size_t(i)]=std::uint8_t('0'+value%10u);value/=10u;}
}
}

extern "C" std::int64_t time_based_one_time_password_algorithm(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
    if(input==nullptr||length<3||length>max_words)return -1;const auto kw=input[0];if(kw<16||kw>std::int64_t(max_key)||length!=std::size_t(kw)+2)return -1;
    const auto n=std::size_t(kw);for(std::size_t i=0;i<n;++i)if(input[i+1]<0||input[i+1]>255)return -1;if(input[n+1]<0)return -1;
    std::array<std::uint8_t,out_bytes> staged{};compute(input,n,staged);if(output==nullptr||capacity<out_bytes)return -2;for(std::size_t i=0;i<out_bytes;++i)output[i]=staged[i];return out_bytes;
}
