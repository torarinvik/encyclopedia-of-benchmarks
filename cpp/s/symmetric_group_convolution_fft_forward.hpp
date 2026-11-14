// Uncompiled subgroup-chain forward-transform research draft.
#pragma once
#include "symmetric_group_convolution_fft_plan.hpp"
#include <numeric>

namespace symmetric_group_fft {
using Block = std::vector<std::int64_t>;
using Blocks = std::vector<Block>;
constexpr std::array<std::size_t,10> factorials = {1,1,2,6,24,120,720,5040,40320,362880};

inline std::size_t permutation_rank(const std::vector<int>& permutation) {
    std::size_t rank = 0;
    for (std::size_t i=0; i<permutation.size(); ++i) {
        std::size_t less = 0;
        for (std::size_t j=i+1; j<permutation.size(); ++j)
            if (permutation[j] < permutation[i]) ++less;
        rank += less*factorials[permutation.size()-1-i];
    }
    return rank;
}

inline Block apply_left(const Generator& generator, const Block& input) {
    const std::size_t d = generator.size();
    Block result(d*d,0);
    for (std::size_t source=0; source<d; ++source) {
        const auto& column = generator[source];
        for (std::size_t col=0; col<d; ++col) {
            const auto value = input[source*d+col];
            auto& diagonal = result[static_cast<std::size_t>(column.diagonal_row)*d+col];
            diagonal = (diagonal + column.diagonal*value)%modulus;
            if (column.partner_row >= 0) {
                auto& partner = result[static_cast<std::size_t>(column.partner_row)*d+col];
                partner = (partner + column.partner*value)%modulus;
            }
        }
    }
    return result;
}

inline Blocks forward(const Levels& levels, int n, const std::vector<std::int64_t>& input) {
    if (n == 1) return Blocks{Block{input[0]}};
    const auto& representations = levels[n];
    Blocks output;
    output.reserve(representations.size());
    for (const auto& representation : representations) {
        const auto d = representation.basis.size();
        output.emplace_back(d*d,0);
    }
    for (int j=0; j<n; ++j) {
        std::vector<std::int64_t> restricted;
        restricted.reserve(factorials[n-1]);
        std::vector<int> h(static_cast<std::size_t>(n-1));
        std::iota(h.begin(),h.end(),0);
        do {
            auto g = h; g.push_back(n-1);
            for (auto& value : g) {
                if (value == j) value = n-1;
                else if (value == n-1) value = j;
            }
            restricted.push_back(input[permutation_rank(g)]);
        } while (std::next_permutation(h.begin(),h.end()));
        const auto child = forward(levels,n-1,restricted);
        for (std::size_t shape=0; shape<representations.size(); ++shape) {
            const auto& rep = representations[shape];
            const std::size_t d = rep.basis.size();
            Block embedded(d*d,0);
            for (const auto& embedding : rep.restrictions) {
                const auto& sub = child[embedding.child_index];
                for (std::size_t row=0; row<embedding.width; ++row)
                    for (std::size_t col=0; col<embedding.width; ++col)
                        embedded[(embedding.offset+row)*d+embedding.offset+col] = sub[row*embedding.width+col];
            }
            for (int generator=j; generator<n-1; ++generator)
                embedded = apply_left(rep.adjacent[generator],embedded);
            for (int generator=n-3; generator>=j; --generator)
                embedded = apply_left(rep.adjacent[generator],embedded);
            for (std::size_t i=0; i<embedded.size(); ++i)
                output[shape][i] = (output[shape][i]+embedded[i])%modulus;
        }
    }
    return output;
}
} // namespace symmetric_group_fft
