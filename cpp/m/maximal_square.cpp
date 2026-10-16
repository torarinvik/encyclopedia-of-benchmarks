#include <algorithm>
#include <cstddef>
#include <cstdint>
extern "C" int64_t maximal_square(const int64_t* a,size_t len){if(!a||len<3||len>258||a[0]<1||a[0]>16||a[1]<1||a[1]>16||static_cast<size_t>(a[0]*a[1])+2!=len)return -1;size_t rows=a[0],cols=a[1];size_t dp[16]={},best=0;for(size_t i=0;i<rows*cols;i++)if(a[i+2]!=0&&a[i+2]!=1)return -1;for(size_t r=0;r<rows;r++){size_t diag=0;for(size_t c=0;c<cols;c++){size_t above=dp[c];if(a[r*cols+c+2])dp[c]=(r==0||c==0)?1:std::min({diag,dp[c],dp[c-1]})+1;else dp[c]=0;best=std::max(best,dp[c]);diag=above;}}return static_cast<int64_t>(best*best);}
