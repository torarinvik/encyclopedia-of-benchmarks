from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("stable_roommates")
fn stable_roommates(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 58:
        return -1
    if input[0] < 2 or input[0] > 8 or (input[0] & 1) != 0:
        return -1
    let n = Int(input[0])
    if length != c_size_t(1 + n * (n - 1)):
        return -1

    var preference = InlineArray[Int, 64](fill=0)
    var rank = InlineArray[Int, 64](fill=0)
    var cursor = 1
    for person in range(n):
        var seen = InlineArray[Bool, 8](fill=False)
        for position in range(n - 1):
            let raw_other = input[cursor]
            cursor += 1
            if raw_other < 0 or raw_other >= input[0] or raw_other == Int64(person):
                return -1
            let other = Int(raw_other)
            if seen[other]:
                return -1
            seen[other] = True
            preference[person * 8 + position] = other
            rank[person * 8 + other] = position
        preference[person * 8 + n - 1] = person
        rank[person * 8 + person] = n - 1

    var left = InlineArray[Int, 8](fill=0)
    var right = InlineArray[Int, 8](fill=0)
    var proposed_to = InlineArray[Bool, 8](fill=False)
    for person in range(n):
        right[person] = n - 1

    var proposer = 0
    var choice = 0
    for person in range(n):
        proposer = person
        while True:
            choice = preference[proposer * 8 + left[proposer]]
            if choice == proposer:
                return 0
            var current = preference[choice * 8 + right[choice]]
            while rank[choice * 8 + proposer] > rank[choice * 8 + current]:
                left[proposer] += 1
                if left[proposer] >= n:
                    return 0
                choice = preference[proposer * 8 + left[proposer]]
                if choice == proposer:
                    return 0
                current = preference[choice * 8 + right[choice]]
            right[choice] = rank[choice * 8 + proposer]
            proposer = current
            if not proposed_to[choice]:
                break
        proposed_to[choice] = True

    var possible = proposer == choice
    for person in range(n):
        if left[person] > right[person]:
            possible = False
    if not possible:
        return 0

    var second = InlineArray[Int, 8](fill=0)
    for person in range(n):
        second[person] = left[person] + 1
    var first_unmatched = 0
    var first_in_cycle = 0
    var tail = InlineArray[Bool, 8](fill=False)
    var cycle = InlineArray[Int, 18](fill=0)

    while True:
        while first_unmatched < n and left[first_unmatched] == right[first_unmatched]:
            first_unmatched += 1
        if first_unmatched == n:
            for person in range(n):
                if left[person] != right[person]:
                    return 0
                let partner = preference[person * 8 + left[person]]
                if partner == person or preference[partner * 8 + left[partner]] != person:
                    return 0
            return 1

        var person = 0
        var position = 0
        var cycle_set = InlineArray[Bool, 8](fill=False)
        if first_in_cycle > 0:
            person = cycle[first_in_cycle - 1]
            position = first_in_cycle - 1
            for id in range(n):
                cycle_set[id] = tail[id]
        else:
            person = first_unmatched

        while True:
            cycle_set[person] = True
            if position >= 18:
                return 0
            cycle[position] = person
            position += 1

            var list_position = second[person]
            var next_choice = -1
            var found_choice = False
            while list_position < n:
                next_choice = preference[person * 8 + list_position]
                list_position += 1
                if next_choice == person:
                    return 0
                if rank[next_choice * 8 + person] <= right[next_choice]:
                    found_choice = True
                    break
            if not found_choice:
                return 0
            second[person] = list_position - 1
            person = preference[next_choice * 8 + right[next_choice]]
            if cycle_set[person]:
                break

        let last_in_cycle = position - 1
        for id in range(n):
            tail[id] = cycle_set[id]
        var cycle_position = position
        var found_cycle_start = False
        while cycle_position > 0:
            cycle_position -= 1
            tail[cycle[cycle_position]] = False
            if cycle[cycle_position] == person:
                found_cycle_start = True
                break
        if not found_cycle_start:
            return 0
        first_in_cycle = cycle_position

        for cycle_index in range(first_in_cycle, last_in_cycle + 1):
            proposer = cycle[cycle_index]
            left[proposer] = second[proposer]
            second[proposer] = left[proposer] + 1
            choice = preference[proposer * 8 + left[proposer]]
            right[choice] = rank[choice * 8 + proposer]
        for cycle_index in range(first_in_cycle, last_in_cycle + 1):
            if left[cycle[cycle_index]] > right[cycle[cycle_index]]:
                return 0
