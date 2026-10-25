#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t N=8, Z=64, IN=164, OUT=36;
float decode(std::int64_t x){ return static_cast<float>(x)/1000000.0f; }
void put32(std::uint8_t*p,std::uint32_t x){p[0]=x;p[1]=x>>8;p[2]=x>>16;p[3]=x>>24;}
}
extern "C" std::int64_t parboil_spmv_jds(const std::int64_t* in,std::size_t len,std::uint8_t*out,std::size_t cap){
 if(!in||len<3||len>IN||in[0]<1||in[0]>8||in[1]<1||in[1]>8||in[2]<1||in[2]>64)return -1;
 auto n=std::size_t(in[0]),d=std::size_t(in[1]),z=std::size_t(in[2]); if(len!=4+3*n+d+2*z)return -1;
 std::int64_t row[N],perm[N],ptr[N+1],col[Z],dat[Z],vec[N]; std::size_t p=3;
 for(std::size_t i=0;i<n;i++){if(in[p]<0||in[p]>std::int64_t(d))return -1;row[i]=in[p++];}
 if(row[0]!=std::int64_t(d))return -1;for(std::size_t i=1;i<n;i++)if(row[i]>row[i-1])return -1;
 for(std::size_t i=0;i<n;i++)perm[i]=in[p++];for(std::size_t i=0;i<n;i++){if(perm[i]<0||perm[i]>=std::int64_t(n))return -1;for(std::size_t j=0;j<i;j++)if(perm[j]==perm[i])return -1;}
 for(std::size_t k=0;k<=d;k++)ptr[k]=in[p++];for(std::size_t j=0;j<z;j++)col[j]=in[p++];for(std::size_t j=0;j<z;j++)dat[j]=in[p++];for(std::size_t i=0;i<n;i++)vec[i]=in[p++];
 std::size_t prefix=0; if(ptr[0]!=0)return -1;for(std::size_t k=0;k<d;k++){std::size_t count=0;for(std::size_t i=0;i<n;i++)if(row[i]>std::int64_t(k))count++;prefix+=count;if(ptr[k+1]!=std::int64_t(prefix))return -1;}if(prefix!=z)return -1;
 for(std::size_t j=0;j<z;j++)if(col[j]<0||col[j]>=std::int64_t(n)||dat[j]<-1000000||dat[j]>1000000)return -1;for(std::size_t i=0;i<n;i++)if(vec[i]<-1000000||vec[i]>1000000)return -1;
 if(!out||cap<4+4*n)return -2;float y[N]{};std::uint8_t stage[OUT]{};
 for(std::size_t i=0;i<n;i++){float acc=0;for(std::size_t k=0;k<std::size_t(row[i]);k++){auto j=std::size_t(ptr[k])+i;float prod=decode(dat[j])*decode(vec[std::size_t(col[j])]);acc=acc+prod;}y[std::size_t(perm[i])]=acc;}
 put32(stage,std::uint32_t(n));for(std::size_t i=0;i<n;i++){std::uint32_t bits;std::memcpy(&bits,&y[i],4);put32(stage+4+4*i,bits);}std::memcpy(out,stage,4+4*n);return 4+4*n;
}
