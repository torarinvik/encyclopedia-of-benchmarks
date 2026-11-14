// Independent finite-field arithmetic scaffold for polynomial_resultant_half_gcd.
// No exported benchmark yet; half-GCD and resultant factor tracking remain.
#pragma once
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <utility>
#include <vector>

namespace resultant_draft {
using Coeff = std::int64_t;
using Poly = std::vector<Coeff>;
constexpr Coeff prime = 998244353;

inline void trim(Poly& a) {
    while (!a.empty() && a.back()==0) a.pop_back();
}

inline Coeff power(Coeff base, std::size_t exponent) {
    Coeff result=1;
    while (exponent) {
        if (exponent&1) result=result*base%prime;
        base=base*base%prime;
        exponent>>=1;
    }
    return result;
}

// All transform lengths used by the bounded profile divide 2^23.
inline void transform(Poly& a, bool inverse) {
    const std::size_t n=a.size();
    for (std::size_t i=1,j=0; i<n; ++i) {
        std::size_t bit=n>>1;
        for (; j&bit; bit>>=1) j^=bit;
        j^=bit;
        if (i<j) std::swap(a[i],a[j]);
    }
    for (std::size_t width=2; width<=n; width<<=1) {
        Coeff root=power(3,static_cast<std::size_t>(prime-1)/width);
        if (inverse) root=power(root,prime-2);
        for (std::size_t start=0; start<n; start+=width) {
            Coeff factor=1;
            for (std::size_t j=0; j<width/2; ++j) {
                Coeff x=a[start+j], y=a[start+j+width/2]*factor%prime;
                a[start+j]=(x+y)%prime;
                a[start+j+width/2]=(x-y+prime)%prime;
                factor=factor*root%prime;
            }
        }
    }
    if (inverse) {
        Coeff scale=power(static_cast<Coeff>(n),prime-2);
        for (auto& x:a) x=x*scale%prime;
    }
}

inline Poly multiply(const Poly& a, const Poly& b) {
    if (a.empty() || b.empty()) return {};
    const std::size_t needed=a.size()+b.size()-1;
    if (std::min(a.size(),b.size())<=32) {
        Poly out(needed,0);
        for (std::size_t i=0; i<a.size(); ++i)
            for (std::size_t j=0; j<b.size(); ++j)
                out[i+j]=(out[i+j]+a[i]*b[j])%prime;
        trim(out);
        return out;
    }
    std::size_t size=1;
    while (size<needed) size<<=1;
    Poly left=a, right=b;
    left.resize(size,0); right.resize(size,0);
    transform(left,false); transform(right,false);
    for (std::size_t i=0; i<size; ++i) left[i]=left[i]*right[i]%prime;
    transform(left,true);
    left.resize(needed);
    trim(left);
    return left;
}

// Truncated inverse. f[0] must be nonzero and count must be positive.
inline Poly inverse_series(const Poly& f, std::size_t count) {
    Poly inverse{power(f[0],prime-2)};
    while (inverse.size()<count) {
        const std::size_t size=std::min(count,2*inverse.size());
        Poly prefix(f.begin(),f.begin()+std::min(size,f.size()));
        Poly correction=multiply(prefix,inverse);
        correction.resize(size,0);
        for (auto& x:correction) x=x ? prime-x : 0;
        correction[0]=(correction[0]+2)%prime;
        inverse=multiply(inverse,correction);
        inverse.resize(size,0);
    }
    return inverse;
}

// Quotient and remainder of canonical polynomials; divisor is nonzero.
inline std::pair<Poly,Poly> divide(const Poly& dividend, const Poly& divisor) {
    if (dividend.size()<divisor.size()) return {{},dividend};
    const std::size_t qsize=dividend.size()-divisor.size()+1;
    Poly high(qsize), reversed(divisor.rbegin(),divisor.rend());
    for (std::size_t i=0; i<qsize; ++i) high[i]=dividend[dividend.size()-1-i];
    Poly reverse_q=multiply(high,inverse_series(reversed,qsize));
    reverse_q.resize(qsize,0);
    std::reverse(reverse_q.begin(),reverse_q.end());
    Poly removed=multiply(reverse_q,divisor);
    Poly remainder(divisor.size()-1,0);
    for (std::size_t i=0; i<remainder.size(); ++i) {
        Coeff subtract=i<removed.size() ? removed[i] : 0;
        remainder[i]=(dividend[i]-subtract+prime)%prime;
    }
    trim(reverse_q); trim(remainder);
    return {std::move(reverse_q),std::move(remainder)};
}

inline Poly add(const Poly& a, const Poly& b) {
    Poly out(std::max(a.size(),b.size()),0);
    for (std::size_t i=0; i<a.size(); ++i) out[i]=a[i];
    for (std::size_t i=0; i<b.size(); ++i) out[i]=(out[i]+b[i])%prime;
    trim(out);
    return out;
}

inline Poly subtract(const Poly& a, const Poly& b) {
    Poly out(std::max(a.size(),b.size()),0);
    for (std::size_t i=0; i<a.size(); ++i) out[i]=a[i];
    for (std::size_t i=0; i<b.size(); ++i) out[i]=(out[i]-b[i]+prime)%prime;
    trim(out);
    return out;
}

// Drop the coefficients below x^offset, retaining ascending coefficient order.
inline Poly high_part(const Poly& a, std::size_t offset) {
    if (offset>=a.size()) return {};
    return Poly(a.begin()+offset,a.end());
}

struct Matrix {
    Poly a, b, c, d;
    static Matrix identity() { return {{1},{},{},{1}}; }
};

// Matrices act on column pairs; compose(left,right) applies right first.
inline Matrix compose(const Matrix& left, const Matrix& right) {
    return {
        add(multiply(left.a,right.a),multiply(left.b,right.c)),
        add(multiply(left.a,right.b),multiply(left.b,right.d)),
        add(multiply(left.c,right.a),multiply(left.d,right.c)),
        add(multiply(left.c,right.b),multiply(left.d,right.d))
    };
}

inline std::pair<Poly,Poly> apply(const Matrix& matrix, const Poly& a, const Poly& b) {
    return {add(multiply(matrix.a,a),multiply(matrix.b,b)),
            add(multiply(matrix.c,a),multiply(matrix.d,b))};
}

// Given a=q*b+r, this left multiplication changes (a,b) into (b,r).
inline Matrix euclidean_step(const Poly& quotient) {
    Poly negative=quotient;
    for (auto& coefficient:negative) if (coefficient) coefficient=prime-coefficient;
    return {{},{1},{1},std::move(negative)};
}
} // namespace resultant_draft
