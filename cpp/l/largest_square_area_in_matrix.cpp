#include <cstddef>
#include <cstdint>
#include <algorithm>
extern "C" std::int64_t largest_square_area_in_matrix(const std::int64_t*v,std::size_t n){if(!v||n<2||n>66)return -2;auto r=v[0],c=v[1];if(r<1||r>8||c<1||c>8||n!=2+r*c)return -2;std::int64_t d[9][9]={};for(int i=0;i<r*c;i++)if(v[2+i]!=0&&v[2+i]!=1)return -2;std::int64_t best=0;for(int i=r-1;i>=0;i--)for(int j=c-1;j>=0;j--)if(v[2+i*c+j]){d[i][j]=1+std::min({d[i+1][j],d[i][j+1],d[i+1][j+1]});best=std::max(best,d[i][j]);}return best;}
