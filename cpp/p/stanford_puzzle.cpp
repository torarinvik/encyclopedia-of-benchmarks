/* Independent bounded reimplementation of Stanford Puzzle (Forest Baskett).
   The pinned source has no explicit redistribution grant; no source code or
   source comments are copied into this port. See the package README. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr int side=5, cell_count=125, type_count=13, max_search_calls=2005;
constexpr std::int64_t hole_scale=1'000'000;
struct Piece { int x,y,z,piece_class; };
constexpr Piece pieces[type_count]={
    {4,2,1,0},{2,1,4,0},{1,4,2,0},{2,4,1,0},{4,1,2,0},{1,2,4,0},
    {3,1,1,1},{1,3,1,1},{1,1,3,1},{2,2,1,2},{2,1,2,2},{1,2,2,2},{2,2,2,3}
};
bool fits(const std::uint8_t* board,int start,int type){
    int x0=start%side,y0=(start/side)%side,z0=start/(side*side);Piece p=pieces[type];
    if(x0+p.x>side||y0+p.y>side||z0+p.z>side)return false;
    for(int z=0;z<p.z;z++)for(int y=0;y<p.y;y++)for(int x=0;x<p.x;x++)if(board[(z0+z)*side*side+(y0+y)*side+x0+x])return false;
    return true;
}
void mark(std::uint8_t* board,int start,int type,std::uint8_t value){
    int x0=start%side,y0=(start/side)%side,z0=start/(side*side);Piece p=pieces[type];
    for(int z=0;z<p.z;z++)for(int y=0;y<p.y;y++)for(int x=0;x<p.x;x++)board[(z0+z)*side*side+(y0+y)*side+x0+x]=value;
}
int first_empty(const std::uint8_t* board,int from){for(int i=from;i<cell_count;i++)if(!board[i])return i;return 0;}
std::int64_t source_index(int flat){int x=flat%side,y=(flat/side)%side,z=flat/(side*side);return (x+1)+8LL*(y+1)+64LL*(z+1);}
bool search(std::uint8_t* board,int* remaining,int start,int& calls,bool& overflow){
    if(++calls>max_search_calls){overflow=true;return false;}
    for(int type=0;type<type_count;type++){int cls=pieces[type].piece_class;if(remaining[cls]==0||!fits(board,start,type))continue;
        mark(board,start,type,1);--remaining[cls];int next=first_empty(board,start);bool child=search(board,remaining,next,calls,overflow);
        if(overflow)return false;if(child||next==0)return true;++remaining[cls];mark(board,start,type,0);
    }
    return false;
}
}

extern "C" std::int64_t stanford_puzzle(const std::int64_t* input,std::size_t length) noexcept {
    if(!input||length!=1||input[0]<1||input[0]>100)return -1;
    std::int64_t checksum=0;
    for(std::int64_t pass=0;pass<input[0];pass++){
        std::uint8_t board[cell_count]={};int remaining[4]={13,3,1,1};if(!fits(board,0,0))return -1;
        mark(board,0,0,1);--remaining[0];int hole=first_empty(board,0);int calls=0;bool overflow=false;
        if(hole==0||!search(board,remaining,hole,calls,overflow)||overflow)return -1;
        checksum+=source_index(hole)*hole_scale+calls;
    }
    return checksum;
}
