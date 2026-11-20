from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_INPUT = 67
const MAX_LITERALS = 48

fn solve(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Int64:
    if length < 2 or length > MAX_INPUT:
        return -1
    let taxa_raw = input[0]
    let characters_raw = input[1]
    if taxa_raw < 1 or taxa_raw > 8 or characters_raw < 0 or characters_raw > 8:
        return -1
    let taxa = Int(taxa_raw)
    let characters = Int(characters_raw)
    if length != 2 + taxa * characters:
        return -1

    var masks = InlineArray[UInt64, 24](fill=0)
    for taxon in range(taxa):
        for character in range(characters):
            let state = input[2 + taxon * characters + character]
            if state < 0 or state > 2:
                return -1
            let at = 3 * character + Int(state)
            masks[at] = masks[at] | (UInt64(1) << taxon)

    var graph = InlineArray[UInt64, 48](fill=0)
    var reverse = InlineArray[UInt64, 48](fill=0)
    for character in range(characters):
        let v0 = 3 * character
        let v1 = v0 + 1
        let v2 = v0 + 2
        var left = 2 * v0
        var right = 2 * v1
        graph[left ^ 1] = graph[left ^ 1] | (UInt64(1) << right)
        reverse[right] = reverse[right] | (UInt64(1) << (left ^ 1))
        graph[right ^ 1] = graph[right ^ 1] | (UInt64(1) << left)
        reverse[left] = reverse[left] | (UInt64(1) << (right ^ 1))
        var present = 0
        var missing = 0
        for state in range(3):
            if masks[3 * character + state] == 0:
                missing = state
            else:
                present += 1
        if present == 2:
            let absent_literal = 2 * (3 * character + missing) + 1
            graph[absent_literal ^ 1] = graph[absent_literal ^ 1] | (UInt64(1) << absent_literal)
            reverse[absent_literal] = reverse[absent_literal] | (UInt64(1) << (absent_literal ^ 1))
        left = 2 * v0
        right = 2 * v2
        graph[left ^ 1] = graph[left ^ 1] | (UInt64(1) << right)
        reverse[right] = reverse[right] | (UInt64(1) << (left ^ 1))
        graph[right ^ 1] = graph[right ^ 1] | (UInt64(1) << left)
        reverse[left] = reverse[left] | (UInt64(1) << (right ^ 1))
        left = 2 * v1
        right = 2 * v2
        graph[left ^ 1] = graph[left ^ 1] | (UInt64(1) << right)
        reverse[right] = reverse[right] | (UInt64(1) << (left ^ 1))
        graph[right ^ 1] = graph[right ^ 1] | (UInt64(1) << left)
        reverse[left] = reverse[left] | (UInt64(1) << (right ^ 1))

    let universe = (UInt64(1) << taxa) - 1
    for left_character in range(characters):
        for right_character in range(left_character + 1, characters):
            for left_state in range(3):
                let left = masks[3 * left_character + left_state]
                for right_state in range(3):
                    let right = masks[3 * right_character + right_state]
                    let all_four = (left & right) != 0 and (left & universe & ~right) != 0 and (right & universe & ~left) != 0 and (universe & ~(left | right)) != 0
                    if all_four:
                        let left_variable = 3 * left_character + left_state
                        let right_variable = 3 * right_character + right_state
                        let a = 2 * left_variable + 1
                        let b = 2 * right_variable + 1
                        graph[a ^ 1] = graph[a ^ 1] | (UInt64(1) << b)
                        reverse[b] = reverse[b] | (UInt64(1) << (a ^ 1))
                        graph[b ^ 1] = graph[b ^ 1] | (UInt64(1) << a)
                        reverse[a] = reverse[a] | (UInt64(1) << (b ^ 1))

    let literal_count = 6 * characters
    var seen = InlineArray[Bool, 48](fill=False)
    var order = InlineArray[Int, 48](fill=0)
    var stack = InlineArray[Int, 48](fill=0)
    var next_index = InlineArray[Int, 48](fill=0)
    var order_count = 0
    for start in range(literal_count):
        if seen[start]:
            continue
        var top = 1
        stack[0] = start
        seen[start] = True
        while top > 0:
            let vertex = stack[top - 1]
            var next = next_index[vertex]
            while next < literal_count and (((graph[vertex] >> next) & 1) == 0 or seen[next]):
                next += 1
            if next < literal_count:
                next_index[vertex] = next + 1
                seen[next] = True
                stack[top] = next
                top += 1
            else:
                order[order_count] = vertex
                order_count += 1
                top -= 1
    var component = InlineArray[Int, 48](fill=-1)
    var label = 0
    while order_count > 0:
        order_count -= 1
        let start = order[order_count]
        if component[start] >= 0:
            continue
        var top = 1
        stack[0] = start
        component[start] = label
        while top > 0:
            top -= 1
            let vertex = stack[top]
            for next in range(literal_count):
                if ((reverse[vertex] >> next) & 1) != 0 and component[next] < 0:
                    component[next] = label
                    stack[top] = next
                    top += 1
        label += 1
    for variable in range(3 * characters):
        if component[2 * variable] == component[2 * variable + 1]:
            return 0
    return 1

@export("perfect_phylogeny_three_state_2sat")
fn perfect_phylogeny_three_state_2sat(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT:
        return -1
    return solve(input, Int(length))
