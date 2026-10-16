#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t SM_MAX_VALUES = 19;
constexpr int SM_MAX_N = 3;

std::int64_t det3(const std::int64_t *m)
{
    return m[0] * (m[4] * m[8] - m[5] * m[7])
         - m[1] * (m[3] * m[8] - m[5] * m[6])
         + m[2] * (m[3] * m[7] - m[4] * m[6]);
}

void charpoly(const std::int64_t *m, int n, std::int64_t &a, std::int64_t &b, std::int64_t &c)
{
    std::int64_t trace = 0;
    for (int i = 0; i < n; ++i) trace += m[i*n+i];
    a = -trace; b = 0; c = 0;
    if (n == 2) b = m[0]*m[3] - m[1]*m[2];
    if (n == 3) {
        b = (m[0]*m[4] - m[1]*m[3]) + (m[0]*m[8] - m[2]*m[6]) + (m[4]*m[8] - m[5]*m[7]);
        c = -det3(m);
    }
}

std::int64_t disc3(std::int64_t a, std::int64_t b, std::int64_t c)
{
    return a*a*b*b - 4*b*b*b - 4*a*a*a*c - 27*c*c + 18*a*b*c;
}

int rank_singular(const std::int64_t *m, int n)
{
    for (int r0=0; r0<n; ++r0) for (int r1=r0+1; r1<n; ++r1)
        for (int c0=0; c0<n; ++c0) for (int c1=c0+1; c1<n; ++c1)
            if (m[r0*n+c0]*m[r1*n+c1] - m[r0*n+c1]*m[r1*n+c0] != 0) return 2;
    for (int i=0; i<n*n; ++i) if (m[i] != 0) return 1;
    return 0;
}

void shifted(const std::int64_t *m, int n, std::int64_t numerator, std::int64_t denominator,
             std::int64_t *out)
{
    for (int i=0; i<n*n; ++i) out[i]=denominator*m[i];
    for (int i=0; i<n; ++i) out[i*n+i]-=numerator;
}

void multiply(const std::int64_t *a, const std::int64_t *b, int n, std::int64_t *out)
{
    for (int row=0; row<n; ++row) for (int col=0; col<n; ++col) {
        std::int64_t value=0;
        for (int k=0; k<n; ++k) value+=a[row*n+k]*b[k*n+col];
        out[row*n+col]=value;
    }
}

bool similar(const std::int64_t *a, const std::int64_t *b, int n)
{
    std::int64_t aa,ab,ac,ba,bb,bc;
    charpoly(a,n,aa,ab,ac); charpoly(b,n,ba,bb,bc);
    if (aa!=ba || ab!=bb || ac!=bc) return false;
    if (n==1) return true;
    if (n==2) {
        if (aa*aa-4*ab!=0) return true;
        std::int64_t da[9]{},db[9]{};
        shifted(a,n,-aa,2,da); shifted(b,n,-aa,2,db);
        return rank_singular(da,n)==rank_singular(db,n);
    }
    if (disc3(aa,ab,ac)!=0) return true;
    const std::int64_t q=aa*aa-3*ab;
    std::int64_t da[9]{},db[9]{};
    if (q==0) {
        shifted(a,n,-aa,3,da); shifted(b,n,-aa,3,db);
        if (rank_singular(da,n)!=rank_singular(db,n)) return false;
        std::int64_t da2[9]{},db2[9]{};
        multiply(da,da,n,da2); multiply(db,db,n,db2);
        return rank_singular(da2,n)==rank_singular(db2,n);
    }
    const std::int64_t numerator=9*ac-aa*ab, denominator=2*q;
    shifted(a,n,numerator,denominator,da); shifted(b,n,numerator,denominator,db);
    return rank_singular(da,n)==rank_singular(db,n);
}
} // namespace

extern "C" std::int64_t similar_matrices(const std::int64_t *input, std::size_t length)
{
    if (input==nullptr || length<1 || length>SM_MAX_VALUES) return -1;
    const std::int64_t n_value=input[0];
    if (n_value<1 || n_value>SM_MAX_N) return -1;
    const int n=static_cast<int>(n_value);
    const std::size_t matrix_size=static_cast<std::size_t>(n*n);
    if (length!=1+2*matrix_size) return -1;
    std::int64_t a[9]{},b[9]{};
    for (std::size_t i=0;i<2*matrix_size;++i) if(input[1+i]<-5 || input[1+i]>5) return -1;
    for (std::size_t i=0;i<matrix_size;++i) { a[i]=input[1+i]; b[i]=input[1+matrix_size+i]; }
    return similar(a,b,n) ? 1 : 0;
}
