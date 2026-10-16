#include <cstddef>
#include <cstdint>

namespace {
constexpr int DR[8]={2,1,-1,-2,-2,-1,1,2};
constexpr int DC[8]={1,2,2,1,-1,-2,-2,-1};
bool solve(int board[8][8],int row,int col,int step){if(step==64)return true;for(int move=0;move<8;++move){int r=row+DR[move],c=col+DC[move];if(r>=0&&r<8&&c>=0&&c<8&&board[r][c]==-1){board[r][c]=step;if(solve(board,r,c,step+1))return true;board[r][c]=-1;}}return false;}
void put(std::uint8_t*out,std::size_t index,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b)out[index*8+b]=static_cast<std::uint8_t>(bits>>(8*b));}
}
extern "C" std::int64_t knight_tour_open_dfs(const std::int64_t*,std::size_t length,std::uint8_t*out,std::size_t capacity) noexcept{
 if(length!=0)return -1;if(!out||capacity<512)return -2;int board[8][8];for(auto&row:board)for(int&cell:row)cell=-1;board[0][0]=0;if(!solve(board,0,0,1))return -1;std::int64_t path[64];for(int r=0;r<8;++r)for(int c=0;c<8;++c)path[board[r][c]]=r*8+c;for(std::size_t i=0;i<64;++i)put(out,i,path[i]);return 512;
}
