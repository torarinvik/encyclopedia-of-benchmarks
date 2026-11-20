from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_N = 8
const MAX_M = 24
const MAX_PARSEABLE_IN = 99
const MAX_WORDS = 44
const OUT_BYTES = 352

fn simplify(inout lits: InlineArray[Int32, 72], inout lens: InlineArray[Int32, 24],
            inout active: InlineArray[Bool, 24], inout values: InlineArray[Int32, 8],
            m: Int, literal: Int32) -> Bool:
    let v = Int(literal if literal > 0 else -literal) - 1
    let value = Int32(1 if literal > 0 else -1)
    if values[v] != 0 and values[v] != value: return False
    values[v] = value
    for c in range(m):
        if not active[c]: continue
        var satisfied = False
        for j in range(Int(lens[c])):
            if lits[3*c+j] == literal: satisfied = True
        if satisfied:
            active[c] = False
            continue
        var kept = 0
        for j in range(Int(lens[c])):
            if lits[3*c+j] != -literal:
                lits[3*c+kept] = lits[3*c+j]
                kept += 1
        lens[c] = Int32(kept)
        if kept == 0: return False
    True

fn propagate(inout lits: InlineArray[Int32, 72], inout lens: InlineArray[Int32, 24],
             inout active: InlineArray[Bool, 24], inout values: InlineArray[Int32, 8],
             m: Int, inout ev_lit: InlineArray[Int64, 8],
             inout ev_kind: InlineArray[Int64, 8], inout ev_i: InlineArray[Int64, 8],
             inout ev_j: InlineArray[Int64, 8], inout count: Int, record: Bool) -> Bool:
    while True:
        var unit: Int32 = 0
        for c in range(m):
            if unit == 0 and active[c] and lens[c] == 1: unit = lits[3*c]
        if unit == 0: return True
        if record:
            ev_lit[count] = Int64(unit); ev_kind[count] = 1
            ev_i[count] = -1; ev_j[count] = -1; count += 1
        if not simplify(lits, lens, active, values, m, unit): return False

fn degrees(inout lits: InlineArray[Int32, 72], inout lens: InlineArray[Int32, 24],
           inout active: InlineArray[Bool, 24], m: Int, n: Int,
           inout positive: InlineArray[Int32, 8], inout negative: InlineArray[Int32, 8]):
    for v in range(n): positive[v] = 0; negative[v] = 0
    for c in range(m):
        if active[c]:
            for j in range(Int(lens[c])):
                let x = lits[3*c+j]
                let v = Int(x if x > 0 else -x) - 1
                if x > 0: positive[v] += 1
                else: negative[v] += 1

fn bucket_member(inout lits: InlineArray[Int32, 72], inout lens: InlineArray[Int32, 24],
                 inout active: InlineArray[Bool, 24], inout values: InlineArray[Int32, 8],
                 m: Int, n: Int, bi: Int, bj: Int) -> Int32:
    var positive = InlineArray[Int32, 8](fill=0)
    var negative = InlineArray[Int32, 8](fill=0)
    degrees(lits, lens, active, m, n, positive, negative)
    for v in range(n):
        if values[v] != 0: continue
        let p = min(10, Int(positive[v]))
        let q = min(10, Int(negative[v]))
        if p == bi and q == bj: return Int32(v + 1)
        if q == bi and p == bj: return Int32(-(v + 1))
    Int32(0)

fn flow_sums(inout lits: InlineArray[Int32, 72], inout lens: InlineArray[Int32, 24],
             inout active: InlineArray[Bool, 24], m: Int, n: Int) -> (Int64, Int64, Int64):
    var p2 = InlineArray[Int64, 8](fill=0); var n2 = InlineArray[Int64, 8](fill=0)
    var p3 = InlineArray[Int64, 8](fill=0); var n3 = InlineArray[Int64, 8](fill=0)
    var count2: Int64 = 0
    for c in range(m):
        if not active[c]: continue
        if lens[c] == 2:
            count2 += 1
            for j in range(2):
                let x = lits[3*c+j]; let v = Int(x if x > 0 else -x) - 1
                if x > 0: p2[v] += 1
                else: n2[v] += 1
        elif lens[c] == 3:
            for j in range(3):
                let x = lits[3*c+j]; let v = Int(x if x > 0 else -x) - 1
                if x > 0: p3[v] += 1
                else: n3[v] += 1
    var s2: Int64 = 0; var s3: Int64 = 0
    for c in range(m):
        if active[c] and lens[c] == 2:
            for j in range(2):
                let x = -lits[3*c+j]; let v = Int(x if x > 0 else -x) - 1
                if x > 0: s2 += p2[v]; s3 += p3[v]
                else: s2 += n2[v]; s3 += n3[v]
    let den = Int64(1) if count2 == 0 else 2 * count2
    (s2, s3, den)

fn choose_bucket(inout lits: InlineArray[Int32, 72], inout lens: InlineArray[Int32, 24],
                 inout active: InlineArray[Bool, 24], inout values: InlineArray[Int32, 8],
                 m: Int, n: Int) -> (Bool, Int, Int):
    let old = flow_sums(lits, lens, active, m, n)
    var found = False; var best_num: Int64 = 0; var best_den: Int64 = 1
    var best_i = -1; var best_j = -1
    for bi in range(11):
        for bj in range(11):
            let literal = bucket_member(lits, lens, active, values, m, n, bi, bj)
            if literal == 0: continue
            var tlits = lits; var tlens = lens; var tactive = active; var tvalues = values
            var ignored_lit = InlineArray[Int64, 8](fill=0)
            var ignored_kind = InlineArray[Int64, 8](fill=0)
            var ignored_i = InlineArray[Int64, 8](fill=0)
            var ignored_j = InlineArray[Int64, 8](fill=0)
            var ignored_count = 0
            if not simplify(tlits, tlens, tactive, tvalues, m, literal): continue
            if not propagate(tlits, tlens, tactive, tvalues, m, ignored_lit, ignored_kind,
                            ignored_i, ignored_j, ignored_count, False): continue
            let next = flow_sums(tlits, tlens, tactive, m, n)
            var num = next.0 * old.2 - old.0 * next.2
            var den = next.1 * old.2 - old.1 * next.2
            if den == 0: continue
            if den < 0: num = -num; den = -den
            if not found or num * best_den > best_num * den or
               (num * best_den == best_num * den and (bi < best_i or (bi == best_i and bj < best_j))):
                found = True; best_num = num; best_den = den; best_i = bi; best_j = bj
    (found, best_i, best_j)

@export("random_3sat_cl_bucket_heuristic")
fn random_3sat_cl_bucket_heuristic(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_PARSEABLE_IN: return -1
    let n64 = input[0]; let m64 = input[1]
    if n64 < 1 or n64 > MAX_N or m64 < 0 or m64 > MAX_M or length != c_size_t(2 + 4*m64): return -1
    let n = Int(n64); let m = Int(m64)
    var lits = InlineArray[Int32, 72](fill=0)
    var lens = InlineArray[Int32, 24](fill=0)
    var active = InlineArray[Bool, 24](fill=False)
    for c in range(m):
        let base = 2 + 4*c; let k = input[base]
        if k < 1 or k > 3: return -1
        var seen = InlineArray[Bool, 8](fill=False)
        lens[c] = Int32(k)
        for j in range(3):
            let raw = input[base + 1 + j]
            if j < Int(k):
                if raw == 0 or raw < -n64 or raw > n64: return -1
                let v = Int(raw if raw > 0 else -raw) - 1
                if seen[v]: return -1
                seen[v] = True; lits[3*c+j] = Int32(raw)
            elif raw != 0: return -1
        active[c] = True

    var values = InlineArray[Int32, 8](fill=0)
    var ev_lit = InlineArray[Int64, 8](fill=0); var ev_kind = InlineArray[Int64, 8](fill=0)
    var ev_i = InlineArray[Int64, 8](fill=0); var ev_j = InlineArray[Int64, 8](fill=0)
    var count = 0; var status: Int64 = 0
    if not propagate(lits, lens, active, values, m, ev_lit, ev_kind, ev_i, ev_j, count, True): status = 1
    while status == 0:
        var pending = False
        for v in range(n):
            if values[v] == 0: pending = True
        if not pending: break
        let picked = choose_bucket(lits, lens, active, values, m, n)
        if not picked.0: status = 2; break
        let literal = bucket_member(lits, lens, active, values, m, n, picked.1, picked.2)
        if literal == 0: status = 2; break
        ev_lit[count] = Int64(literal); ev_kind[count] = 0
        ev_i[count] = Int64(picked.1); ev_j[count] = Int64(picked.2); count += 1
        if not simplify(lits, lens, active, values, m, literal): status = 1; break
        if not propagate(lits, lens, active, values, m, ev_lit, ev_kind, ev_i, ev_j, count, True): status = 1; break

    var words = InlineArray[Int64, MAX_WORDS](fill=0)
    var at = 0; words[at] = status; at += 1; words[at] = Int64(n); at += 1
    var assigned_count = 0
    for v in range(n):
        if values[v] != 0: assigned_count += 1
    words[at] = Int64(assigned_count); at += 1
    for v in range(n): words[at] = Int64(values[v]); at += 1
    words[at] = Int64(count); at += 1
    for e in range(count):
        words[at] = ev_lit[e]; at += 1; words[at] = ev_kind[e]; at += 1
        words[at] = ev_i[e]; at += 1; words[at] = ev_j[e]; at += 1
    let bytes = at * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var staged = InlineArray[UInt8, OUT_BYTES](fill=0)
    for w in range(at):
        let bits = cast[UInt64](words[w])
        for b in range(8): staged[8*w+b] = UInt8((bits >> (8*b)) & 255)
    for b in range(bytes): output[b] = staged[b]
    Int64(bytes)
