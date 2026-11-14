// Uncompiled research draft. Mathematical method from the package references;
// this independently written helper is not yet a benchmark implementation.
#pragma once
#include <algorithm>
#include <array>
#include <cstdint>
#include <map>
#include <stdexcept>
#include <utility>
#include <vector>

namespace symmetric_group_fft {
constexpr std::int64_t modulus = 998244353;
using Shape = std::array<int, 9>;
// Cell is row*9+column; index in the array is the tableau entry.
using Tableau = std::array<int, 9>;

inline std::int64_t power(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent) {
        if (exponent & 1) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

inline bool last_cell_first(const Tableau& a, const Tableau& b, int n) {
    for (int i = n-1; i >= 0; --i) {
        if (a[i] != b[i]) return a[i] < b[i];
    }
    return false;
}

using Bases = std::map<Shape, std::vector<Tableau>>;
inline void enumerate_tableaux(int n, int next, Shape& shape, Tableau& tableau, Bases& bases) {
    if (next == n) { bases[shape].push_back(tableau); return; }
    for (int row = 0; row < n; ++row) {
        // Append a cell only if the rows remain weakly decreasing. Once the
        // first empty row is used, later empty rows would create a gap.
        if (row > 0 && shape[row] >= shape[row-1]) continue;
        const int column = shape[row];
        tableau[next] = row*9+column;
        ++shape[row];
        enumerate_tableaux(n, next+1, shape, tableau, bases);
        --shape[row];
        if (column == 0) break;
    }
}

struct SparseColumn {
    int diagonal_row;
    int partner_row; // -1 for a one-entry column
    std::int64_t diagonal;
    std::int64_t partner;
};
using Generator = std::vector<SparseColumn>;

inline std::vector<Generator> generators(const std::vector<Tableau>& basis, int n) {
    const auto less = [n](const Tableau& a, const Tableau& b) { return last_cell_first(a,b,n); };
    std::vector<Generator> result;
    result.reserve(static_cast<std::size_t>(n-1));
    for (int label = 0; label+1 < n; ++label) {
        Generator columns;
        columns.reserve(basis.size());
        for (std::size_t index = 0; index < basis.size(); ++index) {
            const int first = basis[index][label], second = basis[index][label+1];
            const int distance = (second%9-second/9)-(first%9-first/9);
            if (distance == 0) throw std::logic_error("equal adjacent tableau contents");
            const auto normalized = (distance + modulus) % modulus;
            const auto diagonal = power(normalized, modulus-2);
            if (distance == 1 || distance == -1) {
                columns.push_back({static_cast<int>(index), -1, diagonal, 0});
                continue;
            }
            Tableau swapped = basis[index];
            std::swap(swapped[label], swapped[label+1]);
            auto partner = std::lower_bound(basis.begin(), basis.end(), swapped, less);
            if (partner == basis.end() || less(swapped,*partner) || less(*partner,swapped))
                throw std::logic_error("missing exchanged tableau");
            const auto coefficient = distance > 0 ? 1 : (1-diagonal*diagonal%modulus+modulus)%modulus;
            columns.push_back({static_cast<int>(index), static_cast<int>(partner-basis.begin()), diagonal, coefficient});
        }
        result.push_back(std::move(columns));
    }
    return result;
}

struct Embedding {
    std::size_t child_index;
    std::size_t offset;
    std::size_t width;
};

struct Representation {
    Shape shape;
    std::vector<Tableau> basis;
    std::vector<Generator> adjacent;
    std::vector<Embedding> restrictions;
};

inline std::vector<Representation> representation_plan(int n) {
    if (n < 1 || n > 9) throw std::invalid_argument("unsupported group degree");
    Shape shape{}; Tableau tableau{}; Bases bases;
    enumerate_tableaux(n, 0, shape, tableau, bases);
    std::vector<Representation> result;
    result.reserve(bases.size());
    for (auto& entry : bases) {
        auto& basis = entry.second;
        std::sort(basis.begin(), basis.end(), [n](const Tableau& a, const Tableau& b) {
            return last_cell_first(a,b,n);
        });
        auto adjacent = generators(basis,n);
        result.push_back({entry.first, std::move(basis), std::move(adjacent), {}});
    }
    return result;
}

using Levels = std::vector<std::vector<Representation>>;

inline Levels make_levels(int n) {
    if (n < 1 || n > 9) throw std::invalid_argument("unsupported group degree");
    Levels levels(static_cast<std::size_t>(n+1));
    for (int degree = 1; degree <= n; ++degree)
        levels[degree] = representation_plan(degree);
    for (int degree = 2; degree <= n; ++degree) {
        auto& parents = levels[degree];
        const auto& children = levels[degree-1];
        for (auto& parent : parents) {
            std::size_t start = 0;
            while (start < parent.basis.size()) {
                const int corner = parent.basis[start][degree-1];
                std::size_t end = start+1;
                while (end < parent.basis.size() && parent.basis[end][degree-1] == corner) ++end;
                Shape child_shape = parent.shape;
                --child_shape[corner/9];
                const auto found = std::find_if(children.begin(), children.end(),
                    [&child_shape](const Representation& child) { return child.shape == child_shape; });
                if (found == children.end() || found->basis.size() != end-start)
                    throw std::logic_error("missing restriction block");
                for (std::size_t k=0; k<end-start; ++k) {
                    for (int label=0; label<degree-1; ++label) {
                        if (parent.basis[start+k][label] != found->basis[k][label])
                            throw std::logic_error("restriction ordering differs");
                    }
                }
                parent.restrictions.push_back({static_cast<std::size_t>(found-children.begin()), start, end-start});
                start = end;
            }
        }
    }
    return levels;
}
} // namespace symmetric_group_fft
