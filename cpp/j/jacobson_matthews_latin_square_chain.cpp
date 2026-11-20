#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 4, max_cells = 64, max_moves = 48, max_words = 66;
struct Move { std::size_t i, j, k, ip, jp, kp; };
std::size_t at(std::size_t n, std::size_t i, std::size_t j, std::size_t k) noexcept {
    return (i * n + j) * n + k;
}
bool select_move(const std::array<std::int64_t, max_cells>& a, std::size_t n,
                 std::size_t choice, Move& selected) noexcept {
    std::array<Move, max_moves> moves{};
    std::size_t defects = 0, pi = 0, pj = 0, pk = 0, count = 0;
    for (std::size_t i=0;i<n;++i) for (std::size_t j=0;j<n;++j) for (std::size_t k=0;k<n;++k)
        if (a[at(n,i,j,k)] == -1) { ++defects; pi=i; pj=j; pk=k; }
    if (defects > 1) return false;
    if (defects == 1) {
        for (std::size_t ip=0;ip<n;++ip) for (std::size_t jp=0;jp<n;++jp) for (std::size_t kp=0;kp<n;++kp)
            if (ip!=pi && jp!=pj && kp!=pk && a[at(n,pi,pj,kp)]==1 &&
                a[at(n,pi,jp,pk)]==1 && a[at(n,ip,pj,pk)]==1)
                moves[count++]={pi,pj,pk,ip,jp,kp};
        if (count != 8) return false;
    } else {
        for (std::size_t i=0;i<n;++i) for (std::size_t j=0;j<n;++j) for (std::size_t k=0;k<n;++k) {
            if (a[at(n,i,j,k)] != 0) continue;
            std::size_t ip=n, jp=n, kp=n;
            for (std::size_t x=0;x<n;++x) if (a[at(n,x,j,k)]==1) ip=x;
            for (std::size_t x=0;x<n;++x) if (a[at(n,i,x,k)]==1) jp=x;
            for (std::size_t x=0;x<n;++x) if (a[at(n,i,j,x)]==1) kp=x;
            if (ip==n || jp==n || kp==n) return false;
            moves[count++]={i,j,k,ip,jp,kp};
        }
        if (count != n*n*n-n*n) return false;
    }
    if (choice >= count) return false;
    selected = moves[choice];
    return true;
}
bool step(std::array<std::int64_t,max_cells>& a,std::size_t n,std::size_t choice) noexcept {
    Move m{};
    if (!select_move(a,n,choice,m)) return false;
    ++a[at(n,m.i,m.j,m.k)]; ++a[at(n,m.ip,m.jp,m.k)];
    ++a[at(n,m.ip,m.j,m.kp)]; ++a[at(n,m.i,m.jp,m.kp)];
    --a[at(n,m.ip,m.j,m.k)]; --a[at(n,m.i,m.jp,m.k)];
    --a[at(n,m.i,m.j,m.kp)]; --a[at(n,m.ip,m.jp,m.kp)];
    return true;
}
void write_i64_le(std::uint8_t* output,std::size_t offset,std::int64_t value) noexcept {
    const auto bits=static_cast<std::uint64_t>(value);
    for(std::size_t b=0;b<8;++b) output[offset+b]=static_cast<std::uint8_t>(bits>>(b*8));
}
}

extern "C" std::int64_t jacobson_matthews_latin_square_chain(const std::int64_t* input,
    std::size_t length,std::uint8_t* output,std::size_t capacity) noexcept {
    if(input==nullptr || length<2 || length>14) return -1;
    const auto nv=input[0], sv=input[1];
    if(nv<2 || nv>static_cast<std::int64_t>(max_n) || sv<0 || sv>12 || length!=2+static_cast<std::size_t>(sv)) return -1;
    const auto n=static_cast<std::size_t>(nv), steps=static_cast<std::size_t>(sv);
    std::array<std::int64_t,max_cells> tensor{};
    for(std::size_t i=0;i<n;++i) for(std::size_t j=0;j<n;++j) tensor[at(n,i,j,(i+j)%n)]=1;
    for(std::size_t s=0;s<steps;++s) {
        if(input[2+s]<0 || input[2+s]>=static_cast<std::int64_t>(max_moves) ||
           !step(tensor,n,static_cast<std::size_t>(input[2+s]))) return -1;
    }
    const auto count=2+n*n*n, bytes=count*8;
    if(output==nullptr || capacity<bytes) return -2;
    std::array<std::int64_t,max_words> words{};
    words[0]=nv; words[1]=sv;
    for(std::size_t i=0;i<n*n*n;++i) words[2+i]=tensor[i];
    for(std::size_t i=0;i<count;++i) write_i64_le(output,i*8,words[i]);
    return static_cast<std::int64_t>(bytes);
}
