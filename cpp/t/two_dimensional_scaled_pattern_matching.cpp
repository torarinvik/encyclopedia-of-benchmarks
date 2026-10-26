// Clean-room fixed-rational-scale geometric 2D pattern matching profile.
#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t max_input=186,max_fields=289; void put(std::uint8_t*o,std::size_t a,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t i=0;i<8;++i){o[a+i]=static_cast<std::uint8_t>(b);b>>=8;}} }
extern "C" std::int64_t two_dimensional_scaled_pattern_matching(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){
 if(!v||n<6||n>max_input)return -1;auto h0=v[0],w0=v[1],ph0=v[2],pw0=v[3],p=v[4],q=v[5];if(h0<1||h0>12||w0<1||w0>12||ph0<1||ph0>6||pw0<1||pw0>6||q<1||q>8||p<q||p>2*q)return -1;
 auto h=static_cast<std::size_t>(h0),w=static_cast<std::size_t>(w0),ph=static_cast<std::size_t>(ph0),pw=static_cast<std::size_t>(pw0);if(n!=6+h*w+ph*pw)return -1;for(std::size_t i=0;i<h*w+ph*pw;++i)if(v[6+i]<0||v[6+i]>255)return -1;
 std::int64_t fields[max_fields]{};std::size_t count=1;
 for(std::size_t r=0;r<h;++r)for(std::size_t c=0;c<w;++c){if(p*static_cast<std::int64_t>(ph)>q*static_cast<std::int64_t>(h-r)||p*static_cast<std::int64_t>(pw)>q*static_cast<std::int64_t>(w-c))continue;bool match=true;
  for(std::size_t y=0;y<h-r&&match;++y){if((2*static_cast<std::int64_t>(y)+1)*q>=2*p*static_cast<std::int64_t>(ph))continue;auto py=static_cast<std::size_t>(((2*static_cast<std::int64_t>(y)+1)*q)/(2*p));
   for(std::size_t x=0;x<w-c;++x){if((2*static_cast<std::int64_t>(x)+1)*q>=2*p*static_cast<std::int64_t>(pw))continue;auto px=static_cast<std::size_t>(((2*static_cast<std::int64_t>(x)+1)*q)/(2*p));if(v[6+(r+y)*w+c+x]!=v[6+h*w+py*pw+px]){match=false;break;}}
  }if(match){fields[count++]=static_cast<std::int64_t>(r);fields[count++]=static_cast<std::int64_t>(c);}}
 fields[0]=static_cast<std::int64_t>((count-1)/2);auto bytes=8*count;if(!out||cap<bytes)return -2;for(std::size_t i=0;i<count;++i)put(out,8*i,fields[i]);return static_cast<std::int64_t>(bytes);
}
