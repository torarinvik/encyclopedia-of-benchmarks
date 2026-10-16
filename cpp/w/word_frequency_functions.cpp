#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_term=128,max_text=4096,max_packed=4227;
constexpr std::int64_t max_count=1'000'000;
bool punct(std::uint8_t c){return(c>=33&&c<=47)||(c>=58&&c<=64)||(c>=91&&c<=96)||(c>=123&&c<=126);}
std::uint8_t lower_ascii(std::uint8_t c){return c>='A'&&c<='Z'?static_cast<std::uint8_t>(c+32):c;}
void put32(std::uint8_t*out,std::size_t&p,std::uint32_t x){for(int i=0;i<4;i++){out[p++]=static_cast<std::uint8_t>(x);x>>=8;}}
void put64(std::uint8_t*out,std::size_t&p,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(int i=0;i<8;i++){out[p++]=static_cast<std::uint8_t>(b);b>>=8;}}
std::int64_t milli(double x){const double y=x*1000.0,lo=std::floor(y),f=y-lo;if(f<0.5)return static_cast<std::int64_t>(lo);if(f>0.5)return static_cast<std::int64_t>(lo+1.0);const auto k=static_cast<std::int64_t>(lo);return k%2==0?k:k+1;}
}

extern "C" std::int64_t word_frequency_functions(const std::int64_t*in,std::size_t length,std::uint8_t*out,std::size_t capacity) noexcept {
    if(!in||length<1||length>max_packed)return -1;
    const auto op=in[0];std::int64_t kind=0,a=0,b=0;std::size_t outlen=12;
    if(op==0||op==1){
        if(length<3||in[1]<0||in[1]>static_cast<std::int64_t>(max_term))return -1;
        const auto tn=static_cast<std::size_t>(in[1]),ti=2+tn;
        if(length<ti+1||in[ti]<0||in[ti]>static_cast<std::int64_t>(max_text))return -1;
        const auto dn=static_cast<std::size_t>(in[ti]),di=ti+1;if(length!=di+dn)return -1;
        std::uint8_t term[max_term],text[max_text],clean[max_text];
        for(std::size_t i=0;i<tn;i++){if(in[2+i]<0||in[2+i]>127)return -1;term[i]=lower_ascii(static_cast<std::uint8_t>(in[2+i]));}
        for(std::size_t i=0;i<dn;i++){if(in[di+i]<0||in[di+i]>127)return -1;text[i]=static_cast<std::uint8_t>(in[di+i]);}
        std::size_t cn=0;for(std::size_t i=0;i<dn;i++)if(!punct(text[i])&&(op!=0||text[i]!=10))clean[cn++]=op==1?lower_ascii(text[i]):text[i];
        if(op==0){std::size_t start=0;for(std::size_t i=0;i<=cn;i++)if(i==cn||clean[i]==32){const auto n=i-start;bool same=n==tn;for(std::size_t j=0;same&&j<n;j++)if(lower_ascii(clean[start+j])!=term[j])same=false;if(same)++a;start=i+1;}kind=0;}
        else{kind=1;outlen=20;std::size_t start=0;for(std::size_t i=0;i<=cn;i++)if(i==cn||clean[i]==10){const auto n=i-start;bool found=tn==0;for(std::size_t j=0;!found&&j+tn<=n;j++){std::size_t k=0;while(k<tn&&clean[start+j+k]==term[k])++k;if(k==tn)found=true;}if(found)++a;++b;start=i+1;}}
    }else if(op==2){
        if(length!=4)return -1;const auto df=in[1],n=in[2],smooth=in[3];
        if(df<0||df>max_count||n<0||n>max_count||(smooth!=0&&smooth!=1))return -1;
        if(smooth&&n==0){kind=4;outlen=4;}else if(!smooth&&df==0){kind=3;outlen=4;}else if(!smooth&&n==0){kind=4;outlen=4;}
        else{const double value=smooth?1.0+std::log10(static_cast<double>(n)/static_cast<double>(1+df)):std::log10(static_cast<double>(n)/static_cast<double>(df));kind=2;a=milli(value);}
    }else if(op==3){if(length!=3||in[1]<0||in[1]>max_count||in[2]<-max_count||in[2]>max_count)return -1;kind=2;a=in[1]*in[2];}
    else return -1;
    if(!out||capacity<outlen)return -2;std::size_t p=0;put32(out,p,static_cast<std::uint32_t>(kind));
    if(kind==0||kind==2)put64(out,p,a);else if(kind==1){put64(out,p,a);put64(out,p,b);}return static_cast<std::int64_t>(p);
}
