/* Part of the Bison parser generator,
   Copyright (C) 1984 Bob Corbett and Free Software Foundation, Inc.

BISON is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY.  No author or distributor accepts responsibility to anyone
for the consequences of using it or for whether it serves any
particular purpose or works at all, unless he says so in writing.
Refer to the BISON General Public License for full details.

Everyone is granted permission to copy, modify and redistribute BISON,
but only under the conditions described in the BISON General Public
License.  A copy of this license is supposed to have been given to you
along with BISON so you can know your rights and responsibilities.  It
should be in a file named COPYING.  Among other things, the copyright
notice and this notice must be preserved on all copies.

 In other words, you are welcome to use, share and improve this program.
 You are forbidden to forbid anyone else to use, share and improve
 what you give them.   Help stamp out software-hoarding!  */

/* Modified 2026: bounded numeric grammar adapter; no upstream code is copied. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_nonterminals = 16;
constexpr int max_terminals = 16;
constexpr int max_rules = 32;
constexpr int max_rhs = 8;
constexpr int max_rhs_items = max_rules * max_rhs;
constexpr std::size_t max_input_length = 3 + max_rules * (2 + max_rhs);
}

extern "C" std::int64_t prolangs_c_bison_nullable(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 5 || length > max_input_length) return -1;
    if (input[0] < 1 || input[0] > max_nonterminals ||
        input[1] < 0 || input[1] > max_terminals ||
        input[2] < 1 || input[2] > max_rules) return -1;
    const int nonterminal_count = static_cast<int>(input[0]);
    const int terminal_count = static_cast<int>(input[1]);
    const int rule_count = static_cast<int>(input[2]);
    std::array<int, max_rules> lhs{}, rhs_start{}, rhs_length{}, remaining{};
    std::array<int, max_rhs_items> rhs{};
    std::array<bool, max_rules> eligible{};
    std::array<bool, max_nonterminals> nullable{};
    std::array<int, max_nonterminals> queue{};
    int rhs_items = 0;
    std::size_t offset = 3;

    for (int rule = 0; rule < rule_count; ++rule) {
        if (offset + 2 > length) return -1;
        if (input[offset] < 0 || input[offset] >= nonterminal_count ||
            input[offset + 1] < 0 || input[offset + 1] > max_rhs) return -1;
        lhs[rule] = static_cast<int>(input[offset++]);
        rhs_length[rule] = static_cast<int>(input[offset++]);
        rhs_start[rule] = rhs_items;
        if (offset + static_cast<std::size_t>(rhs_length[rule]) > length ||
            rhs_items + rhs_length[rule] > max_rhs_items) return -1;
        bool has_terminal = false;
        for (int j = 0; j < rhs_length[rule]; ++j) {
            const std::int64_t symbol = input[offset++];
            if (symbol < 0 || symbol >= nonterminal_count + terminal_count) return -1;
            rhs[rhs_items++] = static_cast<int>(symbol);
            if (symbol >= nonterminal_count) has_terminal = true;
        }
        if (rhs_length[rule] > 0 && !has_terminal) {
            eligible[rule] = true;
            remaining[rule] = rhs_length[rule];
        }
    }
    if (offset != length) return -1;

    int queue_tail = 0;
    for (int rule = 0; rule < rule_count; ++rule) {
        if (rhs_length[rule] == 0 && !nullable[lhs[rule]]) {
            nullable[lhs[rule]] = true;
            queue[queue_tail++] = lhs[rule];
        }
    }
    int queue_head = 0;
    while (queue_head < queue_tail) {
        const int symbol = queue[queue_head++];
        for (int rule = 0; rule < rule_count; ++rule) {
            if (!eligible[rule]) continue;
            for (int j = 0; j < rhs_length[rule]; ++j) {
                if (rhs[rhs_start[rule] + j] == symbol) {
                    --remaining[rule];
                    if (remaining[rule] == 0 && !nullable[lhs[rule]]) {
                        nullable[lhs[rule]] = true;
                        queue[queue_tail++] = lhs[rule];
                    }
                }
            }
        }
    }
    std::int64_t mask = 0;
    for (int symbol = 0; symbol < nonterminal_count; ++symbol)
        if (nullable[symbol]) mask |= std::int64_t{1} << symbol;
    return mask;
}
