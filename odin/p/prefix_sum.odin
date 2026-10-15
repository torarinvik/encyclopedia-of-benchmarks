package prefix_sum

import "core:c"

MAX_LENGTH :: 256
HASH_CAPACITY :: 1024

store_i64_le :: proc "c" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}
hash_key :: proc(key: i64) -> int { bucket := key % HASH_CAPACITY; if bucket < 0 do bucket += HASH_CAPACITY; return int(bucket) }
contains_sum :: proc(prefix: [^]i64, count: int, target: i64) -> bool {
    keys: [HASH_CAPACITY]i64
    used: [HASH_CAPACITY]bool
    slot := hash_key(0); used[slot] = true; keys[slot] = 0
    for ending := 1; ending <= count; ending += 1 {
        wanted := prefix[ending] - target; slot = hash_key(wanted)
        for used[slot] && keys[slot] != wanted { slot = (slot + 1) % HASH_CAPACITY }
        if used[slot] do return true
        slot = hash_key(prefix[ending])
        for used[slot] && keys[slot] != prefix[ending] { slot = (slot + 1) % HASH_CAPACITY }
        if !used[slot] { used[slot] = true; keys[slot] = prefix[ending] }
    }
    return false
}

@(export)
prefix_sum :: proc "c" (input: [^]i64, length: c.size_t,
                         output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || input[0] < 0 || input[0] > 2 || input[1] < 0 || input[1] > MAX_LENGTH do return -1
    operation := int(input[0]); count := int(input[1]); extra := 0
    if operation == 1 { extra = 2 } else if operation == 2 { extra = 1 }
    if int(length) != 2 + count + extra || (operation == 1 && count == 0) do return -1
    for i := 0; i < count; i += 1 { if input[2+i] < -2147483648 || input[2+i] > 2147483647 do return -1 }
    if operation == 1 { left,right:=input[2+count],input[3+count];if left<0||right<left||right>=i64(count)do return -1 }
    if operation == 2 && (input[2+count] < -1000000000000 || input[2+count] > 1000000000000) do return -1
    prefix: [MAX_LENGTH+1]i64
    for i := 0; i < count; i += 1 { prefix[i+1] = prefix[i] + input[2+i] }
    words := count; if operation != 0 { words = 1 }
    if int(output_capacity) < words*8 || (words > 0 && output == nil) do return -2
    if operation == 0 { for i:=0;i<count;i+=1 { store_i64_le(output,i*8,prefix[i+1]) }; return i64(count) }
    result := i64(0)
    if operation == 1 { result = prefix[int(input[3+count])+1] - prefix[int(input[2+count])] }
    else if contains_sum(&prefix[0],count,input[2+count]) { result = 1 }
    store_i64_le(output,0,result)
    return 1
}
