# Bounded Olden Voronoi quad-edge draft; see package README for provenance.
# The pinned snapshot has no available license declaration; see the package README.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import floor
from std.memory import ImmutAnyOrigin, UnsafePointer

fn ov_rot(edge: Int) -> Int:
    return (edge & ~3) | ((edge + 1) & 3)

fn ov_rotinv(edge: Int) -> Int:
    return (edge & ~3) | ((edge + 3) & 3)

fn ov_sym(edge: Int) -> Int:
    return edge ^ 2

struct OldenQuadEdges:
    var x: InlineArray[Float64, 5]
    var y: InlineArray[Float64, 5]
    var norm: InlineArray[Float64, 5]
    var next: InlineArray[Int, 128]
    var origin: InlineArray[Int, 128]
    var alive: InlineArray[Bool, 32]
    var count: Int

    fn __init__(out self):
        self.x = InlineArray[Float64, 5](fill=0)
        self.y = InlineArray[Float64, 5](fill=0)
        self.norm = InlineArray[Float64, 5](fill=0)
        self.next = InlineArray[Int, 128](fill=0)
        self.origin = InlineArray[Int, 128](fill=0)
        self.alive = InlineArray[Bool, 32](fill=False)
        self.count = 0

    fn destination(self, edge: Int) -> Int:
        return self.origin[ov_sym(edge)]

    fn left_next(self, edge: Int) -> Int:
        return ov_rot(self.next[ov_rotinv(edge)])

    fn origin_previous(self, edge: Int) -> Int:
        return ov_rot(self.next[ov_rot(edge)])

    fn right_previous(self, edge: Int) -> Int:
        return self.next[ov_sym(edge)]

    fn left_previous(self, edge: Int) -> Int:
        return ov_sym(self.next[edge])

    fn orientation(self, a: Int, b: Int, c: Int) -> Float64:
        return ((self.x[a] - self.x[c]) * (self.y[b] - self.y[c]) -
                (self.x[b] - self.x[c]) * (self.y[a] - self.y[c]))

    fn circle_det(self, a: Int, b: Int, c: Int, d: Int) -> Float64:
        let ax = self.x[a] - self.x[d]; let ay = self.y[a] - self.y[d]
        let bx = self.x[b] - self.x[d]; let by = self.y[b] - self.y[d]
        let cx = self.x[c] - self.x[d]; let cy = self.y[c] - self.y[d]
        return ((self.norm[a] - self.norm[d]) * (bx*cy - by*cx) +
                (self.norm[b] - self.norm[d]) * (cx*ay - cy*ax) +
                (self.norm[c] - self.norm[d]) * (ax*by - ay*bx))

    fn make_edge(mut self, a: Int, b: Int) -> Int:
        if self.count >= 32: return -1
        let e = 4 * self.count
        self.alive[self.count] = True
        self.count += 1
        self.next[e] = e; self.next[e+1] = e+3
        self.next[e+2] = e+2; self.next[e+3] = e+1
        self.origin[e] = a; self.origin[e+2] = b
        return e

    fn splice(mut self, a: Int, b: Int):
        let alpha = ov_rot(self.next[a])
        let beta = ov_rot(self.next[b])
        let a_next = self.next[a]; let alpha_next = self.next[alpha]
        self.next[a] = self.next[b]; self.next[b] = a_next
        self.next[alpha] = self.next[beta]; self.next[beta] = alpha_next

    fn remove_edge(mut self, e: Int):
        let before = self.origin_previous(e)
        self.splice(e, before)
        let opposite = ov_sym(e)
        let opposite_before = self.origin_previous(opposite)
        self.splice(opposite, opposite_before)
        self.alive[e // 4] = False

    fn connect_left(mut self, a: Int, b: Int) -> Int:
        let e = self.make_edge(self.destination(a), self.origin[b])
        if e < 0: return -1
        let at = self.left_next(a)
        self.splice(e, at)
        self.splice(ov_sym(e), b)
        return e

    fn connect_right(mut self, a: Int, b: Int) -> Int:
        let e = self.make_edge(self.destination(a), self.origin[b])
        if e < 0: return -1
        self.splice(e, ov_sym(a))
        let at = self.origin_previous(b)
        self.splice(ov_sym(e), at)
        return e

    fn valid(self, candidate: Int, base: Int) -> Bool:
        return self.orientation(self.origin[base], self.destination(candidate),
                                self.destination(base)) > 0.0

    fn triangle(mut self, a: Int, b: Int, c: Int) -> (Int, Int):
        let ab = self.make_edge(a, b)
        let bc = self.make_edge(b, c)
        if ab < 0 or bc < 0: return (-1, -1)
        self.splice(ov_sym(ab), bc)
        let ca = self.connect_left(bc, ab)
        if ca < 0: return (-1, -1)
        if self.orientation(a, c, b) > 0.0: return (ov_sym(ca), ca)
        return (ab, ov_sym(bc))

    fn merge(mut self, left_outer: Int, left_inner: Int,
             right_inner: Int, right_outer: Int) -> (Int, Int):
        var ldi = left_inner; var rdi = right_inner
        var ldo = left_outer; var rdo = right_outer
        # Find the lower common tangent of the two triangulations.
        while True:
            let pivot = self.origin[rdi]
            var a = self.origin[ldi]; var b = self.destination(ldi)
            while self.orientation(a, b, pivot) > 0.0:
                ldi = self.left_next(ldi)
                a = self.origin[ldi]; b = self.destination(ldi)
            if self.orientation(self.destination(rdi), pivot, a) > 0.0:
                rdi = self.right_previous(rdi)
            else: break
        var base = self.connect_left(ov_sym(rdi), ldi)
        if base < 0: return (-1, -1)
        var lcand = self.right_previous(base)
        var rcand = self.origin_previous(base)
        if self.origin[base] == self.origin[rdo]: rdo = base
        if self.destination(base) == self.origin[ldo]: ldo = ov_sym(base)
        while True:
            var candidate = self.next[lcand]
            if self.valid(candidate, base):
                let fixed = self.origin[base]
                let root = self.origin[lcand]
                while self.circle_det(self.destination(lcand), self.destination(candidate), root, fixed) > 0.0:
                    self.remove_edge(lcand)
                    lcand = candidate
                    candidate = self.next[lcand]
            candidate = self.origin_previous(rcand)
            if self.valid(candidate, base):
                let fixed = self.destination(base)
                let root = self.origin[rcand]
                while self.circle_det(self.destination(candidate), self.destination(rcand), root, fixed) > 0.0:
                    self.remove_edge(rcand)
                    rcand = candidate
                    candidate = self.origin_previous(rcand)
            let left_valid = self.valid(lcand, base)
            let right_valid = self.valid(rcand, base)
            if not left_valid and not right_valid: return (ldo, rdo)
            if not left_valid or (right_valid and
                    self.circle_det(self.destination(lcand), self.origin[lcand],
                                    self.origin[rcand], self.destination(rcand)) > 0.0):
                base = self.connect_left(rcand, ov_sym(base))
                if base < 0: return (-1, -1)
                rcand = self.left_next(ov_sym(base))
            else:
                let edge = self.connect_right(lcand, base)
                if edge < 0: return (-1, -1)
                base = ov_sym(edge)
                lcand = self.right_previous(base)

    fn face(self, edge: Int) -> (Bool, Int, Int, Int, Float64, Float64):
        let e2 = self.left_next(edge)
        let e3 = self.left_next(e2)
        if self.left_next(e3) != edge: return (False, 0, 0, 0, 0.0, 0.0)
        let a = self.origin[edge]; let b = self.destination(edge)
        let c = self.destination(e2)
        if a == b or b == c or a == c or self.orientation(a, b, c) <= 0.0:
            return (False, 0, 0, 0, 0.0, 0.0)
        let vx = self.x[b] - self.x[a]; let vy = self.y[b] - self.y[a]
        let wx = self.x[c] - self.x[a]; let wy = self.y[c] - self.y[a]
        let denominator = -2.0 * (vx*wy - vy*wx)
        let numerator = (self.x[c]-self.x[b])*wx + (self.y[c]-self.y[b])*wy
        let cx = 0.5*(self.x[a]+self.x[b]) + numerator*vy/denominator
        let cy = 0.5*(self.y[a]+self.y[b]) - numerator*vx/denominator
        return (True, a, b, c, cx, cy)

@export("olden_voronoi")
fn olden_voronoi(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or (length != 7 and length != 11): return -1
    if input[0] != 3 and input[0] != 5: return -1
    let n = Int(input[0])
    if length != c_size_t(1 + 2*n): return -1
    var graph = OldenQuadEdges()
    for i in range(n):
        let x = input[1+2*i]; let y = input[2+2*i]
        if x < -8 or x > 8 or y < -8 or y > 8: return -1
        if i > 0 and input[1+2*(i-1)] >= x: return -1
        graph.x[i] = Float64(x); graph.y[i] = Float64(y)
        graph.norm[i] = Float64(x*x + y*y)
    for a in range(n):
        for b in range(a+1, n):
            for c in range(b+1, n):
                if graph.orientation(a, b, c) == 0.0: return -1
                for d in range(c+1, n):
                    if graph.circle_det(a, b, c, d) == 0.0: return -1
    let left = graph.triangle(0, 1, 2)
    if left[0] < 0: return -1
    if n == 5:
        let right = graph.make_edge(3, 4)
        if right < 0: return -1
        let hull = graph.merge(left[0], left[1], right, ov_sym(right))
        if hull[0] < 0: return -1
    var seen = InlineArray[Int, 48](fill=-1)
    var face_count = 0; var edge_count = 0; var dual = 0; var rays = 0
    var projection = Int64(0)
    for i in range(graph.count):
        if not graph.alive[i]: continue
        let e = 4*i
        let left_face = graph.face(e)
        let right_face = graph.face(ov_sym(e))
        if left_face[0] or right_face[0]:
            edge_count += 1
            if left_face[0] and right_face[0]: dual += 1
            else: rays += 1
        for side in range(2):
            let face = left_face if side == 0 else right_face
            if not face[0]: continue
            let a = face[1]; let b = face[2]; let c = face[3]
            var duplicate = False
            for j in range(face_count):
                let u = seen[3*j]; let v = seen[3*j+1]; let w = seen[3*j+2]
                if (a == u or a == v or a == w) and (b == u or b == v or b == w) and (c == u or c == v or c == w):
                    duplicate = True
            if not duplicate:
                if face_count >= 16: return -1
                seen[3*face_count] = a; seen[3*face_count+1] = b; seen[3*face_count+2] = c
                face_count += 1
                projection += Int64(floor(face[4]*1000.0 + 0.5)) + 2*Int64(floor(face[5]*1000.0 + 0.5))
    return projection + Int64(100*face_count + 10*dual + rays + edge_count)
