#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t MaxText=32,MaxPattern=8,MaxInput=43,Alphabet=5;
bool less_suffix(const std::int64_t* s,std::size_t n,std::size_t a,std::size_t b){while(a<n&&b<n){if(s[a]!=s[b])return s[a]<s[b];++a;++b;}return a==n&&b!=n;}
void store(std::uint8_t* out,std::size_t off,std::int64_t v){auto bits=static_cast<std::uint64_t>(v);for(std::size_t b=0;b<8;++b){out[off+b]=static_cast<std::uint8_t>(bits&255U);bits>>=8;}}
}
extern "C" std::int64_t fm_index_locate(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity) noexcept{
 if(!input||length<5||length>MaxInput)return -1;auto n64=input[0];if(n64<1||n64>MaxText||length<static_cast<std::size_t>(n64)+4)return -1;
 auto n=static_cast<std::size_t>(n64),m_at=n+1;auto m64=input[m_at];if(m64<1||m64>MaxPattern||length!=m_at+1+static_cast<std::size_t>(m64)+1)return -1;
 auto m=static_cast<std::size_t>(m64);auto stride64=input[length-1];if(stride64<1||stride64>n64)return -1;auto stride=static_cast<std::size_t>(stride64),N=n+1;
 std::int64_t s[MaxText+1]{},pattern[MaxPattern]{};for(std::size_t i=0;i<n;++i){auto x=input[1+i];if(x<1||x>4)return -1;s[i]=x;}for(std::size_t i=0;i<m;++i){auto x=input[m_at+1+i];if(x<1||x>4)return -1;pattern[i]=x;}s[n]=0;
 std::size_t sa[MaxText+1]{};for(std::size_t i=0;i<N;++i)sa[i]=i;for(std::size_t i=1;i<N;++i){auto key=sa[i],j=i;while(j>0&&less_suffix(s,N,key,sa[j-1])){sa[j]=sa[j-1];--j;}sa[j]=key;}
 std::int64_t bwt[MaxText+1]{};std::size_t freq[Alphabet]{};for(std::size_t i=0;i<N;++i){bwt[i]=s[(sa[i]+N-1)%N];++freq[static_cast<std::size_t>(bwt[i])];}
 std::size_t C[Alphabet]{},sum=0;for(std::size_t c=0;c<Alphabet;++c){C[c]=sum;sum+=freq[c];}
 std::size_t left=0,right=N;for(std::size_t j=m;j>0;--j){auto c=static_cast<std::size_t>(pattern[j-1]);std::size_t rl=0,rr=0;for(std::size_t x=0;x<left;++x)if(static_cast<std::size_t>(bwt[x])==c)++rl;for(std::size_t x=0;x<right;++x)if(static_cast<std::size_t>(bwt[x])==c)++rr;left=C[c]+rl;right=C[c]+rr;if(left==right)break;}
 std::size_t LF[MaxText+1]{};bool sampled[MaxText+1]{};std::size_t samples[MaxText+1]{};for(std::size_t row=0;row<N;++row){auto c=static_cast<std::size_t>(bwt[row]);std::size_t rank=0;for(std::size_t x=0;x<row;++x)if(static_cast<std::size_t>(bwt[x])==c)++rank;LF[row]=C[c]+rank;sampled[row]=(sa[row]%stride==0);samples[row]=sa[row];}
 std::int64_t loc[MaxText]{};std::size_t count=0;for(std::size_t origin=left;origin<right;++origin){auto row=origin;std::size_t steps=0;while(!sampled[row]&&steps<N){row=LF[row];++steps;}if(!sampled[row])return -1;auto pos=(samples[row]+steps)%N;if(pos>=n)return -1;loc[count++]=static_cast<std::int64_t>(pos);}
 auto bytes=8*(count+1);if(!output||capacity<bytes)return -2;store(output,0,static_cast<std::int64_t>(count));for(std::size_t i=0;i<count;++i)store(output,8*(i+1),loc[i]);return static_cast<std::int64_t>(bytes);
}
