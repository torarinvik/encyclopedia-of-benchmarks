package key_priority_queue

import "core:c"

@(export)
key_priority_queue :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 98 || input[0] < 0 || input[0] > 32 do return -1
    keys: [32]i64
    priorities: [32]i64
    answers: [32]i64
    n, out_n, pos: c.size_t = 0, 0, 1
    for opi: c.size_t = 0; opi < c.size_t(input[0]); opi += 1 {
        if pos >= length do return -1
        op := input[pos]
        if op == 0 || op == 1 {
            if pos + 2 >= length do return -1
            key, priority := input[pos+1], input[pos+2]
            if key < -1_000_000_000 || key > 1_000_000_000 || priority < -1_000_000_000 || priority > 1_000_000_000 do return -1
            pos += 3
            found := n
            for i: c.size_t = 0; i < n; i += 1 { if keys[i] == key { found = i; break } }
            if op == 0 {
                if found != n do return -1
                keys[n], priorities[n] = key, priority
                i := n
                for i > 0 { parent := (i-1)/2; if priorities[parent] <= priorities[i] do break
                    keys[parent], keys[i] = keys[i], keys[parent]; priorities[parent], priorities[i] = priorities[i], priorities[parent]; i = parent }
                n += 1
            } else if found == n {
                keys[n], priorities[n] = key, priority
                i := n
                for i > 0 { parent := (i-1)/2; if priorities[parent] <= priorities[i] do break
                    keys[parent], keys[i] = keys[i], keys[parent]; priorities[parent], priorities[i] = priorities[i], priorities[parent]; i = parent }
                n += 1
            } else {
                priorities[found] = priority
                if found > 0 && priorities[(found-1)/2] > priority {
                    i := found
                    for i > 0 { parent := (i-1)/2; if priorities[parent] <= priorities[i] do break
                        keys[parent], keys[i] = keys[i], keys[parent]; priorities[parent], priorities[i] = priorities[i], priorities[parent]; i = parent }
                } else {
                    left, right := 2*found+1, 2*found+2
                    if (left < n && priorities[left] < priority) || (right < n && priorities[right] < priority) {
                        i := found
                        for 2*i+1 < n { l, r := 2*i+1, 2*i+2; child := n
                            if priorities[l] < priorities[i] && (r >= n || priorities[l] < priorities[r]) { child = l }
                            else if r < n && priorities[r] < priorities[i] { child = r } else { break }
                            keys[i], keys[child] = keys[child], keys[i]; priorities[i], priorities[child] = priorities[child], priorities[i]; i = child
                        }
                    }
                }
            }
        } else if op == 2 {
            pos += 1
            if n == 0 do return -1
            keys[0], keys[n-1] = keys[n-1], keys[0]; priorities[0], priorities[n-1] = priorities[n-1], priorities[0]
            n -= 1; answers[out_n] = keys[n]; out_n += 1
            if n > 0 { i: c.size_t = 0; for 2*i+1 < n { l, r := 2*i+1, 2*i+2; child := n
                if priorities[l] < priorities[i] && (r >= n || priorities[l] < priorities[r]) { child = l }
                else if r < n && priorities[r] < priorities[i] { child = r } else { break }
                keys[i], keys[child] = keys[child], keys[i]; priorities[i], priorities[child] = priorities[child], priorities[i]; i = child
            } }
        } else if op == 3 {
            if pos + 1 >= length do return -1
            key := input[pos+1]
            if key < -1_000_000_000 || key > 1_000_000_000 do return -1
            pos += 2; present := false
            for i: c.size_t = 0; i < n; i += 1 { if keys[i] == key { present = true; break } }
            answers[out_n] = i64(present); out_n += 1
        } else if op == 4 { pos += 1; answers[out_n] = i64(n == 0); out_n += 1 }
        else { return -1 }
    }
    if pos != length do return -1
    bytes := out_n * 8
    if output == nil || output_capacity < bytes do return -2
    for i: c.size_t = 0; i < out_n; i += 1 { bits := u64(answers[i]); for b: c.size_t = 0; b < 8; b += 1 { output[8*i+b] = u8(bits >> (8*b)) } }
    return i64(bytes)
}
