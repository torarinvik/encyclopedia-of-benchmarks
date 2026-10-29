package point_set_range_composite

import "core:c"

Modulus :: i64(998244353)
Max_N :: 16
Max_Operations :: 32
Max_Input_Length :: 162
Tree_Capacity :: 64

Affine_Map :: struct { a, b: i64 }
Tree :: struct { nodes: [Tree_Capacity]Affine_Map }

identity_map :: proc() -> Affine_Map {
    return {1, 0}
}

compose :: proc(left, right: Affine_Map) -> Affine_Map {
    return {
        (right.a * left.a) % Modulus,
        (right.a * left.b + right.b) % Modulus,
    }
}

@(export)
point_set_range_composite :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > c.size_t(Max_Input_Length) do return -1
    n_value, q_value := values[0], values[1]
    if n_value < 1 || n_value > i64(Max_N) || q_value < 0 || q_value > i64(Max_Operations) do return -1
    n, q := int(n_value), int(q_value)
    if int(length) != 2 + 2*n + 4*q do return -1

    for i := 0; i < n; i += 1 {
        a, b := values[2 + 2*i], values[3 + 2*i]
        if a < 0 || a >= Modulus || b < 0 || b >= Modulus do return -1
    }

    base := 1
    for base < n do base *= 2
    tree := Tree{}
    for i := 0; i < Tree_Capacity; i += 1 do tree.nodes[i] = identity_map()
    for i := 0; i < n; i += 1 {
        tree.nodes[base + i] = {values[2 + 2*i], values[3 + 2*i]}
    }
    for node := base - 1; node > 0; node -= 1 {
        tree.nodes[node] = compose(tree.nodes[2*node], tree.nodes[2*node + 1])
    }

    checksum, query_number: i64 = 0, 0
    cursor := 2 + 2*n
    for _ := 0; _ < q; _ += 1 {
        opcode, first, second, third := values[cursor], values[cursor+1], values[cursor+2], values[cursor+3]
        cursor += 4
        if opcode == 0 {
            if first < 0 || first >= n_value || second < 0 || second >= Modulus || third < 0 || third >= Modulus do return -1
            node := base + int(first)
            tree.nodes[node] = {second, third}
            for node > 1 {
                node /= 2
                tree.nodes[node] = compose(tree.nodes[2*node], tree.nodes[2*node + 1])
            }
        } else if opcode == 1 {
            if first < 0 || first > second || second > n_value || third < 0 || third >= Modulus do return -1
            left_index, right_index := base + int(first), base + int(second)
            left, right := identity_map(), identity_map()
            for left_index < right_index {
                if left_index & 1 == 1 {
                    left = compose(left, tree.nodes[left_index])
                    left_index += 1
                }
                if right_index & 1 == 1 {
                    right_index -= 1
                    right = compose(tree.nodes[right_index], right)
                }
                left_index /= 2
                right_index /= 2
            }
            combined := compose(left, right)
            answer := (combined.a * third + combined.b) % Modulus
            query_number += 1
            checksum = (checksum + query_number*answer) % Modulus
        } else {
            return -1
        }
    }
    if cursor != int(length) do return -1
    return checksum
}
