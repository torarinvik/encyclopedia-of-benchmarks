// Uncompiled transpose-recursion inverse-transform research draft.
#pragma once
#include "symmetric_group_convolution_fft_forward.hpp"

namespace symmetric_group_fft {
inline std::vector<std::int64_t> invariant_diagonal(const Representation& rep) {
    const std::size_t d = rep.basis.size();
    std::vector<std::int64_t> weights(d,-1);
    std::vector<std::size_t> queue;
    for (std::size_t start=0; start<d; ++start) {
        if (weights[start] != -1) continue;
        weights[start] = 1;
        queue.clear(); queue.push_back(start);
        for (std::size_t head=0; head<queue.size(); ++head) {
            const auto source = queue[head];
            for (const auto& generator : rep.adjacent) {
                const auto& edge = generator[source];
                if (edge.partner_row < 0) continue;
                const auto target = static_cast<std::size_t>(edge.partner_row);
                const auto& back = generator[target];
                if (back.partner_row != static_cast<int>(source) || edge.partner == 0 || back.partner == 0)
                    throw std::logic_error("invalid generator pair");
                const auto candidate = weights[source]*back.partner%modulus*power(edge.partner,modulus-2)%modulus;
                if (weights[target] == -1) { weights[target] = candidate; queue.push_back(target); }
                else if (weights[target] != candidate) throw std::logic_error("inconsistent invariant form");
            }
        }
    }
    return weights;
}

inline Block apply_left_transpose(const Generator& generator, const Block& input) {
    const auto d = generator.size();
    Block result(d*d,0);
    for (std::size_t source=0; source<d; ++source) {
        const auto& column = generator[source];
        for (std::size_t col=0; col<d; ++col) {
            auto value = column.diagonal*input[static_cast<std::size_t>(column.diagonal_row)*d+col]%modulus;
            if (column.partner_row >= 0)
                value = (value+column.partner*input[static_cast<std::size_t>(column.partner_row)*d+col])%modulus;
            result[source*d+col] = value;
        }
    }
    return result;
}

inline std::vector<std::int64_t> transpose_forward(const Levels& levels, int n, const Blocks& gradients) {
    if (n == 1) return {gradients[0][0]};
    const auto& representations = levels[n];
    const auto& subrepresentations = levels[n-1];
    std::vector<std::int64_t> output(factorials[n],0);
    for (int j=0; j<n; ++j) {
        Blocks child;
        child.reserve(subrepresentations.size());
        for (const auto& rep : subrepresentations) {
            const auto width = rep.basis.size(); child.emplace_back(width*width,0);
        }
        for (std::size_t shape=0; shape<representations.size(); ++shape) {
            const auto& rep = representations[shape];
            const std::size_t d = rep.basis.size();
            Block block = gradients[shape];
            // Reverse the palindromic adjacent-generator sequence of forward().
            for (int generator=j; generator<n-1; ++generator)
                block = apply_left_transpose(rep.adjacent[generator],block);
            for (int generator=n-3; generator>=j; --generator)
                block = apply_left_transpose(rep.adjacent[generator],block);
            for (const auto& embedding : rep.restrictions) {
                auto& sub = child[embedding.child_index];
                for (std::size_t row=0; row<embedding.width; ++row)
                    for (std::size_t col=0; col<embedding.width; ++col) {
                        auto& target = sub[row*embedding.width+col];
                        target = (target+block[(embedding.offset+row)*d+embedding.offset+col])%modulus;
                    }
            }
        }
        const auto restricted = transpose_forward(levels,n-1,child);
        std::vector<int> h(static_cast<std::size_t>(n-1));
        std::iota(h.begin(),h.end(),0);
        std::size_t index = 0;
        do {
            auto g=h; g.push_back(n-1);
            for (auto& value : g) {
                if (value == j) value = n-1;
                else if (value == n-1) value = j;
            }
            output[permutation_rank(g)] = restricted[index++];
        } while (std::next_permutation(h.begin(),h.end()));
    }
    return output;
}

inline std::vector<std::int64_t> inverse(const Levels& levels, int n, const Blocks& blocks) {
    if (n == 1) return {blocks[0][0]};
    const auto inverse_order = power(static_cast<std::int64_t>(factorials[n]),modulus-2);
    Blocks weighted;
    weighted.reserve(levels[n].size());
    for (std::size_t shape=0; shape<levels[n].size(); ++shape) {
        const auto& rep = levels[n][shape];
        const auto d = rep.basis.size();
        const auto diagonal = invariant_diagonal(rep);
        std::vector<std::int64_t> inverse_diagonal(d);
        for (std::size_t i=0; i<d; ++i) inverse_diagonal[i] = power(diagonal[i],modulus-2);
        Block block(d*d,0);
        for (std::size_t row=0; row<d; ++row) for (std::size_t col=0; col<d; ++col) {
            auto value = blocks[shape][row*d+col]*static_cast<std::int64_t>(d)%modulus;
            value = value*inverse_order%modulus;
            value = value*diagonal[row]%modulus;
            block[row*d+col] = value*inverse_diagonal[col]%modulus;
        }
        weighted.push_back(std::move(block));
    }
    return transpose_forward(levels,n,weighted);
}
} // namespace symmetric_group_fft
