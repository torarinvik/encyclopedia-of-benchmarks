#include <cstddef>
#include <cstdint>
#include <string>
static const char *small_words[]={"Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Ten","Eleven","Twelve","Thirteen","Fourteen","Fifteen","Sixteen","Seventeen","Eighteen","Nineteen"};
static const char *tens_words[]={"","","Twenty","Thirty","Forty","Fifty","Sixty","Seventy","Eighty","Ninety"};
static const char *scales[]={"","Thousand","Million","Billion","Trillion"};
static void add(std::string &s,const char *w){if(!s.empty())s+=' ';s+=w;}
static void chunk(std::string&s,unsigned x){if(x>=100){add(s,small_words[x/100]);add(s,"Hundred");x%=100;}if(x>=20){add(s,tens_words[x/10]);x%=10;}if(x>0&&x<20)add(s,small_words[x]);}
extern "C" std::int64_t number_to_words(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){
 if(!v||n<3||n>9||v[0]<-1||v[0]>1||v[1]<0||v[1]>999999999999999LL||v[2]<0||v[2]>6||n!=static_cast<std::size_t>(v[2])+3)return -1;
 bool nz=v[1]!=0;for(std::size_t i=3;i<n;i++){if(v[i]<0||v[i]>9)return -1;if(v[i])nz=true;}if((nz&&v[0]==0)||(!nz&&v[0]!=0))return -1;
 std::string result;if(v[0]<0)add(result,"Negative");std::uint64_t whole=static_cast<std::uint64_t>(v[1]);unsigned g[5]{};for(int i=0;i<5;i++){g[i]=whole%1000;whole/=1000;}bool any=false;for(int i=4;i>=0;i--)if(g[i]){chunk(result,g[i]);if(i)add(result,scales[i]);any=true;}if(!any)add(result,"Zero");bool fnz=false;for(std::size_t i=3;i<n;i++)if(v[i])fnz=true;if(fnz){add(result,"Point");for(std::size_t i=3;i<n;i++)add(result,small_words[v[i]]);}
 if(result.size()>cap||(result.size()&&!out))return -2;for(std::size_t i=0;i<result.size();i++)out[i]=static_cast<std::uint8_t>(result[i]);return static_cast<std::int64_t>(result.size());
}
