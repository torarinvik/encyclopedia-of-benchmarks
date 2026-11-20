#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t QMAX=40, CAP=32, HALF=8;
void store(std::uint8_t* out,std::size_t at,std::int64_t x){
    auto bits=static_cast<std::uint64_t>(x);
    for(std::size_t b=0;b<8;++b) out[at+b]=static_cast<std::uint8_t>(bits>>(8*b));
}
}
extern "C" std::int64_t two_left_hashing_operation_trace(
    const std::int64_t* in,std::size_t n,std::uint8_t* out,std::size_t cap){
    if(in==nullptr||n<5||n>162) return -1;
    if(in[0]<1||in[0]>(std::int64_t)QMAX||n!=1+4*(std::size_t)in[0]) return -1;
    auto q=(std::size_t)in[0];
    for(std::size_t i=0;i<q;++i){
        auto op=in[1+4*i],key=in[2+4*i],l=in[3+4*i],r=in[4+4*i];
        if(op<0||op>2||key<0||key>63||l<0||l>=8||r<0||r>=8) return -1;
        for(std::size_t j=0;j<i;++j) if(in[2+4*j]==key&&(in[3+4*j]!=l||in[4+4*j]!=r)) return -1;
    }
    const auto bytes=16*q;
    if(out==nullptr||cap<bytes) return -2;
    std::array<int,16> head{},len{}; head.fill(-1); len.fill(0);
    std::array<int,32> key{},next{}; key.fill(-1); next.fill(-1);
    std::array<std::int64_t,40> status{},place{}; std::size_t live=0;
    for(std::size_t i=0;i<q;++i){
        int op=(int)in[1+4*i],k=(int)in[2+4*i],lb=(int)in[3+4*i],rb=8+(int)in[4+4*i];
        int found=-1,fb=-1;
        for(int side=0;side<2 && found<0;++side){
            int b=side==0?lb:rb;
            for(int x=head[b];x>=0;x=next[x]) if(key[x]==k){found=x;fb=b;break;}
        }
        if(op==0){
            if(found>=0){status[i]=0;place[i]=-1;continue;}
            if(live==32)return -3;
            bool left=len[lb]<=len[rb];int b=left?lb:rb,x=0;while(key[x]>=0)++x;
            key[x]=k;next[x]=head[b];head[b]=x;++len[b];++live;status[i]=1;place[i]=left?0:1;
        }else if(op==1){status[i]=found>=0?1:0;place[i]=-1;}
        else if(found<0){status[i]=0;place[i]=-1;}
        else{int p=-1,x=head[fb];while(x!=found){p=x;x=next[x];}if(p<0)head[fb]=next[x];else next[p]=next[x];key[x]=-1;next[x]=-1;--len[fb];--live;status[i]=1;place[i]=-1;}
    }
    for(std::size_t i=0;i<q;++i){store(out,16*i,status[i]);store(out,16*i+8,place[i]);}
    return (std::int64_t)bytes;
}
