// Uncompiled and unexecuted matrix-tree draft.
#include <array>
#include <cstddef>
#include <cstdint>

using Matrix = std::array<std::array<std::int64_t,6>,6>;
static std::int64_t minor_det(const Matrix& lap, int n, int first, int second) {
    Matrix a{}; int row = 0;
    for (int i=0;i<n;++i) if (i!=first && i!=second) {
        int col=0;
        for (int j=0;j<n;++j) if (j!=first && j!=second) a[row][col++]=lap[i][j];
        ++row;
    }
    if (!row) return 1;
    std::int64_t previous=1;
    for (int k=0;k<row-1;++k) {
        const auto pivot=a[k][k]; if (!pivot) return 0;
        for (int i=k+1;i<row;++i) for (int j=k+1;j<row;++j)
            a[i][j]=(a[i][j]*pivot-a[i][k]*a[k][j])/previous;
        for (int i=k+1;i<row;++i) a[i][k]=0;
        previous=pivot;
    }
    return a[row-1][row-1];
}
extern "C" std::int64_t effective_resistance_unit_graph(const std::int64_t* input, std::size_t length) {
    if (!input || length<4 || length>35) return -1;
    const auto nv=input[0], mv=input[1], sv=input[2], tv=input[3];
    if (nv<2 || nv>6 || mv<0 || mv>15 || sv<0 || sv>=nv || tv<0 || tv>=nv || sv==tv || length!=static_cast<std::size_t>(4+2*mv)) return -1;
    const int n=static_cast<int>(nv), m=static_cast<int>(mv), s=static_cast<int>(sv), t=static_cast<int>(tv);
    Matrix lap{}; bool seen[6][6]{};
    for (int i=0;i<m;++i) {
        const auto u64=input[4+2*i], v64=input[5+2*i];
        if (u64<0 || u64>=n || v64<0 || v64>=n || u64==v64) return -1;
        const int u=static_cast<int>(u64), v=static_cast<int>(v64);
        if (seen[u][v]) return -1;
        seen[u][v]=seen[v][u]=true;
        ++lap[u][u]; ++lap[v][v]; --lap[u][v]; --lap[v][u];
    }
    const auto trees=minor_det(lap,n,t,-1);
    if (trees<=0) return -1;
    const auto forests=minor_det(lap,n,s,t);
    auto a=trees,b=forests;
    while (b) { auto r=a%b; a=b; b=r; }
    return forests/a*65536+trees/a;
}
