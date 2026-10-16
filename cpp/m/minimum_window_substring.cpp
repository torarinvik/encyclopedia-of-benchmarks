#include <cstddef>
#include <cstdint>
extern "C" std::int64_t minimum_window_substring(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap) noexcept {
 if(!v||n<3||n>258||v[0]<0||v[0]>128)return -1;std::size_t a=static_cast<std::size_t>(v[0]);if(n<a+2)return -1;auto mm=v[a+1];if(mm<1||mm>128)return -1;std::size_t m=static_cast<std::size_t>(mm);if(n!=a+m+2)return -1;
 int need[128]={};for(std::size_t i=0;i<a;i++)if(v[i+1]<0||v[i+1]>127)return -1;for(std::size_t i=0;i<m;i++){auto c=v[a+2+i];if(c<0||c>127)return -1;++need[c];}
 std::size_t left=0,best=a+1,start=0;int missing=static_cast<int>(m);for(std::size_t right=0;right<a;right++){int c=static_cast<int>(v[right+1]);if(need[c]>0)--missing;--need[c];while(missing==0){auto len=right-left+1;if(len<best){best=len;start=left;}int x=static_cast<int>(v[left+1]);++need[x];++left;if(need[x]>0)++missing;}}
 if(best==a+1)return 0;if(best>cap||(!out&&best))return -2;for(std::size_t i=0;i<best;i++)out[i]=static_cast<std::uint8_t>(v[start+1+i]);return static_cast<std::int64_t>(best);
}
