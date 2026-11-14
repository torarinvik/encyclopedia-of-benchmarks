// Uncompiled and unexecuted algorithm draft; no benchmark export yet.
#pragma once
#include "polynomial_resultant_half_gcd_reduction.hpp"

namespace resultant_draft {

// Both inputs are canonical, nonzero field polynomials. This kernel leaves
// input-frame validation to the future benchmark entry point.
inline Coeff resultant(Poly a, Poly b) {
    Coeff answer=1;
    if (a.size()<b.size()) {
        if (((a.size()-1)&1) && ((b.size()-1)&1)) answer=prime-answer;
        std::swap(a,b);
    }
    while (true) {
        if (b.size()==1) return answer*power(b[0],a.size()-1)%prime;

        // Equal degrees need one ordinary division before strict-order HGCD.
        if (a.size()==b.size()) {
            auto division=divide(a,b);
            if (division.second.empty()) return 0;
            const std::size_t da=a.size()-1, db=b.size()-1;
            const std::size_t dr=division.second.size()-1;
            if ((da&1) && (db&1)) answer=prime-answer;
            answer=answer*power(b.back(),da-dr)%prime;
            a=std::move(b); b=std::move(division.second);
            continue;
        }

        std::vector<QuotientHead> heads;
        Matrix matrix=half_reduce(a,b,&heads);
        auto reduced=apply(matrix,a,b);
        if (heads.empty()) {
            // The second input already lies below the half-degree threshold.
            auto division=divide(a,b);
            if (division.second.empty()) return 0;
            const std::size_t da=a.size()-1, db=b.size()-1;
            const std::size_t dr=division.second.size()-1;
            if ((da&1) && (db&1)) answer=prime-answer;
            answer=answer*power(b.back(),da-dr)%prime;
            a=std::move(b); b=std::move(division.second);
            continue;
        }
        // Since the last divisor had degree at least the positive cutoff,
        // a zero final remainder means a nonconstant common factor.
        if (reduced.second.empty()) return 0;

        std::size_t da=a.size()-1, db=b.size()-1;
        Coeff leading=b.back();
        for (std::size_t i=0; i<heads.size(); ++i) {
            // The next quotient reveals the degree and leading coefficient
            // of this step's remainder. The final remainder comes from the
            // full lifted pair, never from a truncated recursive result.
            const bool last=i+1==heads.size();
            const std::size_t dr=last ? reduced.second.size()-1
                                      : db-heads[i+1].degree;
            if ((da&1) && (db&1)) answer=prime-answer;
            answer=answer*power(leading,da-dr)%prime;
            if (!last) leading=leading*power(heads[i+1].leading,prime-2)%prime;
            da=db; db=dr;
        }
        a=std::move(reduced.first); b=std::move(reduced.second);
    }
}
} // namespace resultant_draft
