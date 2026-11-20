from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime LL_MAX_N = 8
comptime LL_MAX_EDGES = 18
comptime LL_MAX_FACES = 16
comptime LL_MAX_DARTS = 2 * (LL_MAX_N - 1)
comptime LL_MAX_STACK = 64
comptime LL_MAX_INPUT = 55
comptime LL_MAX_WORDS = 3 + 2 * LL_MAX_EDGES

struct LLState:
    var x: InlineArray[Int64, LL_MAX_N]
    var y: InlineArray[Int64, LL_MAX_N]
    var edge_u: InlineArray[Int, LL_MAX_EDGES]
    var edge_v: InlineArray[Int, LL_MAX_EDGES]
    var edge_count: Int
    var face_a: InlineArray[Int, LL_MAX_FACES]
    var face_b: InlineArray[Int, LL_MAX_FACES]
    var face_c: InlineArray[Int, LL_MAX_FACES]
    var face_count: Int
    var rotation: InlineArray[Int, LL_MAX_N * LL_MAX_N]
    var degree: InlineArray[Int, LL_MAX_N]
    var tree_rotation: InlineArray[Int, LL_MAX_N * LL_MAX_N]
    var tree_degree: InlineArray[Int, LL_MAX_N]
    var contour_u: InlineArray[Int, LL_MAX_DARTS]
    var contour_v: InlineArray[Int, LL_MAX_DARTS]
    var contour_len: Int
    var stack_u: InlineArray[Int, LL_MAX_STACK]
    var stack_v: InlineArray[Int, LL_MAX_STACK]
    var stack_len: Int
    var weight: InlineArray[Float64, LL_MAX_N * LL_MAX_N]
    var hull: InlineArray[Bool, LL_MAX_N]
    var tree: InlineArray[Bool, LL_MAX_N * LL_MAX_N]
    var kept: InlineArray[Bool, LL_MAX_N * LL_MAX_N]

    fn __init__(out self):
        self.x = InlineArray[Int64, LL_MAX_N](fill=0)
        self.y = InlineArray[Int64, LL_MAX_N](fill=0)
        self.edge_u = InlineArray[Int, LL_MAX_EDGES](fill=0)
        self.edge_v = InlineArray[Int, LL_MAX_EDGES](fill=0)
        self.edge_count = 0
        self.face_a = InlineArray[Int, LL_MAX_FACES](fill=0)
        self.face_b = InlineArray[Int, LL_MAX_FACES](fill=0)
        self.face_c = InlineArray[Int, LL_MAX_FACES](fill=0)
        self.face_count = 0
        self.rotation = InlineArray[Int, LL_MAX_N * LL_MAX_N](fill=0)
        self.degree = InlineArray[Int, LL_MAX_N](fill=0)
        self.tree_rotation = InlineArray[Int, LL_MAX_N * LL_MAX_N](fill=0)
        self.tree_degree = InlineArray[Int, LL_MAX_N](fill=0)
        self.contour_u = InlineArray[Int, LL_MAX_DARTS](fill=0)
        self.contour_v = InlineArray[Int, LL_MAX_DARTS](fill=0)
        self.contour_len = 0
        self.stack_u = InlineArray[Int, LL_MAX_STACK](fill=0)
        self.stack_v = InlineArray[Int, LL_MAX_STACK](fill=0)
        self.stack_len = 0
        self.weight = InlineArray[Float64, LL_MAX_N * LL_MAX_N](fill=0.0)
        self.hull = InlineArray[Bool, LL_MAX_N](fill=False)
        self.tree = InlineArray[Bool, LL_MAX_N * LL_MAX_N](fill=False)
        self.kept = InlineArray[Bool, LL_MAX_N * LL_MAX_N](fill=False)

fn ll_orient(s: LLState, a: Int, b: Int, c: Int) -> Int64:
    (s.x[b] - s.x[a]) * (s.y[c] - s.y[a]) - (s.y[b] - s.y[a]) * (s.x[c] - s.x[a])

fn ll_incircle(s: LLState, a: Int, b: Int, c: Int, p: Int) -> Int64:
    let ax = s.x[a] - s.x[p]
    let ay = s.y[a] - s.y[p]
    let bx = s.x[b] - s.x[p]
    let by = s.y[b] - s.y[p]
    let cx = s.x[c] - s.x[p]
    let cy = s.y[c] - s.y[p]
    let determinant = (ax * ax + ay * ay) * (bx * cy - by * cx) - (bx * bx + by * by) * (ax * cy - ay * cx) + (cx * cx + cy * cy) * (ax * by - ay * bx)
    if ll_orient(s, a, b, c) > 0: determinant else: -determinant

fn ll_dist2(s: LLState, a: Int, b: Int) -> Int64:
    let dx = s.x[a] - s.x[b]
    let dy = s.y[a] - s.y[b]
    dx * dx + dy * dy

fn ll_sort_three(a0: Int, b0: Int, c0: Int) -> (Int, Int, Int):
    var a = a0
    var b = b0
    var c = c0
    if a > b:
        let temp = a
        a = b
        b = temp
    if b > c:
        let temp = b
        b = c
        c = temp
    if a > b:
        let temp = a
        a = b
        b = temp
    (a, b, c)

fn ll_is_face(s: LLState, a0: Int, b0: Int, c0: Int) -> Bool:
    let (a, b, c) = ll_sort_three(a0, b0, c0)
    for i in range(s.face_count):
        if s.face_a[i] == a and s.face_b[i] == b and s.face_c[i] == c:
            return True
    False

fn ll_angle_less(s: LLState, origin: Int, a: Int, b: Int) -> Bool:
    let ax = s.x[a] - s.x[origin]
    let ay = s.y[a] - s.y[origin]
    let bx = s.x[b] - s.x[origin]
    let by = s.y[b] - s.y[origin]
    let ah = 0 if ay > 0 or (ay == 0 and ax >= 0) else 1
    let bh = 0 if by > 0 or (by == 0 and bx >= 0) else 1
    if ah != bh: return ah < bh
    let cross = ax * by - ay * bx
    if cross != 0: return cross > 0
    a < b

fn ll_cw_next(s: LLState, u: Int, v: Int) -> (Bool, Int, Int):
    let count = s.degree[v]
    if count == 0: return (False, 0, 0)
    for i in range(count):
        if s.rotation[v * LL_MAX_N + i] == u:
            let next = (i + count - 1) % count
            return (True, v, s.rotation[v * LL_MAX_N + next])
    (False, 0, 0)

fn ll_cw_tree_next(s: LLState, u: Int, v: Int) -> (Bool, Int, Int):
    let count = s.tree_degree[v]
    if count == 0: return (False, 0, 0)
    for i in range(count):
        if s.tree_rotation[v * LL_MAX_N + i] == u:
            let next = (i + count - 1) % count
            return (True, v, s.tree_rotation[v * LL_MAX_N + next])
    (False, 0, 0)

fn ll_contour_find(s: LLState, u: Int, v: Int) -> Int:
    for i in range(s.contour_len):
        if s.contour_u[i] == u and s.contour_v[i] == v: return i
    -1

fn ll_canonicalize(inout s: LLState):
    if s.contour_len == 0: return
    var first = 0
    for i in range(1, s.contour_len):
        if s.contour_u[i] < s.contour_u[first] or (s.contour_u[i] == s.contour_u[first] and s.contour_v[i] < s.contour_v[first]):
            first = i
    if first == 0: return
    var us = InlineArray[Int, LL_MAX_DARTS](fill=0)
    var vs = InlineArray[Int, LL_MAX_DARTS](fill=0)
    for i in range(s.contour_len):
        let at = (first + i) % s.contour_len
        us[i] = s.contour_u[at]
        vs[i] = s.contour_v[at]
    for i in range(s.contour_len):
        s.contour_u[i] = us[i]
        s.contour_v[i] = vs[i]

fn ll_eligible(s: LLState, u: Int, v: Int) -> Bool:
    let at = ll_contour_find(s, u, v)
    if at < 0 or s.hull[v] or s.contour_len < 3: return False
    let next = (at + 1) % s.contour_len
    let (found, cw_u, cw_v) = ll_cw_next(s, u, v)
    found and s.contour_u[next] == cw_u and s.contour_v[next] == cw_v and ll_is_face(s, u, v, cw_v)

fn ll_push_candidate(inout s: LLState, u: Int, v: Int) -> Bool:
    if not ll_eligible(s, u, v): return True
    if s.stack_len >= LL_MAX_STACK: return False
    s.stack_u[s.stack_len] = u
    s.stack_v[s.stack_len] = v
    s.stack_len += 1
    True

fn ll_parse(inout s: LLState, input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> (Bool, Int):
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(14) or length > c_size_t(LL_MAX_INPUT):
        return (False, 0)
    let n64 = input[0]
    if n64 < 3 or n64 > LL_MAX_N: return (False, 0)
    let n = Int(n64)
    let m_at = 1 + 2 * n
    if length <= c_size_t(m_at): return (False, 0)
    let m64 = input[m_at]
    if m64 < 3 or m64 > LL_MAX_EDGES or length != c_size_t(m_at + 1 + 2 * Int(m64)):
        return (False, 0)
    let m = Int(m64)

    for i in range(n):
        let x = input[1 + 2 * i]
        let y = input[2 + 2 * i]
        if x < -10 or x > 10 or y < -10 or y > 10: return (False, 0)
        s.x[i] = x
        s.y[i] = y
        for j in range(i):
            if s.x[i] == s.x[j] and s.y[i] == s.y[j]: return (False, 0)

    for a in range(n):
        for b in range(a + 1, n):
            for c in range(b + 1, n):
                if ll_orient(s, a, b, c) == 0: return (False, 0)
    for a in range(n):
        for b in range(a + 1, n):
            for c in range(b + 1, n):
                for d in range(c + 1, n):
                    if ll_incircle(s, a, b, c, d) == 0: return (False, 0)

    s.edge_count = m
    var supplied = InlineArray[Bool, LL_MAX_N * LL_MAX_N](fill=False)
    for i in range(m):
        let u64 = input[m_at + 1 + 2 * i]
        let v64 = input[m_at + 2 + 2 * i]
        if u64 < 0 or v64 <= u64 or v64 >= n64: return (False, 0)
        let u = Int(u64)
        let v = Int(v64)
        if i > 0 and (u < s.edge_u[i - 1] or (u == s.edge_u[i - 1] and v <= s.edge_v[i - 1])):
            return (False, 0)
        s.edge_u[i] = u
        s.edge_v[i] = v
        supplied[u * LL_MAX_N + v] = True
        supplied[v * LL_MAX_N + u] = True

    var expected = InlineArray[Bool, LL_MAX_N * LL_MAX_N](fill=False)
    for a0 in range(n):
        for b0 in range(a0 + 1, n):
            for c0 in range(b0 + 1, n):
                var a = a0
                var b = b0
                var c = c0
                if ll_orient(s, a, b, c) < 0:
                    let temp = b
                    b = c
                    c = temp
                var empty = True
                for p in range(n):
                    if p != a and p != b and p != c and ll_incircle(s, a, b, c, p) > 0:
                        empty = False
                        break
                if empty:
                    if s.face_count >= LL_MAX_FACES: return (False, 0)
                    let (fa, fb, fc) = ll_sort_three(a, b, c)
                    s.face_a[s.face_count] = fa
                    s.face_b[s.face_count] = fb
                    s.face_c[s.face_count] = fc
                    s.face_count += 1
                    expected[a * LL_MAX_N + b] = True
                    expected[b * LL_MAX_N + a] = True
                    expected[a * LL_MAX_N + c] = True
                    expected[c * LL_MAX_N + a] = True
                    expected[b * LL_MAX_N + c] = True
                    expected[c * LL_MAX_N + b] = True
    for a in range(n):
        for b in range(a + 1, n):
            if supplied[a * LL_MAX_N + b] != expected[a * LL_MAX_N + b]: return (False, 0)

    for a in range(n):
        for b in range(a + 1, n):
            var positive = False
            var negative = False
            for p in range(n):
                if p == a or p == b: continue
                let side = ll_orient(s, a, b, p)
                positive = positive or side > 0
                negative = negative or side < 0
            if not (positive and negative):
                s.hull[a] = True
                s.hull[b] = True

    for i in range(m):
        let u = s.edge_u[i]
        let v = s.edge_v[i]
        let du = s.degree[u]
        let dv = s.degree[v]
        if du >= LL_MAX_N or dv >= LL_MAX_N: return (False, 0)
        s.rotation[u * LL_MAX_N + du] = v
        s.rotation[v * LL_MAX_N + dv] = u
        s.degree[u] += 1
        s.degree[v] += 1
    for v in range(n):
        for i in range(1, s.degree[v]):
            let key = s.rotation[v * LL_MAX_N + i]
            var pos = i
            while pos > 0 and ll_angle_less(s, v, key, s.rotation[v * LL_MAX_N + pos - 1]):
                s.rotation[v * LL_MAX_N + pos] = s.rotation[v * LL_MAX_N + pos - 1]
                pos -= 1
            s.rotation[v * LL_MAX_N + pos] = key
    (True, n)

fn ll_build_mst_contour(inout s: LLState, n: Int) -> Bool:
    var order = InlineArray[Int, LL_MAX_EDGES](fill=0)
    for i in range(s.edge_count): order[i] = i
    for i in range(1, s.edge_count):
        let key = order[i]
        var pos = i
        while pos > 0:
            let prior = order[pos - 1]
            let prev_len = ll_dist2(s, s.edge_u[prior], s.edge_v[prior])
            let key_len = ll_dist2(s, s.edge_u[key], s.edge_v[key])
            let before = prev_len < key_len or (prev_len == key_len and (s.edge_u[prior] < s.edge_u[key] or (s.edge_u[prior] == s.edge_u[key] and s.edge_v[prior] <= s.edge_v[key])))
            if before: break
            order[pos] = prior
            pos -= 1
        order[pos] = key

    var parent = InlineArray[Int, LL_MAX_N](fill=0)
    var component_size = InlineArray[Int, LL_MAX_N](fill=1)
    for i in range(n): parent[i] = i
    var chosen = 0
    for rank in range(s.edge_count):
        let edge = order[rank]
        let u = s.edge_u[edge]
        let v = s.edge_v[edge]
        var a = u
        var b = v
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        while parent[b] != b:
            parent[b] = parent[parent[b]]
            b = parent[b]
        if a == b: continue
        if component_size[a] < component_size[b]:
            let temp = a
            a = b
            b = temp
        parent[b] = a
        component_size[a] += component_size[b]
        s.tree[u * LL_MAX_N + v] = True
        s.tree[v * LL_MAX_N + u] = True
        s.kept[u * LL_MAX_N + v] = True
        s.kept[v * LL_MAX_N + u] = True
        let du = s.tree_degree[u]
        let dv = s.tree_degree[v]
        s.tree_rotation[u * LL_MAX_N + du] = v
        s.tree_rotation[v * LL_MAX_N + dv] = u
        s.tree_degree[u] += 1
        s.tree_degree[v] += 1
        chosen += 1
    if chosen != n - 1: return False

    for v in range(n):
        for i in range(1, s.tree_degree[v]):
            let key = s.tree_rotation[v * LL_MAX_N + i]
            var pos = i
            while pos > 0 and ll_angle_less(s, v, key, s.tree_rotation[v * LL_MAX_N + pos - 1]):
                s.tree_rotation[v * LL_MAX_N + pos] = s.tree_rotation[v * LL_MAX_N + pos - 1]
                pos -= 1
            s.tree_rotation[v * LL_MAX_N + pos] = key
    for i in range(s.edge_count):
        let u = s.edge_u[i]
        let v = s.edge_v[i]
        let length = sqrt(Float64(ll_dist2(s, u, v)))
        s.weight[u * LL_MAX_N + v] = length
        s.weight[v * LL_MAX_N + u] = length

    var first_u = LL_MAX_N
    var first_v = LL_MAX_N
    for u in range(n):
        for v in range(n):
            if s.tree[u * LL_MAX_N + v] and (u < first_u or (u == first_u and v < first_v)):
                first_u = u
                first_v = v
    if first_u == LL_MAX_N: return False
    s.contour_u[0] = first_u
    s.contour_v[0] = first_v
    s.contour_len = 1
    let expected_darts = 2 * (n - 1)
    while s.contour_len < expected_darts:
        let last = s.contour_len - 1
        let (found, next_u, next_v) = ll_cw_tree_next(s, s.contour_u[last], s.contour_v[last])
        if not found: return False
        if next_u == first_u and next_v == first_v: break
        for i in range(s.contour_len):
            if s.contour_u[i] == next_u and s.contour_v[i] == next_v: return False
        s.contour_u[s.contour_len] = next_u
        s.contour_v[s.contour_len] = next_v
        s.contour_len += 1
    if s.contour_len != expected_darts: return False
    let (closed, close_u, close_v) = ll_cw_tree_next(s, s.contour_u[s.contour_len - 1], s.contour_v[s.contour_len - 1])
    closed and close_u == first_u and close_v == first_v

fn ll_run(inout s: LLState, n: Int) -> (Bool, Int, Int):
    for i in range(s.contour_len):
        if not ll_push_candidate(s, s.contour_u[i], s.contour_v[i]): return (False, 0, 0)
    var absorbed = 0
    var steps = 0
    while s.stack_len > 0 and steps < 2 * LL_MAX_EDGES:
        s.stack_len -= 1
        let v = s.stack_u[s.stack_len]
        let w = s.stack_v[s.stack_len]
        if not ll_eligible(s, v, w): continue
        let at = ll_contour_find(s, v, w)
        let next_at = (at + 1) % s.contour_len
        let u = s.contour_v[next_at]
        let path_weight = s.weight[v * LL_MAX_N + w] + s.weight[w * LL_MAX_N + u]
        let chord_length = sqrt(Float64(ll_dist2(s, v, u)))
        if path_weight > 2.0 * chord_length:
            s.kept[v * LL_MAX_N + u] = True
            s.kept[u * LL_MAX_N + v] = True
        else:
            s.weight[v * LL_MAX_N + u] = path_weight

        if next_at == 0:
            for i in range(s.contour_len - 1):
                s.contour_u[i] = s.contour_u[i + 1]
                s.contour_v[i] = s.contour_v[i + 1]
            s.contour_len -= 1
            s.contour_u[s.contour_len - 1] = v
            s.contour_v[s.contour_len - 1] = u
        else:
            s.contour_u[at] = v
            s.contour_v[at] = u
            for i in range(next_at, s.contour_len - 1):
                s.contour_u[i] = s.contour_u[i + 1]
                s.contour_v[i] = s.contour_v[i + 1]
            s.contour_len -= 1
        ll_canonicalize(s)
        absorbed += 1
        steps += 1

        let chord_at = ll_contour_find(s, v, u)
        if chord_at < 0 or not ll_push_candidate(s, v, u): return (False, 0, 0)
        let left_at = (chord_at + s.contour_len - 1) % s.contour_len
        if not ll_push_candidate(s, s.contour_u[left_at], s.contour_v[left_at]): return (False, 0, 0)
    if steps >= 2 * LL_MAX_EDGES and s.stack_len > 0: return (False, 0, 0)
    var shortcuts = 0
    for u in range(n):
        for v in range(u + 1, n):
            if s.kept[u * LL_MAX_N + v] and not s.tree[u * LL_MAX_N + v]: shortcuts += 1
    (True, absorbed, shortcuts)

fn ll_write_i64(output: UnsafePointer[UInt8, MutAnyOrigin], word: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[word * 8 + byte] = UInt8((bits >> UInt(8 * byte)) & UInt64(255))

@export("levcopoulos_lingas_planar_geometric_spanner")
fn levcopoulos_lingas_planar_geometric_spanner(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    var s = LLState()
    let (valid, n) = ll_parse(s, input, length)
    if not valid or not ll_build_mst_contour(s, n): return -1
    let (completed, absorbed, shortcuts) = ll_run(s, n)
    if not completed: return -1

    var words = InlineArray[Int64, LL_MAX_WORDS](fill=0)
    words[0] = Int64(absorbed)
    words[1] = Int64(shortcuts)
    var word_count = 3
    for u in range(n):
        for v in range(u + 1, n):
            if s.kept[u * LL_MAX_N + v]:
                words[word_count] = Int64(u)
                words[word_count + 1] = Int64(v)
                word_count += 2
                words[2] += 1
    let output_bytes = word_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    for i in range(word_count): ll_write_i64(output, i, words[i])
    Int64(output_bytes)
