// Clean-room bounded work-function algorithm for finite k-server metrics.
package work_function_k_server

import "core:c"

MAX_P :: 6
MAX_K :: 3
MAX_R :: 8
MAX_CONFIGS :: 20
MAX_INPUT :: 50
INF :: i64(9223372036854775807)

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}
sort_cfg :: proc(x: [^]i64, k: int) {
    for i := 0; i < k; i += 1 { for j := i+1; j < k; j += 1 { if x[j] < x[i] { x[i],x[j]=x[j],x[i] } } }
}
find_cfg :: proc(configs: [^]i64, count: int, x: [^]i64, k: int) -> int {
    for i := 0; i < count; i += 1 {
        same := true
        for j := 0; j < k; j += 1 { if configs[i*MAX_K+j] != x[j] { same = false } }
        if same do return i
    }
    return count
}
cfg_dist :: proc(a,b: [^]i64, k: int, metric: [^]i64, p: int) -> i64 {
    if k == 1 do return metric[int(a[0])*p+int(b[0])]
    if k == 2 {
        x := metric[int(a[0])*p+int(b[0])] + metric[int(a[1])*p+int(b[1])]
        y := metric[int(a[0])*p+int(b[1])] + metric[int(a[1])*p+int(b[0])]
        return min(x,y)
    }
    perms: [6][3]int = {{0,1,2},{0,2,1},{1,0,2},{1,2,0},{2,0,1},{2,1,0}}
    best := INF
    for q in 0..<6 {
        value := metric[int(a[0])*p+int(b[perms[q][0]])] + metric[int(a[1])*p+int(b[perms[q][1]])] + metric[int(a[2])*p+int(b[perms[q][2]])]
        if value < best { best = value }
    }
    return best
}

@(export)
work_function_k_server :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT do return -1
    p64,k64,n64 := input[0],input[1],input[2]
    if p64 < 2 || p64 > 6 || k64 < 1 || k64 > 3 || k64 > p64 || n64 < 0 || n64 > 8 do return -1
    p,k,n := int(p64),int(k64),int(n64)
    initial_at := 3+p*p; requests_at := initial_at+k
    if length != c.size_t(requests_at+n) do return -1
    metric: [MAX_P*MAX_P]i64
    for i := 0; i < p; i += 1 { for j := 0; j < p; j += 1 {
        value := input[3+i*p+j]
        if value < 0 || value > 1000 || (i == j && value != 0) || (i != j && value == 0) do return -1
        metric[i*p+j] = value
    } }
    for i := 0; i < p; i += 1 { for j := 0; j < p; j += 1 {
        if metric[i*p+j] != metric[j*p+i] do return -1
        for z := 0; z < p; z += 1 { if metric[i*p+j] > metric[i*p+z]+metric[z*p+j] do return -1 }
    } }
    initial: [MAX_K]i64
    for i := 0; i < k; i += 1 { initial[i] = input[initial_at+i]; if initial[i] < 0 || initial[i] >= p64 do return -1; for j := 0; j < i; j += 1 { if initial[j] == initial[i] do return -1 } }
    sort_cfg(&initial[0],k)
    requests: [MAX_R]i64
    for t := 0; t < n; t += 1 { requests[t] = input[requests_at+t]; if requests[t] < 0 || requests[t] >= p64 do return -1 }
    output_bytes := 8*(2+n*k)
    if output == nil || capacity < c.size_t(output_bytes) do return -2

    configs: [MAX_CONFIGS*MAX_K]i64
    config_count := 0
    for a := 0; a < p; a += 1 {
        if k == 1 { configs[config_count*MAX_K]=i64(a);config_count+=1;continue }
        for b := a+1; b < p; b += 1 {
            if k == 2 { configs[config_count*MAX_K]=i64(a);configs[config_count*MAX_K+1]=i64(b);config_count+=1;continue }
            for c0 := b+1; c0 < p; c0 += 1 { configs[config_count*MAX_K]=i64(a);configs[config_count*MAX_K+1]=i64(b);configs[config_count*MAX_K+2]=i64(c0);config_count+=1 }
        }
    }
    work,next_work: [MAX_CONFIGS]i64
    for x := 0; x < config_count; x += 1 { work[x]=cfg_dist(&initial[0],&configs[x*MAX_K],k,&metric[0],p) }
    staged: [2+MAX_R*MAX_K]i64;staged[0]=i64(n);staged[1]=i64(k)
    current := initial
    for t := 0; t < n; t += 1 {
        r := requests[t]
        for x := 0; x < config_count; x += 1 {
            next_work[x]=INF
            for y := 0; y < config_count; y += 1 {
                contains := false
                for j := 0; j < k; j += 1 { if configs[y*MAX_K+j]==r { contains=true } }
                if contains { value:=work[y]+cfg_dist(&configs[y*MAX_K],&configs[x*MAX_K],k,&metric[0],p);if value<next_work[x]{next_work[x]=value} }
            }
        }
        best:=INF;best_slot:=0;chosen:=current;already_served:=false
        for j:=0;j<k;j+=1{if current[j]==r{already_served=true}}
        if !already_served {
            for slot:=0;slot<k;slot+=1 {
                candidate:=current;candidate[slot]=r;sort_cfg(&candidate[0],k)
                index:=find_cfg(&configs[0],config_count,&candidate[0],k)
                score:=work[index]+metric[int(current[slot])*p+int(r)]
                if score<best || (score==best && slot<best_slot){best=score;best_slot=slot;chosen=candidate}
            }
        }
        for j:=0;j<k;j+=1{staged[2+t*k+j]=chosen[j];current[j]=chosen[j]}
        for x:=0;x<config_count;x+=1{work[x]=next_work[x]}
    }
    for i:=0;i<2+n*k;i+=1{store_i64_le(output,8*i,staged[i])}
    return i64(output_bytes)
}
