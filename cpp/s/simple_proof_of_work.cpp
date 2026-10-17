#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_INPUT=4096, MAX_PADDED=4160;
constexpr std::uint32_t K[64]={
0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
std::uint32_t rotr(std::uint32_t x,unsigned n){return (x>>n)|(x<<(32-n));}
}

static std::int64_t proof_of_work_hash(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity) noexcept {
 if(length>MAX_INPUT||(length>0&&input==nullptr))return -1;
 for(std::size_t i=0;i<length;++i)if(input[i]<0||input[i]>255)return -1;
 std::uint8_t padded[MAX_PADDED]{};for(std::size_t i=0;i<length;++i)padded[i]=static_cast<std::uint8_t>(input[i]);padded[length]=0x80;
 const std::size_t blocks=(length+9+63)/64,padded_length=blocks*64;const std::uint64_t bit_length=static_cast<std::uint64_t>(length)*8;
 for(std::size_t i=0;i<8;++i)padded[padded_length-1-i]=static_cast<std::uint8_t>(bit_length>>(8*i));
 std::uint32_t h[8]={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
 for(std::size_t block=0;block<blocks;++block){std::uint32_t w[64];
  for(std::size_t i=0;i<16;++i){const std::size_t p=block*64+i*4;w[i]=(std::uint32_t(padded[p])<<24)|(std::uint32_t(padded[p+1])<<16)|(std::uint32_t(padded[p+2])<<8)|padded[p+3];}
  for(std::size_t i=16;i<64;++i){const std::uint32_t x=w[i-15],y=w[i-2];const std::uint32_t s0=rotr(x,7)^rotr(x,18)^(x>>3),s1=rotr(y,17)^rotr(y,19)^(y>>10);w[i]=s1+w[i-7]+s0+w[i-16];}
  std::uint32_t a=h[0],b=h[1],c=h[2],d=h[3],e=h[4],f=h[5],g=h[6],hh=h[7];
  for(std::size_t i=0;i<64;++i){const std::uint32_t s1=rotr(e,6)^rotr(e,11)^rotr(e,25),ch=(e&f)^(~e&g),t1=hh+s1+ch+K[i]+w[i],s0=rotr(a,2)^rotr(a,13)^rotr(a,22),maj=(a&b)^(a&c)^(b&c),t2=s0+maj;hh=g;g=f;f=e;e=d+t1;d=c;c=b;b=a;a=t1+t2;}
  h[0]+=a;h[1]+=b;h[2]+=c;h[3]+=d;h[4]+=e;h[5]+=f;h[6]+=g;h[7]+=hh;
 }
 if(output==nullptr||capacity<32)return -2;
 for(std::size_t i=0;i<8;++i)for(std::size_t byte=0;byte<4;++byte)output[i*4+byte]=static_cast<std::uint8_t>(h[i]>>(24-8*byte));
 return 32;
}


namespace {
constexpr std::size_t HEADER=5,MAX_VALUES=134,MAX_FIELD=64,MAX_NONCE=4096;
std::size_t append_decimal(std::int64_t*out,std::size_t pos,std::uint64_t v){std::uint8_t d[20];std::size_t n=0;do{d[n++]=static_cast<std::uint8_t>('0'+v%10);v/=10;}while(v);while(n)out[pos++]=d[--n];return pos;}
bool zero_prefix(const std::uint8_t*d,std::int64_t x){for(std::int64_t i=0;i<x;++i){auto b=d[static_cast<std::size_t>(i)/2];if((i%2==0?b>>4:b&15)!=0)return false;}return true;}
}
extern "C" std::int64_t simple_proof_of_work(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity) noexcept {
 if(!input||length<HEADER||length>MAX_VALUES)return -1;auto block=input[0],difficulty=input[1],maxn=input[2],tl=input[3],pl=input[4];if(block<0||difficulty<0||difficulty>2||maxn<0||maxn>MAX_NONCE||tl<0||tl>MAX_FIELD||pl<0||pl>MAX_FIELD)return -1;if(length!=HEADER+std::size_t(tl)+std::size_t(pl))return -1;
 auto tx=input+HEADER;auto prev=tx+tl;for(std::size_t i=0;i<std::size_t(tl);++i)if(tx[i]<0||tx[i]>127)return -1;for(std::size_t i=0;i<std::size_t(pl);++i)if(prev[i]<0||prev[i]>127)return -1;if(!output||capacity<72)return -2;static constexpr char hex[]="0123456789abcdef";
 for(std::uint64_t nonce=0;nonce<=std::uint64_t(maxn);++nonce){std::int64_t m[151];std::size_t n=append_decimal(m,0,std::uint64_t(block));for(std::size_t i=0;i<std::size_t(tl);++i)m[n++]=tx[i];for(std::size_t i=0;i<std::size_t(pl);++i)m[n++]=prev[i];n=append_decimal(m,n,nonce);std::uint8_t d[32];if(proof_of_work_hash(m,n,d,32)!=32)return -1;if(zero_prefix(d,difficulty)){for(std::size_t i=0;i<8;++i)output[i]=std::uint8_t(nonce>>(8*i));for(std::size_t i=0;i<32;++i){output[8+2*i]=hex[d[i]>>4];output[9+2*i]=hex[d[i]&15];}return 72;}}return -3;
}
