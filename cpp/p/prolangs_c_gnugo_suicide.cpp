// GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
// Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
// Upstream suicide/eval/countlib/count are under GNU GPL version 1; derivative under GPLv1.
#include <array>
#include <cstddef>
#include <cstdint>

static int group_liberties(const std::array<std::uint8_t,361>& board, int start, std::uint8_t color) {
    std::array<std::uint8_t,361> seen{}, lib_seen{};
    std::array<int,361> stack{}; std::size_t top=0; int count=0;
    stack[top++]=start; seen[static_cast<std::size_t>(start)]=1;
    while(top) {
        int at=stack[--top], r=at/19, c=at%19; int nb[4], n=0;
        if(r>0) nb[n++]=at-19; if(r<18) nb[n++]=at+19; if(c>0) nb[n++]=at-1; if(c<18) nb[n++]=at+1;
        for(int j=0;j<n;++j) { int next=nb[j]; auto ix=static_cast<std::size_t>(next);
            if(board[ix]==0) { if(!lib_seen[ix]) { lib_seen[ix]=1; ++count; } }
            else if(board[ix]==color && !seen[ix]) { seen[ix]=1; stack[top++]=next; }
        }
    }
    return count;
}

extern "C" std::int64_t prolangs_c_gnugo_suicide(const std::int64_t *input, std::size_t length) noexcept {
    if(input==nullptr || length<6 || length>246) return -1;
    const auto row=input[0], col=input[1], own=input[2], opponent=input[3], ko=input[4], count=input[5];
    if(row<0 || row>=19 || col<0 || col>=19 || (own!=1 && own!=2) || (opponent!=1 && opponent!=2) || own==opponent ||
       ko < -1 || ko >= 361 || count<0 || count>120 || length!=6+2*static_cast<std::size_t>(count)) return -1;
    std::array<std::uint8_t,361> board{};
    for(std::int64_t k=0;k<count;++k) { auto at=input[6+2*static_cast<std::size_t>(k)], stone=input[7+2*static_cast<std::size_t>(k)];
        if(at<0 || at>=361 || (stone!=1 && stone!=2) || board[static_cast<std::size_t>(at)]) return -1;
        board[static_cast<std::size_t>(at)]=static_cast<std::uint8_t>(stone);
    }
    int target=static_cast<int>(row*19+col); if(board[static_cast<std::size_t>(target)]) return -1;
    board[static_cast<std::size_t>(target)]=static_cast<std::uint8_t>(opponent);
    if(group_liberties(board,target,static_cast<std::uint8_t>(opponent))>0) return 0;
    int dead=0; for(int i=0;i<361;++i) if(board[static_cast<std::size_t>(i)]==own && group_liberties(board,i,static_cast<std::uint8_t>(own))==0) ++dead;
    return (dead==0 || (dead==1 && ko==target)) ? 1 : 0;
}
