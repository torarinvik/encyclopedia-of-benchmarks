#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>
extern "C" double median_two_array(const int64_t*a,size_t len){if(!a||len<2||len>259||a[0]<0||a[1]<0||a[0]+a[1]<1||a[0]+a[1]>256||len!=static_cast<size_t>(a[0]+a[1])+2)return -1.0e300;size_t n1=a[0],n=a[0]+a[1];std::vector<int64_t> v;for(size_t i=0;i<n;i++){auto x=a[i+2];if(x < -1000000||x>1000000)return -1.0e300;if(i<n1&&i&&x<a[i+1])return -1.0e300;if(i>=n1&&i>n1&&x<a[i+1])return -1.0e300;v.push_back(x);}std::sort(v.begin(),v.end());size_t m=n/2;return n%2?double(v[m]):(double(v[m-1])+double(v[m]))/2.0;}
