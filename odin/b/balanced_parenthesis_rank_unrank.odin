// Clean-room completion-count dynamic programming for Dyck-word rank/unrank.
package balanced_parenthesis_rank_unrank

import "core:c"

MAX_PAIRS :: 10
MAX_INPUT_LENGTH :: 22
WAYS_STRIDE :: 11
WAYS_COUNT :: 231

@(export)
balanced_parenthesis_rank_unrank :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
    mode, pair_value := input[0], input[1]
    if pair_value < 1 || pair_value > MAX_PAIRS do return -1
    pairs, sequence_length := int(pair_value), 2*int(pair_value)
    if mode == 0 {
        if length != c.size_t(2+sequence_length) do return -1
        balance := 0
        for i := 0; i < sequence_length; i += 1 {
            symbol := input[2+i]
            if symbol != 0 && symbol != 1 do return -1
            if symbol == 0 do balance += 1 else do balance -= 1
            if balance < 0 do return -1
        }
        if balance != 0 do return -1
    } else if mode == 1 {
        if length != 3 do return -1
    } else {
        return -1
    }

    ways: [WAYS_COUNT]i64
    ways[0] = 1
    for remaining := 1; remaining <= sequence_length; remaining += 1 {
        for balance := 0; balance <= pairs; balance += 1 {
            count := i64(0)
            if balance < pairs do count += ways[(remaining-1)*WAYS_STRIDE+balance+1]
            if balance > 0 do count += ways[(remaining-1)*WAYS_STRIDE+balance-1]
            ways[remaining*WAYS_STRIDE+balance] = count
        }
    }

    if mode == 0 {
        rank := i64(0)
        balance := 0
        for i := 0; i < sequence_length; i += 1 {
            symbol := input[2+i]
            remaining := sequence_length-i-1
            if symbol == 1 && balance < pairs do rank += ways[remaining*WAYS_STRIDE+balance+1]
            if symbol == 0 do balance += 1 else do balance -= 1
        }
        return rank
    }

    rank := input[2]
    if rank < 0 || rank >= ways[sequence_length*WAYS_STRIDE] do return -1
    balance := 0
    code := i64(0)
    for i := 0; i < sequence_length; i += 1 {
        remaining := sequence_length-i-1
        opening_count := i64(0)
        if balance < pairs do opening_count = ways[remaining*WAYS_STRIDE+balance+1]
        symbol := i64(0)
        if rank < opening_count do balance += 1 else {
            rank -= opening_count
            symbol = 1
            balance -= 1
        }
        code = (code << 1) | symbol
    }
    return code
}
