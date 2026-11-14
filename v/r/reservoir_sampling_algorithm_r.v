module reservoir_sampling_algorithm_r

@[export: 'reservoir_sampling_algorithm_r']
pub fn reservoir_sampling_algorithm_r(input &i64, length usize, output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 2 || length > 130 { return -1 }
    nv := unsafe { input[0] }
    kv := unsafe { input[1] }
    if nv < 0 || nv > 64 || kv < 0 || kv > nv { return -1 }
    n := int(nv)
    k := int(kv)
    if length != usize(2+2*n-k) { return -1 }
    for i in 0 .. n {
        value := unsafe { input[2+i] }
        if value < -1000000 || value > 1000000 { return -1 }
    }
    for i in k .. n {
        draw := unsafe { input[2+n+i-k] }
        if draw < 0 || draw > i64(i) { return -1 }
    }
    if unsafe { output == nil } || capacity < usize(8*k) { return -2 }
    mut reservoir := [64]i64{}
    for i in 0 .. k { reservoir[i] = unsafe { input[2+i] } }
    for i in k .. n {
        draw := int(unsafe { input[2+n+i-k] })
        if draw < k { reservoir[draw] = unsafe { input[2+i] } }
    }
    for i in 0 .. k {
        mut encoded := if reservoir[i] < 0 { ~u64(-reservoir[i]-1) } else { u64(reservoir[i]) }
        for j in 0 .. 8 {
            unsafe { output[8*i+j] = u8(encoded & 255) }
            encoded >>= 8
        }
    }
    return i64(8*k)
}
