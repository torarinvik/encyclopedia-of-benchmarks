from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime PTS_N = 16
comptime PTS_Q = 32
comptime PTS_BASE = 16
comptime PTS_INPUT_MAX = 5 * PTS_N + 4 * PTS_Q - 2
comptime PTS_MOD: Int64 = 998244353

fn pts_find(inout parent: InlineArray[Int, PTS_N], x0: Int) -> Int:
    var x = x0
    while parent[x] != x:
        parent[x] = parent[parent[x]]
        x = parent[x]
    return x

fn pts_compose(lm: Int64, la: Int64, rm: Int64, ra: Int64) -> InlineArray[Int64, 2]:
    var out = InlineArray[Int64, 2](fill=0)
    out[0] = lm * rm % PTS_MOD
    out[1] = (lm * ra + la) % PTS_MOD
    return out

fn pts_set(inout sm: InlineArray[Int64, 32], inout sa: InlineArray[Int64, 32],
    pos: InlineArray[Int, PTS_N], lm: InlineArray[Int64, PTS_N],
    la: InlineArray[Int64, PTS_N], u: Int):
    var k = PTS_BASE + pos[u]
    sm[k] = lm[u]; sa[k] = la[u]
    k //= 2
    while k > 0:
        let c = pts_compose(sm[2*k], sa[2*k], sm[2*k+1], sa[2*k+1])
        sm[k] = c[0]; sa[k] = c[1]
        k //= 2

fn pts_chain(sm: InlineArray[Int64, 32], sa: InlineArray[Int64, 32],
    pos: InlineArray[Int, PTS_N], ends: InlineArray[Int, PTS_N], h: Int) -> Int64:
    var l = PTS_BASE + pos[h]
    var r = PTS_BASE + ends[h]
    var lm: Int64 = 1; var la: Int64 = 0
    var rm: Int64 = 1; var ra: Int64 = 0
    while l < r:
        if l % 2 == 1:
            let c = pts_compose(lm, la, sm[l], sa[l]); lm = c[0]; la = c[1]; l += 1
        if r % 2 == 1:
            r -= 1
            let c = pts_compose(sm[r], sa[r], rm, ra); rm = c[0]; ra = c[1]
        l //= 2; r //= 2
    let c = pts_compose(lm, la, rm, ra)
    return c[1]

fn pts_store(output: UnsafePointer[UInt8, MutAnyOrigin], index: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for i in range(8): output[index+i] = UInt8((bits >> UInt(8*i)) & 255)

@export("point_set_tree_path_composite_sum_fixed_root")
fn point_set_tree_path_composite_sum_fixed_root(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > PTS_INPUT_MAX:
        return -1
    let nr = input[0]; let qr = input[1]
    if nr < 1 or nr > PTS_N or qr < 1 or qr > PTS_Q: return -1
    let n = Int(nr); let q = Int(qr); let input_len = Int(length)
    var cur = 2
    var value = InlineArray[Int64, PTS_N](fill=0)
    for u in range(n):
        if cur >= input_len: return -1
        value[u] = input[cur]; cur += 1
        if value[u] < 0 or value[u] >= PTS_MOD: return -1
    var edge_at = InlineArray[Int, PTS_N * PTS_N](fill=-1)
    var eu = InlineArray[Int, PTS_N](fill=0); var ev = InlineArray[Int, PTS_N](fill=0)
    var eb = InlineArray[Int64, PTS_N](fill=0); var ec = InlineArray[Int64, PTS_N](fill=0)
    var dsu = InlineArray[Int, PTS_N](fill=0); var dsz = InlineArray[Int, PTS_N](fill=0)
    for u in range(n): dsu[u] = u; dsz[u] = 1
    for e in range(n-1):
        if cur + 4 > input_len: return -1
        let ur = input[cur]; let vr = input[cur+1]; let b = input[cur+2]; let c = input[cur+3]; cur += 4
        if ur < 0 or ur >= nr or vr < 0 or vr >= nr or ur == vr or b < 1 or b >= PTS_MOD or c < 0 or c >= PTS_MOD: return -1
        let u = Int(ur); let v = Int(vr); var ru = pts_find(dsu, u); var rv = pts_find(dsu, v)
        if ru == rv: return -1
        if dsz[ru] < dsz[rv]: let t = ru; ru = rv; rv = t
        dsu[rv] = ru; dsz[ru] += dsz[rv]; eu[e] = u; ev[e] = v; eb[e] = b; ec[e] = c
        edge_at[u*PTS_N+v] = e; edge_at[v*PTS_N+u] = e
    var kinds = InlineArray[Int64, PTS_Q](fill=0)
    var ox = InlineArray[Int64, PTS_Q](fill=0); var oy = InlineArray[Int64, PTS_Q](fill=0); var oz = InlineArray[Int64, PTS_Q](fill=0)
    for i in range(q):
        if cur >= input_len: return -1
        kinds[i] = input[cur]; cur += 1
        if kinds[i] == 0:
            if cur + 2 > input_len: return -1
            ox[i] = input[cur]; oy[i] = input[cur+1]; cur += 2
            if ox[i] < 0 or ox[i] >= nr or oy[i] < 0 or oy[i] >= PTS_MOD: return -1
        elif kinds[i] == 1:
            if cur + 3 > input_len: return -1
            ox[i] = input[cur]; oy[i] = input[cur+1]; oz[i] = input[cur+2]; cur += 3
            if ox[i] < 0 or ox[i] >= nr-1 or oy[i] < 1 or oy[i] >= PTS_MOD or oz[i] < 0 or oz[i] >= PTS_MOD: return -1
        else: return -1
    if cur != input_len: return -1
    let bytes = 8*q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2

    var parent = InlineArray[Int, PTS_N](fill=-2); var pedge = InlineArray[Int, PTS_N](fill=-1)
    var order = InlineArray[Int, PTS_N](fill=0); var stack = InlineArray[Int, PTS_N](fill=0)
    var top = 1; var count = 0; parent[0] = -1; stack[0] = 0
    while top > 0:
        top -= 1; let u = stack[top]; order[count] = u; count += 1
        for v in range(n):
            if edge_at[u*PTS_N+v] >= 0 and v != parent[u]:
                parent[v] = u; pedge[v] = edge_at[u*PTS_N+v]; stack[top] = v; top += 1
    var sub = InlineArray[Int, PTS_N](fill=1); var heavy = InlineArray[Int, PTS_N](fill=-1)
    for oi in range(count):
        let u = order[count-1-oi]; var best = 0
        for v in range(n):
            if parent[v] == u:
                sub[u] += sub[v]
                if sub[v] > best or (sub[v] == best and (heavy[u] < 0 or v < heavy[u])): best = sub[v]; heavy[u] = v
    var head = InlineArray[Int, PTS_N](fill=0); var pos = InlineArray[Int, PTS_N](fill=0)
    var ends = InlineArray[Int, PTS_N](fill=0); var hs = InlineArray[Int, PTS_N](fill=0)
    var timer = 0; top = 1; hs[0] = 0
    while top > 0:
        top -= 1; let h = hs[top]; var u = h
        while True:
            head[u] = h; pos[u] = timer; timer += 1
            for v in range(n):
                if parent[v] == u and v != heavy[u]: hs[top] = v; top += 1
            if heavy[u] < 0: break
            u = heavy[u]
        ends[h] = timer
    var down = InlineArray[Int64, PTS_N](fill=0)
    for oi in range(count):
        let u = order[count-1-oi]; down[u] = value[u]
        for v in range(n):
            if parent[v] == u: let e = pedge[v]; down[u] += eb[e]*down[v] + ec[e]*Int64(sub[v])
        down[u] %= PTS_MOD
    var lm = InlineArray[Int64, PTS_N](fill=0); var la = InlineArray[Int64, PTS_N](fill=0)
    for u in range(n):
        la[u] = value[u]
        for v in range(n):
            if parent[v] == u:
                let e = pedge[v]
                if heavy[u] == v: lm[u] = eb[e]; la[u] += ec[e]*Int64(sub[v])
                else: la[u] += eb[e]*down[v] + ec[e]*Int64(sub[v])
        la[u] %= PTS_MOD
    var sm = InlineArray[Int64, 32](fill=1); var sa = InlineArray[Int64, 32](fill=0)
    for u in range(n): sm[PTS_BASE+pos[u]] = lm[u]; sa[PTS_BASE+pos[u]] = la[u]
    for i in range(PTS_BASE-1, 0, -1): let c = pts_compose(sm[2*i],sa[2*i],sm[2*i+1],sa[2*i+1]); sm[i]=c[0];sa[i]=c[1]
    var current = InlineArray[Int64, PTS_N](fill=0)
    for u in range(n): if head[u] == u: current[u] = down[u]
    for qi in range(q):
        var start = 0
        if kinds[qi] == 0:
            let u = Int(ox[qi]); la[u] = (la[u]+oy[qi]-value[u])%PTS_MOD
            if la[u] < 0: la[u] += PTS_MOD
            value[u] = oy[qi]; pts_set(sm,sa,pos,lm,la,u); start = u
        else:
            let e = Int(ox[qi]); let u = eu[e]; let v = ev[e]; let child = if parent[u] == v: u else: v; let p = parent[child]
            let ob = eb[e]; let oc = ec[e]
            if heavy[p] == child: lm[p] = oy[qi]; la[p] = (la[p]+(oz[qi]-oc)*Int64(sub[child]))%PTS_MOD
            else: la[p] = (la[p]+(oy[qi]-ob)*current[child]+(oz[qi]-oc)*Int64(sub[child]))%PTS_MOD
            if la[p] < 0: la[p] += PTS_MOD
            eb[e] = oy[qi]; ec[e] = oz[qi]; pts_set(sm,sa,pos,lm,la,p); start = p
        var u = start
        while True:
            let h = head[u]; let old = current[h]; current[h] = pts_chain(sm,sa,pos,ends,h)
            if h == 0: break
            let p = parent[h]; let e = pedge[h]; la[p] = (la[p]+eb[e]*(current[h]-old))%PTS_MOD
            if la[p] < 0: la[p] += PTS_MOD
            pts_set(sm,sa,pos,lm,la,p); u = p
        pts_store(output, 8*qi, current[0])
    return Int64(bytes)
