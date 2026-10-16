#include <cstddef>
#include <cstdint>
namespace {
constexpr int MAX_N=8,MAX_OUTPUT_WORDS=737;
bool safe(const int*rows,int col,int row){for(int c=0;c<col;++c){int prior=rows[c];if(prior==row||prior-c==row-col||prior+c==row+col)return false;}return true;}
void enumerate(int n,int col,int*rows,std::int64_t*out,std::size_t&used){if(col==n){for(int c=0;c<n;++c)out[used++]=rows[c];out[0]+=1;return;}for(int row=0;row<n;++row)if(safe(rows,col,row)){rows[col]=row;enumerate(n,col+1,rows,out,used);}}
void put(std::uint8_t*out,std::size_t i,std::int64_t v){auto bits=static_cast<std::uint64_t>(v);for(std::size_t b=0;b<8;++b)out[i*8+b]=static_cast<std::uint8_t>(bits>>(8*b));}
}
extern "C" std::int64_t n_queens_backtracking_csharp(std::int64_t n,std::uint8_t*out,std::size_t cap)noexcept{if(n<0||n>MAX_N)return -1;std::int64_t values[MAX_OUTPUT_WORDS]{};std::size_t used=1;if(n>0){int rows[MAX_N]{};enumerate(static_cast<int>(n),0,rows,values,used);}auto required=used*8;if(!out||cap<required)return -2;for(std::size_t i=0;i<used;++i)put(out,i,values[i]);return static_cast<std::int64_t>(required);}
