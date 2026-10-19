#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_OPS=8, MAX_INPUT=1+13*MAX_OPS, MAX_OUTPUT=12*MAX_OPS;
struct IFPF { std::uint8_t type,sign; std::int16_t exp; std::uint64_t mant; };
void sticky_right(IFPF& v,unsigned n){while(n--){auto lost=v.mant&1u;v.mant>>=1;if(lost)v.mant|=1u;}}
void round_result(IFPF& v){if(v.type==2)v.mant&=~std::uint64_t(7);}
void normalize(IFPF& v){while((v.mant>>63)==0){v.mant<<=1;--v.exp;}}
IFPF add_sub(IFPF x,IFPF y,unsigned op){
 IFPF z{2,x.sign,x.exp,0};int d=int(x.exp)-int(y.exp);
 if(d>0)sticky_right(y,unsigned(d));else if(d<0){sticky_right(x,unsigned(-d));z.sign=y.sign^op;z.exp=y.exp;}
 if(x.sign^y.sign^op){z.mant=x.mant-y.mant;if(x.mant<y.mant){z.sign=y.sign^op;z.mant=y.mant-x.mant;}if(z.mant==0){z.type=0;z.sign=0;}else normalize(z);}
 else{z.mant=x.mant+y.mant;if(z.mant<x.mant){++z.exp;z.mant=(z.mant>>1)|UINT64_C(0x8000000000000000);}}
 round_result(z);return z;
}
IFPF multiply(IFPF x,IFPF y){
 IFPF z{2,std::uint8_t(x.sign^y.sign),std::int16_t(x.exp+y.exp),0};std::uint64_t high=0,low=0,mult=y.mant;
 for(unsigned i=0;i<64;++i){std::uint64_t carry=0;if(mult&1u){auto old=high;high+=x.mant;carry=high<old;}mult>>=1;auto outgoing=high&1u;high=(high>>1)|(carry<<63);low=(low>>1)|(outgoing<<63);}
 while((high>>63)==0){auto carry=low>>63;low<<=1;high=(high<<1)|carry;--z.exp;}if(low==0)high|=1u;z.mant=high;round_result(z);return z;
}
IFPF divide_emulated(IFPF x,IFPF y){
 IFPF z{2,std::uint8_t(x.sign^y.sign),std::int16_t(x.exp-y.exp+128),0};auto dividend=x.mant;std::uint64_t rem=0;
 while((z.mant>>63)==0){auto carry=dividend>>63;dividend<<=1;auto overflow=rem>>63;rem=(rem<<1)|carry;std::uint64_t bit=0;if(overflow||rem>=y.mant){rem-=y.mant;bit=1;}z.mant=(z.mant<<1)|bit;--z.exp;}
 round_result(z);return z;
}
}
extern "C" std::int64_t nbench_emulated_float_arithmetic(const std::int64_t* in,std::size_t len,std::uint8_t* out,std::size_t cap){
 if(!in||len<14||len>MAX_INPUT+1)return -1;auto count=in[0];if(count<1||count>MAX_OPS||len!=1+13*std::size_t(count))return -1;
 IFPF result[MAX_OPS]{};
 for(std::size_t i=0;i<std::size_t(count);++i){auto p=1+13*i;auto op=in[p],sx=in[p+1],ex=in[p+2],sy=in[p+7],ey=in[p+8];if(op<0||op>3||sx<0||sx>1||sy<0||sy>1||ex< -8||ex>8||ey< -8||ey>8)return -1;std::uint64_t mx=0,my=0;
  for(std::size_t j=0;j<4;++j){auto a=in[p+3+j],b=in[p+9+j];if(a<0||a>65535||b<0||b>65535)return -1;mx=(mx<<16)|std::uint16_t(a);my=(my<<16)|std::uint16_t(b);}if((mx>>63)==0||(my>>63)==0)return -1;
  IFPF x{2,std::uint8_t(sx),std::int16_t(ex),mx},y{2,std::uint8_t(sy),std::int16_t(ey),my};
  result[i]=op==0?add_sub(x,y,0):op==1?add_sub(x,y,1):op==2?multiply(x,y):divide_emulated(x,y);
  if(result[i].type==2&&(result[i].exp< -80||result[i].exp>32||(result[i].mant>>63)==0))return -1;
 }
 auto bytes=std::size_t(count)*12;if(!out||cap<bytes)return -2;
 for(std::size_t i=0;i<std::size_t(count);++i){auto v=result[i];auto p=12*i;out[p]=v.type;out[p+1]=v.sign;auto e=std::uint16_t(v.exp);out[p+2]=std::uint8_t(e);out[p+3]=std::uint8_t(e>>8);for(std::size_t j=0;j<4;++j){auto w=std::uint16_t(v.mant>>(48-16*j));out[p+4+2*j]=std::uint8_t(w);out[p+5+2*j]=std::uint8_t(w>>8);}}
 return std::int64_t(bytes);
}
