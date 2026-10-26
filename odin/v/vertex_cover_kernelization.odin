// Clean-room high-/low-degree vertex-cover reduction profile.
package vertex_cover_kernelization

import "core:c"

MAX_N :: 16
MAX_M :: 64
MAX_INPUT :: 131
MAX_FIELDS :: 133

put_i64 :: proc(out: [^]u8, at: int, value: i64) {
    bits := u64(value)
    for b := 0; b < 8; b += 1 { out[at+b] = u8(bits & 255); bits >>= 8 }
}

@(export)
vertex_cover_kernelization :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT do return -1
    n64,m64,k := input[0],input[1],input[2]
    if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 || k < 0 || k > 16 || length != c.size_t(3+2*int(m64)) do return -1
    n,m := int(n64),int(m64)
    edge: [MAX_N][MAX_N]bool
    previous_u,previous_v := i64(-1),i64(-1)
    for e := 0; e < m; e += 1 {
        u,v := input[3+2*e],input[4+2*e]
        if u < 0 || v <= u || v >= n64 || u < previous_u || (u == previous_u && v <= previous_v) do return -1
        edge[int(u)][int(v)]=true;edge[int(v)][int(u)]=true;previous_u=u;previous_v=v
    }
    if output == nil do return -2
    active: [MAX_N]bool
    for i := 0; i < n; i += 1 { active[i]=true }
    forced := u64(0)
    infeasible := false
    for {
        if k < 0 { infeasible=true;break }
        chosen,neighbor,kind := n,n,0
        for u := 0; u < n; u += 1 { if active[u] { degree:=0;for v:=0;v<n;v+=1{if edge[u][v]{degree+=1}};if degree==0{chosen=u;kind=1;break} } }
        if kind==1 { active[chosen]=false;continue }
        for u:=0;u<n;u+=1 { if active[u] { degree,only:=0,n;for v:=0;v<n;v+=1{if edge[u][v]{degree+=1;only=v}};if degree==1{chosen=u;neighbor=only;kind=2;break} } }
        if kind==0 { for u:=0;u<n;u+=1 { if active[u] { degree:=0;for v:=0;v<n;v+=1{if edge[u][v]{degree+=1}};if i64(degree)>k{chosen=u;kind=3;break} } } }
        if kind==0 do break
        f:=chosen;if kind==2{f=neighbor};forced|=u64(1)<<u32(f);active[f]=false;k-=1
        for v:=0;v<n;v+=1{edge[f][v]=false;edge[v][f]=false}
    }
    staged: [MAX_FIELDS]i64
    count:=0;staged[count]=1;if infeasible{staged[count]=0};count+=1;staged[count]=k;count+=1;staged[count]=i64(forced);count+=1
    active_mask:=u64(0);for v:=0;v<n;v+=1{if active[v]{active_mask|=u64(1)<<u32(v)}};staged[count]=i64(active_mask);count+=1
    remaining:=0;for u:=0;u<n;u+=1{for v:=u+1;v<n;v+=1{if edge[u][v]{remaining+=1}}};staged[count]=i64(remaining);count+=1
    for u:=0;u<n;u+=1{for v:=u+1;v<n;v+=1{if edge[u][v]{staged[count]=i64(u);staged[count+1]=i64(v);count+=2}}}
    if capacity < c.size_t(8*count) do return -2
    for i:=0;i<count;i+=1{put_i64(output,8*i,staged[i])}
    return i64(8*count)
}
