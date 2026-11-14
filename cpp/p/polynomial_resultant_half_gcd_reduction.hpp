// Independent recursive half-GCD matrix draft. Not compiled or executed.
#pragma once
#include "polynomial_resultant_half_gcd_primitives.hpp"

namespace resultant_draft {

// A quotient's degree and leading coefficient are enough to reconstruct the
// degrees and leading coefficients of the successive Euclidean remainders.
struct QuotientHead { std::size_t degree; Coeff leading; };

// For canonical a,b with deg(a)>deg(b), return a forward matrix taking the
// pair to consecutive remainders. The second output has degree below
// ceil(deg(a)/2); zero is represented by the empty polynomial.
// This routine does not yet track the resultant's scalar factors.
inline Matrix half_reduce(const Poly& a, const Poly& b,
                          std::vector<QuotientHead>* heads=nullptr) {
    if (b.empty()) return Matrix::identity();
    const std::size_t degree=a.size()-1;
    const std::size_t threshold=(degree+1)/2;
    if (b.size()<=threshold) return Matrix::identity();

    if (degree<=64) {
        Poly first=a, second=b;
        Matrix result=Matrix::identity();
        while (!second.empty() && second.size()>threshold) {
            auto division=divide(first,second);
            if (heads) heads->push_back({division.first.size()-1,division.first.back()});
            result=compose(euclidean_step(division.first),result);
            first=std::move(second);
            second=std::move(division.second);
        }
        return result;
    }

    // Reduce the high halves, then apply that matrix to the original pair so
    // that the actual low coefficients and the true remainder degrees return.
    Matrix first_matrix=half_reduce(high_part(a,threshold),high_part(b,threshold),heads);
    auto reduced=apply(first_matrix,a,b);
    if (reduced.second.empty() || reduced.second.size()<=threshold) return first_matrix;

    auto division=divide(reduced.first,reduced.second);
    if (heads) heads->push_back({division.first.size()-1,division.first.back()});
    Matrix one_step=euclidean_step(division.first);
    Matrix prefix=compose(one_step,first_matrix);
    if (division.second.empty()) return prefix;
    const std::size_t second_degree=reduced.second.size()-1;
    const std::size_t shift=2*threshold-second_degree;
    Poly upper_first=high_part(reduced.second,shift);
    Poly upper_second=high_part(division.second,shift);
    if (upper_second.empty()) return prefix;
    Matrix last_matrix=half_reduce(upper_first,upper_second,heads);
    return compose(last_matrix,prefix);
}
} // namespace resultant_draft
