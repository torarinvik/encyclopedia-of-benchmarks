#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 12, MAX_PAIRS = 36, TABLE_VALUES = 234, MAX_INPUT = 247, MAX_OUTPUT = 112;
constexpr std::int64_t INF = INT64_C(1152921504606846976);
int pair_type_of(std::int64_t left, std::int64_t right) {
    if (left == 0 && right == 3) return 0;
    if (left == 3 && right == 0) return 1;
    if (left == 1 && right == 2) return 2;
    if (left == 2 && right == 1) return 3;
    if (left == 2 && right == 3) return 4;
    if (left == 3 && right == 2) return 5;
    return -1;
}
bool lex_less_mask(std::uint64_t left, std::uint64_t right, std::size_t count) {
    std::size_t li = 0, ri = 0;
    for (;;) {
        while (li < count && ((left >> li) & 1U) == 0) ++li;
        while (ri < count && ((right >> ri) & 1U) == 0) ++ri;
        if (li == count || ri == count) return li == count && ri < count;
        if (li != ri) return li < ri;
        ++li; ++ri;
    }
}
std::int64_t loop_cost(const std::int64_t *input, std::size_t n, int kind, int unpaired, int children) {
    return input[1+n+static_cast<std::size_t>(kind)*39+static_cast<std::size_t>(unpaired)*3+static_cast<std::size_t>(children)];
}
void put64(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte=0; byte<8; ++byte) { out[offset+byte]=static_cast<std::uint8_t>(bits&255U); bits >>= 8; }
}
}

extern "C" std::int64_t rna_mfe_loop_energy_dp(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input==nullptr || length<239 || length>MAX_INPUT) return -1;
    const std::int64_t n64=input[0];
    if (n64<4 || n64>static_cast<std::int64_t>(MAX_N) || length!=1+static_cast<std::size_t>(n64)+TABLE_VALUES) return -1;
    const std::size_t n=static_cast<std::size_t>(n64);
    std::int64_t bases[MAX_N];
    for (std::size_t i=0;i<n;++i) { bases[i]=input[1+i]; if (bases[i]<0 || bases[i]>3) return -1; }
    for (std::size_t i=1+n;i<length;++i) if (input[i]<-1000 || input[i]>1000) return -1;
    int types[MAX_N][MAX_N], ids[MAX_N][MAX_N];
    for (std::size_t i=0;i<MAX_N;++i) for (std::size_t j=0;j<MAX_N;++j) { types[i][j]=-1; ids[i][j]=-1; }
    int pair_i[MAX_PAIRS],pair_j[MAX_PAIRS]; std::size_t pair_count=0;
    for (std::size_t i=0;i<n;++i) for (std::size_t j=i+4;j<n;++j) {
        int kind=pair_type_of(bases[i],bases[j]);
        if (kind>=0) { types[i][j]=kind; ids[i][j]=static_cast<int>(pair_count); pair_i[pair_count]=static_cast<int>(i); pair_j[pair_count]=static_cast<int>(j); ++pair_count; }
    }
    std::int64_t ve[MAX_N][MAX_N]; std::uint64_t vm[MAX_N][MAX_N]{};
    for (std::size_t i=0;i<MAX_N;++i) for (std::size_t j=0;j<MAX_N;++j) ve[i][j]=INF;
    for (std::size_t span=4;span<n;++span) for (std::size_t i=0;i+span<n;++i) {
        const std::size_t j=i+span; const int kind=types[i][j]; if (kind<0) continue;
        const std::uint64_t outer=UINT64_C(1)<<static_cast<unsigned>(ids[i][j]);
        std::int64_t best=INF; std::uint64_t best_mask=0;
        std::int64_t candidate=loop_cost(input,n,kind,static_cast<int>(span)-1,0);
        if (candidate<best || (candidate==best && lex_less_mask(outer,best_mask,pair_count))) { best=candidate; best_mask=outer; }
        for (std::size_t a=i+1;a<j;++a) for (std::size_t b=a+4;b<j;++b) {
            if (ids[a][b]<0 || ve[a][b]==INF) continue;
            const int u=static_cast<int>(a-i-1+j-b-1); candidate=loop_cost(input,n,kind,u,1)+ve[a][b];
            const std::uint64_t mask=outer|vm[a][b];
            if (candidate<best || (candidate==best && lex_less_mask(mask,best_mask,pair_count))) { best=candidate; best_mask=mask; }
        }
        for (std::size_t a=i+1;a<j;++a) for (std::size_t b=a+4;b<j;++b) {
            if (ids[a][b]<0 || ve[a][b]==INF) continue;
            for (std::size_t c=b+1;c<j;++c) for (std::size_t d=c+4;d<j;++d) {
                if (ids[c][d]<0 || ve[c][d]==INF) continue;
                const int u=static_cast<int>(a-i-1+c-b-1+j-d-1);
                candidate=loop_cost(input,n,kind,u,2)+ve[a][b]+ve[c][d];
                const std::uint64_t mask=outer|vm[a][b]|vm[c][d];
                if (candidate<best || (candidate==best && lex_less_mask(mask,best_mask,pair_count))) { best=candidate; best_mask=mask; }
            }
        }
        ve[i][j]=best; vm[i][j]=best_mask;
    }
    std::int64_t we[MAX_N]{}; std::uint64_t wm[MAX_N]{};
    for (std::size_t j=0;j<n;++j) {
        std::int64_t best=j==0?0:we[j-1]; std::uint64_t best_mask=j==0?0:wm[j-1];
        for (std::size_t i=0;i+4<=j;++i) {
            if (types[i][j]<0 || ve[i][j]==INF) continue;
            const std::int64_t prefix=i==0?0:we[i-1];
            const std::uint64_t mask=(i==0?0:wm[i-1])|vm[i][j]; const std::int64_t value=prefix+ve[i][j];
            if (value<best || (value==best && lex_less_mask(mask,best_mask,pair_count))) { best=value; best_mask=mask; }
        }
        we[j]=best; wm[j]=best_mask;
    }
    std::int64_t count=0; for (std::size_t p=0;p<pair_count;++p) if ((wm[n-1]>>p)&1U) ++count;
    const std::size_t bytes=8*(2+2*static_cast<std::size_t>(count)); if (output==nullptr || capacity<bytes) return -2;
    std::uint8_t staged[MAX_OUTPUT]; put64(staged,0,we[n-1]); put64(staged,8,count); std::size_t at=2;
    for (std::size_t p=0;p<pair_count;++p) if ((wm[n-1]>>p)&1U) { put64(staged,8*at++,pair_i[p]); put64(staged,8*at++,pair_j[p]); }
    for (std::size_t byte=0;byte<bytes;++byte) output[byte]=staged[byte];
    return static_cast<std::int64_t>(bytes);
}
