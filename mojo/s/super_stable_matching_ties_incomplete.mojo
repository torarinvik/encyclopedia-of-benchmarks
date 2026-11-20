from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N = 4
const MAX_PARSEABLE_LENGTH = 34

fn solve(values: InlineArray[Int64, 34], length: Int) -> Int64:
    if length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    let n_raw = values[0]
    if n_raw < 1 or n_raw > MAX_N:
        return -1
    let n = Int(n_raw)
    if length != 1 + 2 * n * n:
        return -1
    let side = n * n
    var men_rank = InlineArray[Int64, 16](fill=0)
    var women_rank = InlineArray[Int64, 16](fill=0)
    for man in range(n):
        for woman in range(n):
            let rank = values[1 + man * n + woman]
            if rank < 0 or rank > n_raw:
                return -1
            men_rank[man * MAX_N + woman] = rank
    for woman in range(n):
        for man in range(n):
            let rank = values[1 + side + woman * n + man]
            if rank < 0 or rank > n_raw or ((rank > 0) != (men_rank[man * MAX_N + woman] > 0)):
                return -1
            women_rank[woman * MAX_N + man] = rank
    for person in range(n):
        var maximum: Int64 = 0
        for partner in range(n):
            if men_rank[person * MAX_N + partner] > maximum:
                maximum = men_rank[person * MAX_N + partner]
        var level: Int64 = 1
        while level <= maximum:
            var found = False
            for partner in range(n):
                if men_rank[person * MAX_N + partner] == level:
                    found = True
            if not found:
                return -1
            level += 1
        maximum = 0
        for partner in range(n):
            if women_rank[person * MAX_N + partner] > maximum:
                maximum = women_rank[person * MAX_N + partner]
        level = 1
        while level <= maximum:
            var found = False
            for partner in range(n):
                if women_rank[person * MAX_N + partner] == level:
                    found = True
            if not found:
                return -1
            level += 1

    var alive = InlineArray[Bool, 16](fill=False)
    var engaged = InlineArray[Bool, 16](fill=False)
    var proposed = InlineArray[Bool, 4](fill=False)
    for man in range(n):
        for woman in range(n):
            alive[man * MAX_N + woman] = men_rank[man * MAX_N + woman] > 0
    while True:
        var proposer = -1
        for man in range(n):
            var has_engagement = False
            var has_choice = False
            for woman in range(n):
                let index = man * MAX_N + woman
                if engaged[index]:
                    has_engagement = True
                if alive[index]:
                    has_choice = True
            if proposer < 0 and not has_engagement and has_choice:
                proposer = man
        if proposer < 0:
            break
        var head_rank = n_raw + 1
        for woman in range(n):
            let index = proposer * MAX_N + woman
            if alive[index] and men_rank[index] < head_rank:
                head_rank = men_rank[index]
        for woman in range(n):
            let index = proposer * MAX_N + woman
            if not alive[index] or men_rank[index] != head_rank:
                continue
            proposed[woman] = True
            engaged[index] = True
            for successor in range(n):
                let successor_index = successor * MAX_N + woman
                if alive[successor_index]
                    and women_rank[woman * MAX_N + successor] > women_rank[woman * MAX_N + proposer]:
                    engaged[successor_index] = False
                    alive[successor_index] = False
        for woman in range(n):
            var count = 0
            var tail_rank: Int64 = 0
            for man in range(n):
                let index = man * MAX_N + woman
                if engaged[index]:
                    count += 1
                if alive[index] and women_rank[woman * MAX_N + man] > tail_rank:
                    tail_rank = women_rank[woman * MAX_N + man]
            if count > 1:
                for man in range(n):
                    let index = man * MAX_N + woman
                    engaged[index] = False
                    if alive[index] and women_rank[woman * MAX_N + man] == tail_rank:
                        alive[index] = False

    let base = n_raw + 1
    var limit: Int64 = 1
    for _ in range(n):
        limit *= base
    var best_code: Int64 = 0
    var best_size = -1
    for code in range(Int(limit)):
        var used = 0
        var size = 0
        var valid = True
        var place = limit // base
        for man in range(n):
            let woman = Int((Int64(code) // place) % base)
            if woman < n:
                let bit = 1 << woman
                if not engaged[man * MAX_N + woman] or (used & bit) != 0:
                    valid = False
                used |= bit
                size += 1
            if man + 1 < n:
                place //= base
        if valid and size > best_size:
            best_size = size
            best_code = Int64(code)
    var matched = InlineArray[Bool, 4](fill=False)
    var place = limit // base
    for man in range(n):
        let woman = Int((best_code // place) % base)
        if woman < n:
            matched[woman] = True
        if man + 1 < n:
            place //= base
    for woman in range(n):
        if proposed[woman] and not matched[woman]:
            return -2
    return best_code

@export("super_stable_matching_ties_incomplete")
fn super_stable_matching_ties_incomplete(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1
        or length > MAX_PARSEABLE_LENGTH:
        return -1
    var values = InlineArray[Int64, 34](fill=0)
    for index in range(Int(length)):
        values[index] = input[index]
    return solve(values, Int(length))
