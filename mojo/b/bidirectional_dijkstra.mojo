from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

comptime MAX_VERTICES = 64
comptime INF = 1_000_000_000

@export("bidirectional_dijkstra")
fn bidirectional_dijkstra(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4: return -1
    let nv = input[0]; let ne = input[1]; let sv = input[2]; let tv = input[3]
    if nv < 1 or nv > 64 or ne < 0 or ne > 256 or sv < 0 or sv >= nv or tv < 0 or tv >= nv or length != c_size_t(4 + 3 * ne): return -1
    let n = Int(nv); let m = Int(ne); let source = Int(sv); let target = Int(tv)
    var froms = List[Int](capacity=m); var tos = List[Int](capacity=m); var weights = List[Int64](capacity=m)
    for i in range(m):
        let a = input[4 + 3 * i]; let b = input[5 + 3 * i]; let w = input[6 + 3 * i]
        if a < 0 or a >= nv or b < 0 or b >= nv or w < 0 or w > 1_000_000: return -1
        froms.append(Int(a)); tos.append(Int(b)); weights.append(w)
    if source == target: return 0
    var df = List[Int64](capacity=n); var db = List[Int64](capacity=n)
    var sf = List[Bool](capacity=n); var sb = List[Bool](capacity=n)
    for _ in range(n): df.append(INF); db.append(INF); sf.append(False); sb.append(False)
    df[source] = 0; db[target] = 0; var best: Int64 = INF
    for _ in range(2 * n):
        var uf = -1; var ub = -1; var mf: Int64 = INF; var mb: Int64 = INF
        for v in range(n):
            if not sf[v] and df[v] < mf: mf = df[v]; uf = v
            if not sb[v] and db[v] < mb: mb = db[v]; ub = v
        if uf < 0 or ub < 0: break
        if best < INF and mf + mb >= best: break
        if mf <= mb:
            sf[uf] = True
            if db[uf] < INF: best = min(best, df[uf] + db[uf])
            for e in range(m):
                if froms[e] != uf: continue
                let v = tos[e]; let candidate = df[uf] + weights[e]
                if not sf[v] and candidate < df[v]: df[v] = candidate
                if db[v] < INF: best = min(best, candidate + db[v])
        else:
            sb[ub] = True
            if df[ub] < INF: best = min(best, df[ub] + db[ub])
            for e in range(m):
                if tos[e] != ub: continue
                let v = froms[e]; let candidate = db[ub] + weights[e]
                if not sb[v] and candidate < db[v]: db[v] = candidate
                if df[v] < INF: best = min(best, candidate + df[v])
    return -1 if best == INF else best
