package magic_sequence

import "core:c"

MAX_N :: 11
FNV_OFFSET_BASIS :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)
I64_RESULT_MASK :: u64(0x7fff_ffff_ffff_ffff)

fnv_byte :: proc "contextless" (hash: ^u64, value: u8) {
    hash^ = ((hash^) ^ u64(value)) * FNV_PRIME
}

enumerate :: proc "contextless" (n: int, hash: ^u64, hash_rows: bool) -> u32 {
    if n == 0 do return 1

    vector := [11]u8{}
    frequencies := [11]u8{}
    next_candidate := [11]u8{}
    prefix_sum := [12]u8{}
    depth := 0
    solution_count := u32(0)

    for {
        if depth == n {
            is_magic := true
            for symbol := 0; symbol < n; symbol += 1 {
                if frequencies[symbol] != vector[symbol] {
                    is_magic = false
                    break
                }
            }
            if is_magic {
                solution_count += 1
                if hash_rows {
                    for index := 0; index < n; index += 1 {
                        fnv_byte(hash, vector[index])
                    }
                }
            }
            depth -= 1
            frequencies[int(vector[depth])] -= 1
            continue
        }

        candidate := next_candidate[depth]
        if int(candidate) >= n {
            next_candidate[depth] = 0
            if depth == 0 do break
            depth -= 1
            frequencies[int(vector[depth])] -= 1
            continue
        }
        next_candidate[depth] = candidate + 1
        sum := int(prefix_sum[depth]) + int(candidate)
        if sum > n do continue

        vector[depth] = candidate
        frequencies[int(candidate)] += 1
        prefix_sum[depth + 1] = u8(sum)
        depth += 1
        next_candidate[depth] = 0
    }
    return solution_count
}

@(export)
magic_sequence :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length != 1 do return -1
    n_value := input[0]
    if n_value < 0 || n_value > MAX_N do return -1
    n := int(n_value)

    hash := FNV_OFFSET_BASIS
    fnv_byte(&hash, u8(n))
    solution_count := enumerate(n, &hash, false)
    for shift := u32(0); shift < 32; shift += 8 {
        fnv_byte(&hash, u8(solution_count >> shift))
    }
    enumerate(n, &hash, true)
    return i64(hash & I64_RESULT_MASK)
}
