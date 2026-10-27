#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_FACETS=16,MAX_VERTICES=12;
void put_i64(std::uint8_t*out,std::size_t word,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b)out[word*8+b]=static_cast<std::uint8_t>(bits>>(8*b));}
bool less_tri(const int a[3],const int b[3]){for(int i=0;i<3;++i){if(a[i]<b[i])return true;if(a[i]>b[i])return false;}return false;}
bool equal_tri(const int a[3],const int b[3]){return a[0]==b[0]&&a[1]==b[1]&&a[2]==b[2];}
}
extern "C" std::int64_t crust_pole_triangle_filter(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
 if(input==nullptr||length<3||length>51)return -1;auto ns0=input[0],np0=input[1],nf0=input[2];
 if(ns0<3||ns0>8||np0<1||np0>4||ns0+np0>MAX_VERTICES||nf0<0||nf0>MAX_FACETS||length!=3+3*static_cast<std::size_t>(nf0))return -1;
 int ns=static_cast<int>(ns0),total=static_cast<int>(ns0+np0),nf=static_cast<int>(nf0),facets[MAX_FACETS][3]{},count=0;
 for(int i=0;i<nf;++i){auto a0=input[3+3*i],b0=input[4+3*i],c0=input[5+3*i];if(a0<0||a0>=total||b0<0||b0>=total||c0<0||c0>=total||a0==b0||a0==c0||b0==c0)return -1;if(a0>=ns||b0>=ns||c0>=ns)continue;
  int t[3]={static_cast<int>(a0),static_cast<int>(b0),static_cast<int>(c0)};for(int a=1;a<3;++a){int x=t[a],j=a;while(j>0&&t[j-1]>x){t[j]=t[j-1];--j;}t[j]=x;}bool duplicate=false;for(int j=0;j<count;++j)if(equal_tri(t,facets[j]))duplicate=true;if(!duplicate){for(int j=0;j<3;++j)facets[count][j]=t[j];++count;}
 }
 for(int i=1;i<count;++i){int t[3]={facets[i][0],facets[i][1],facets[i][2]},j=i;while(j>0&&less_tri(t,facets[j-1])){for(int z=0;z<3;++z)facets[j][z]=facets[j-1][z];--j;}for(int z=0;z<3;++z)facets[j][z]=t[z];}
 const auto bytes=static_cast<std::size_t>(1+3*count)*8;if(output==nullptr||capacity<bytes)return -2;put_i64(output,0,count);std::size_t at=1;for(int i=0;i<count;++i)for(int j=0;j<3;++j)put_i64(output,at++,facets[i][j]);return static_cast<std::int64_t>(bytes);
}
