#include <cstddef>
#include <cstdint>
namespace {
struct Move{int row,col,degree;};constexpr int DX[8]={1,2,2,1,-1,-2,-2,-1};constexpr int DY[8]={-2,-1,1,2,2,1,-1,-2};
int count_neighbors(const int b[8][8],int r,int c){int n=0;for(int i=0;i<8;++i){int y=r+DY[i],x=c+DX[i];if(y>=0&&y<8&&x>=0&&x<8&&b[y][x]==0)++n;}return n;}
int neighbors(const int b[8][8],int r,int c,Move out[8]){int n=0;for(int i=0;i<8;++i){int y=r+DY[i],x=c+DX[i];if(y>=0&&y<8&&x>=0&&x<8&&b[y][x]==0)out[n++]={y,x,count_neighbors(b,y,x)};}return n;}
void sort_moves(Move*m,int n){for(int i=1;i<n;++i){Move v=m[i];int j=i;while(j>0&&m[j-1].degree>v.degree){m[j]=m[j-1];--j;}m[j]=v;}}
bool orphan(const int b[8][8],int count,int r,int c){if(count<63){Move m[8];int n=neighbors(b,r,c,m);for(int i=0;i<n;++i)if(count_neighbors(b,m[i].row,m[i].col)==0)return true;}return false;}
bool solve(int b[8][8],int r,int c,int count){if(count>64)return true;Move m[8];int n=neighbors(b,r,c,m);if(n==0&&count!=64)return false;sort_moves(m,n);for(int i=0;i<n;++i){auto x=m[i];b[x.row][x.col]=count;if(!orphan(b,count,x.row,x.col)&&solve(b,x.row,x.col,count+1))return true;b[x.row][x.col]=0;}return false;}
void put(std::uint8_t*out,std::size_t i,std::int64_t v){auto bits=static_cast<std::uint64_t>(v);for(std::size_t b=0;b<8;++b)out[i*8+b]=static_cast<std::uint8_t>(bits>>(8*b));}
}
extern "C" std::int64_t knights_tour_warnsdorff_open(const std::int64_t*,std::size_t len,std::uint8_t*out,std::size_t cap)noexcept{if(len!=0)return -1;if(!out||cap<512)return -2;int b[8][8]{};b[0][0]=1;if(!solve(b,0,0,2))return -1;std::int64_t path[64];for(int r=0;r<8;++r)for(int c=0;c<8;++c)path[b[r][c]-1]=r*8+c;for(std::size_t i=0;i<64;++i)put(out,i,path[i]);return 512;}
