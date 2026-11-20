from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N: Int = 64
const SLOTS: Int = 129
const INF: Int64 = 9223372036854775807

struct BlossomSearch:
    var n: Int
    var nodes: Int
    var epoch: Int
    var weight: InlineArray[Int64, SLOTS * SLOTS]
    var dual: InlineArray[Int64, SLOTS]
    var edge_a: InlineArray[Int32, SLOTS * SLOTS]
    var edge_b: InlineArray[Int32, SLOTS * SLOTS]
    var mate: InlineArray[Int32, SLOTS]
    var slack_from: InlineArray[Int32, SLOTS]
    var top: InlineArray[Int32, SLOTS]
    var parent: InlineArray[Int32, SLOTS]
    var state: InlineArray[Int32, SLOTS]
    var seen: InlineArray[Int, SLOTS]
    var members: InlineArray[Int32, SLOTS * SLOTS]
    var member_count: InlineArray[Int32, SLOTS]
    var child_of: InlineArray[Int32, SLOTS * (MAX_N + 1)]
    var queue: InlineArray[Int, MAX_N]
    var queued: InlineArray[Bool, MAX_N + 1]
    var head: Int
    var tail: Int
    var count: Int

    fn __init__(out self):
        self.n = 0
        self.nodes = 0
        self.epoch = 0
        self.weight = InlineArray[Int64, SLOTS * SLOTS]()
        self.dual = InlineArray[Int64, SLOTS]()
        self.edge_a = InlineArray[Int32, SLOTS * SLOTS]()
        self.edge_b = InlineArray[Int32, SLOTS * SLOTS]()
        self.mate = InlineArray[Int32, SLOTS]()
        self.slack_from = InlineArray[Int32, SLOTS]()
        self.top = InlineArray[Int32, SLOTS]()
        self.parent = InlineArray[Int32, SLOTS]()
        self.state = InlineArray[Int32, SLOTS]()
        self.seen = InlineArray[Int, SLOTS]()
        self.members = InlineArray[Int32, SLOTS * SLOTS]()
        self.member_count = InlineArray[Int32, SLOTS]()
        self.child_of = InlineArray[Int32, SLOTS * (MAX_N + 1)]()
        self.queue = InlineArray[Int, MAX_N]()
        self.queued = InlineArray[Bool, MAX_N + 1]()
        self.head = 0
        self.tail = 0
        self.count = 0

    fn matrix(self, a: Int, b: Int) -> Int:
        return a * SLOTS + b

    fn provenance(self, b: Int, leaf: Int) -> Int:
        return b * (MAX_N + 1) + leaf

    fn member(self, b: Int, i: Int) -> Int:
        return b * SLOTS + i

    fn delta(self, a: Int, b: Int) -> Int64:
        let at = self.matrix(a, b)
        return self.dual[self.edge_a[at]] + self.dual[self.edge_b[at]] - 2 * self.weight[at]

    fn enqueue_leaf(mut self, v: Int):
        if v <= 0 or v > self.n or self.queued[v]: return
        self.queue[self.tail] = v
        self.tail = (self.tail + 1) % self.n
        self.count += 1
        self.queued[v] = True

    fn enqueue_members(mut self, x: Int):
        if x <= self.n:
            self.enqueue_leaf(x)
            return
        for i in range(self.member_count[x]):
            self.enqueue_members(self.members[self.member(x, i)])

    fn set_top(mut self, x: Int, b: Int):
        self.top[x] = b
        if x > self.n:
            for i in range(self.member_count[x]):
                self.set_top(self.members[self.member(x, i)], b)

    fn update_slack(mut self, u: Int, x: Int):
        let old = self.slack_from[x]
        if old == 0 or self.delta(u, x) < self.delta(old, x):
            self.slack_from[x] = u

    fn refresh_slack(mut self, x: Int):
        self.slack_from[x] = 0
        for u in range(1, self.n + 1):
            let component = self.top[u]
            if self.weight[self.matrix(u, x)] > 0 and component != x and self.state[component] == 0:
                self.update_slack(u, x)

    fn cycle_position(mut self, b: Int, child: Int) -> Int:
        let size = self.member_count[b]
        var pos = 0
        while pos < size and self.members[self.member(b, pos)] != child:
            pos += 1
        if pos >= size: return 0
        if pos % 2 == 1:
            var left = 1
            var right = size - 1
            while left < right:
                let a = self.member(b, left)
                let z = self.member(b, right)
                let tmp = self.members[a]
                self.members[a] = self.members[z]
                self.members[z] = tmp
                left += 1
                right -= 1
            pos = size - pos
        return pos

    fn rotate_cycle(mut self, b: Int, start: Int):
        let size = self.member_count[b]
        var copy = InlineArray[Int32, SLOTS]()
        for i in range(size): copy[i] = self.members[self.member(b, (i + start) % size)]
        for i in range(size): self.members[self.member(b, i)] = copy[i]

    fn set_pair(mut self, u: Int, v: Int):
        let at = self.matrix(u, v)
        self.mate[u] = self.edge_b[at]
        if u <= self.n: return
        let leaf = self.edge_a[at]
        let entry = self.child_of[self.provenance(u, leaf)]
        let pos = self.cycle_position(u, entry)
        for i in range(pos):
            self.set_pair(self.members[self.member(u, i)], self.members[self.member(u, i ^ 1)])
        self.set_pair(entry, v)
        self.rotate_cycle(u, pos)

    fn augment(mut self, u_start: Int, v_start: Int):
        var u = u_start
        var v = v_start
        while True:
            let next = self.top[self.mate[u]]
            self.set_pair(u, v)
            if next == 0: return
            let prior = self.top[self.parent[next]]
            self.set_pair(next, prior)
            u = prior
            v = next

    fn common_base(mut self, u_start: Int, v_start: Int) -> Int:
        self.epoch += 1
        var u = u_start
        var v = v_start
        while u != 0 or v != 0:
            if u != 0:
                if self.seen[u] == self.epoch: return u
                self.seen[u] = self.epoch
                u = self.top[self.mate[u]]
                if u != 0: u = self.top[self.parent[u]]
            let temp = u
            u = v
            v = temp
        return 0

    fn add_child(mut self, b: Int, x: Int):
        let at = self.member(b, self.member_count[b])
        self.members[at] = x
        self.member_count[b] += 1

    fn contract(mut self, u: Int, base: Int, v: Int):
        var b = self.n + 1
        while b <= self.nodes and self.top[b] != 0: b += 1
        if b > self.nodes: self.nodes += 1
        self.dual[b] = 0
        self.state[b] = 0
        self.mate[b] = self.mate[base]
        self.member_count[b] = 0
        self.add_child(b, base)
        var x = u
        while x != base:
            self.add_child(b, x)
            let y = self.top[self.mate[x]]
            self.add_child(b, y)
            self.enqueue_members(y)
            x = self.top[self.parent[y]]
        var left = 1
        var right = self.member_count[b] - 1
        while left < right:
            let li = self.member(b, left)
            let ri = self.member(b, right)
            let temp = self.members[li]
            self.members[li] = self.members[ri]
            self.members[ri] = temp
            left += 1
            right -= 1
        x = v
        while x != base:
            self.add_child(b, x)
            let y = self.top[self.mate[x]]
            self.add_child(b, y)
            self.enqueue_members(y)
            x = self.top[self.parent[y]]
        self.set_top(b, b)

        for y in range(1, self.nodes + 1):
            let by = self.matrix(b, y)
            let yb = self.matrix(y, b)
            self.weight[by] = 0; self.weight[yb] = 0
            self.edge_a[by] = 0; self.edge_b[by] = 0
            self.edge_a[yb] = 0; self.edge_b[yb] = 0
        for leaf in range(MAX_N + 1): self.child_of[self.provenance(b, leaf)] = 0
        for i in range(self.member_count[b]):
            let child = self.members[self.member(b, i)]
            for y in range(1, self.nodes + 1):
                let cy = self.matrix(child, y)
                let by = self.matrix(b, y)
                if self.weight[cy] == 0: continue
                if self.weight[by] == 0 or self.delta(child, y) < self.delta(b, y):
                    self.weight[by] = self.weight[cy]
                    self.edge_a[by] = self.edge_a[cy]
                    self.edge_b[by] = self.edge_b[cy]
                    let yc = self.matrix(y, child)
                    let yb = self.matrix(y, b)
                    self.weight[yb] = self.weight[yc]
                    self.edge_a[yb] = self.edge_a[yc]
                    self.edge_b[yb] = self.edge_b[yc]
            for leaf in range(1, self.n + 1):
                var contains = child == leaf
                if child > self.n: contains = self.child_of[self.provenance(child, leaf)] != 0
                if contains: self.child_of[self.provenance(b, leaf)] = child
        self.refresh_slack(b)

    fn expand(mut self, b: Int):
        for i in range(self.member_count[b]):
            let child = self.members[self.member(b, i)]
            self.set_top(child, child)
        let outside = self.parent[b]
        let entry_leaf = self.edge_a[self.matrix(b, outside)]
        let entry = self.child_of[self.provenance(b, entry_leaf)]
        let pos = self.cycle_position(b, entry)
        var i = 0
        while i < pos:
            let inner = self.members[self.member(b, i)]
            let outer = self.members[self.member(b, i + 1)]
            self.parent[inner] = self.edge_a[self.matrix(outer, inner)]
            self.state[inner] = 1
            self.state[outer] = 0
            self.slack_from[inner] = 0
            self.refresh_slack(outer)
            self.enqueue_members(outer)
            i += 2
        self.state[entry] = 1
        self.parent[entry] = outside
        for i in range(pos + 1, self.member_count[b]):
            let child = self.members[self.member(b, i)]
            self.state[child] = -1
            self.refresh_slack(child)
        self.top[b] = 0

    fn process_edge(mut self, left: Int, right: Int) -> Bool:
        let u = self.top[left]
        let v = self.top[right]
        if self.state[v] == -1:
            self.parent[v] = left
            self.state[v] = 1
            let next = self.top[self.mate[v]]
            self.slack_from[v] = 0
            self.slack_from[next] = 0
            self.state[next] = 0
            self.enqueue_members(next)
        elif self.state[v] == 0:
            let base = self.common_base(u, v)
            if base == 0:
                self.augment(u, v)
                self.augment(v, u)
                return True
            self.contract(u, base, v)
        return False

    fn stage(mut self) -> Bool:
        for x in range(self.nodes + 1):
            self.state[x] = -1
            self.slack_from[x] = 0
        self.head = 0; self.tail = 0; self.count = 0
        for i in range(MAX_N + 1): self.queued[i] = False
        for x in range(1, self.nodes + 1):
            if self.top[x] == x and self.mate[x] == 0:
                self.parent[x] = 0
                self.state[x] = 0
                self.enqueue_members(x)
        if self.count == 0: return False

        while True:
            while self.count != 0:
                let u = self.queue[self.head]
                self.head = (self.head + 1) % self.n
                self.count -= 1
                self.queued[u] = False
                if self.state[self.top[u]] == 1: continue
                for v in range(1, self.n + 1):
                    if self.weight[self.matrix(u, v)] == 0 or self.top[u] == self.top[v]: continue
                    if self.delta(u, v) == 0:
                        let at = self.matrix(u, v)
                        if self.process_edge(self.edge_a[at], self.edge_b[at]): return True
                    else:
                        self.update_slack(u, self.top[v])
            var step = INF
            for u in range(1, self.n + 1):
                if self.state[self.top[u]] == 0 and self.dual[u] < step: step = self.dual[u]
            for b in range(self.n + 1, self.nodes + 1):
                if self.top[b] == b and self.state[b] == 1 and self.dual[b] / 2 < step: step = self.dual[b] / 2
            for x in range(1, self.nodes + 1):
                if self.top[x] != x or self.slack_from[x] == 0: continue
                let slack = self.delta(self.slack_from[x], x)
                if self.state[x] == -1 and slack < step: step = slack
                elif self.state[x] == 0 and slack / 2 < step: step = slack / 2
            if step == INF: return False
            for u in range(1, self.n + 1):
                let state = self.state[self.top[u]]
                if state == 0:
                    if self.dual[u] == step: return False
                    self.dual[u] -= step
                elif state == 1:
                    self.dual[u] += step
            for b in range(self.n + 1, self.nodes + 1):
                if self.top[b] != b: continue
                if self.state[b] == 0: self.dual[b] += 2 * step
                elif self.state[b] == 1: self.dual[b] -= 2 * step
            for x in range(1, self.nodes + 1):
                if self.top[x] != x or self.slack_from[x] == 0 or self.top[self.slack_from[x]] == x: continue
                if self.delta(self.slack_from[x], x) == 0:
                    let at = self.matrix(self.slack_from[x], x)
                    if self.process_edge(self.edge_a[at], self.edge_b[at]): return True
            for b in range(self.n + 1, self.nodes + 1):
                if self.top[b] == b and self.state[b] == 1 and self.dual[b] == 0: self.expand(b)

@export("general_weighted_matching_primal_dual_blossom")
fn general_weighted_matching_primal_dual_blossom(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 6051: return -2
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_N or m_value < 0 or m_value > n_value * (n_value - 1) / 2: return -2
    let n = Int(n_value)
    let edges = Int(m_value)
    if length != c_size_t(2 + 3 * edges): return -2
    var search = BlossomSearch()
    search.n = n
    search.nodes = n
    var largest: Int64 = 0
    for i in range(edges):
        let u_value = input[2 + 3 * i]
        let v_value = input[3 + 3 * i]
        let weight = input[4 + 3 * i]
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value or weight < 1 or weight > 1_000_000: return -2
        let u = Int(u_value) + 1
        let v = Int(v_value) + 1
        let at_uv = search.matrix(u, v)
        let at_vu = search.matrix(v, u)
        if search.weight[at_uv] != 0: return -2
        search.weight[at_uv] = weight
        search.weight[at_vu] = weight
        search.edge_a[at_uv] = u; search.edge_b[at_uv] = v
        search.edge_a[at_vu] = v; search.edge_b[at_vu] = u
        if weight > largest: largest = weight
    for u in range(1, n + 1):
        search.top[u] = u
        search.dual[u] = largest
        search.child_of[search.provenance(u, u)] = u
    while search.stage(): pass
    var answer: Int64 = 0
    for u in range(1, n + 1):
        let v = search.mate[u]
        if v > u: answer += search.weight[search.matrix(u, v)]
    return answer
