package problem115

@(export)
problem115 :: proc "c" (min_block_length: i64) -> i64 {
    if min_block_length < 1 || min_block_length > 100 do return -1
    ways: [1024]i64
    for i := 0; i < int(min_block_length); i += 1 { ways[i] = 1 }
    for n := int(min_block_length); n < 1024; n += 1 {
        ways[n] = 1
        for block_length := int(min_block_length); block_length <= n; block_length += 1 {
            for block_start := 0; block_start < n - block_length; block_start += 1 {
                ways[n] += ways[n - block_start - block_length - 1]
            }
            ways[n] += 1
        }
        if ways[n] > 1000000 do return i64(n)
    }
    return -1
}
