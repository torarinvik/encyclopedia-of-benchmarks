#include <cstddef>
#include <cstdint>
#include <cstring>
#include <cmath>
static void putd(std::uint8_t*o,std::size_t p,double x){std::uint64_t b;std::memcpy(&b,&x,8);for(int k=0;k<8;k++)o[p+k]=std::uint8_t(b>>(8*k));}
extern "C" std::int64_t neural_network(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){if(!v||n<7)return -1;int ni=int(v[0]),nh=int(v[1]),no=int(v[2]);if(ni<1||ni>3||nh<1||nh>3||no<1||no>3||n!=3+std::size_t(ni)+std::size_t(ni)*nh+std::size_t(nh)*no)return -1;for(std::size_t i=3;i<n;i++)if(v[i]<-1000||v[i]>1000)return -1;if(!out||cap<std::size_t(no)*8)return -2;std::size_t x=3,w1=x+ni,w2=w1+std::size_t(ni)*nh;double h[3];for(int j=0;j<nh;j++){double z=0;for(int i=0;i<ni;i++)z+=double(v[x+i])/1000.*(double(v[w1+std::size_t(i)*nh+j])/1000.);h[j]=1./(1.+std::exp(-z));}for(int j=0;j<no;j++){double z=0;for(int i=0;i<nh;i++)z+=h[i]*(double(v[w2+std::size_t(i)*no+j])/1000.);putd(out,std::size_t(j)*8,1./(1.+std::exp(-z)));}return no*8;}
