#include <cstddef>
#include <cstdint>
extern "C" std::int64_t otsu_threshold(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){
 if(!v||n<2||v[0]<1||v[0]>32||n!=static_cast<std::size_t>(v[0])+1)return -1;std::size_t count=static_cast<std::size_t>(v[0]);std::uint64_t hist[256]={};for(std::size_t j=0;j<count;j++){auto p=v[j+1];if(p<0||p>255)return -1;hist[p]++;}
 double total=0;for(std::size_t i=0;i<256;i++)total+=static_cast<double>(i)*hist[i];double maxv=0,sum=0;std::size_t wb=0,t=0;
 for(std::size_t i=0;i<256;i++){wb+=hist[i];if(!wb)continue;auto wf=count-wb;if(!wf)break;sum+=static_cast<double>(i)*hist[i];double mb=sum/wb,mf=(total-sum)/wf,var=wb*wf*(mb-mf)*(mb-mf);if(var>maxv){maxv=var;t=i;}}
 if(cap<count||!out)return -2;for(std::size_t j=0;j<count;j++)out[j]=v[j+1]>static_cast<std::int64_t>(t)?255:0;return static_cast<std::int64_t>(count);
}
