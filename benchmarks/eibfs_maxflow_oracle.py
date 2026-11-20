"""Bounded Excesses IBFS (EIBFS) max-flow reference.

The primary follows the paper's two-tree pseudoflow method.  It uses a fixed
vertex/neighbor order, full adjacency rescans after an augmentation, and the
    paper's round-robin orphan relabel rule.  For the final scalar result it
    starts from every source-forest vertex (including positive-excess roots),
    closes that blocking-cut side under residual reachability, and sums the
    original capacities crossing the resulting cut.
"""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MIN_VERTICES = 2
MAX_VERTICES = 8
MAX_EDGES = 24
MAX_CAPACITY = 100
MAX_VALID_INPUT_LENGTH = 4 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = MAX_EDGES * MAX_CAPACITY

FREE = 0
SOURCE_TREE = 1
SINK_TREE = 2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, int, list[tuple[int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    n, m, source, sink = values[:4]
    if (not MIN_VERTICES <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES
            or not 0 <= source < n or not 0 <= sink < n or source == sink
            or len(values) != 4 + 3 * m):
        return None
    edges: list[tuple[int, int, int]] = []
    for offset in range(4, len(values), 3):
        u, v, capacity = values[offset:offset + 3]
        if not (0 <= u < n and 0 <= v < n and u != v
                and 0 <= capacity <= MAX_CAPACITY):
            return None
        edges.append((u, v, capacity))
    return n, source, sink, edges


class _EIBFS:
    def __init__(self, n: int, source: int, sink: int,
                 edges: list[tuple[int, int, int]]) -> None:
        self.n = n
        self.source = source
        self.sink = sink
        self.original = [[0] * n for _ in range(n)]
        self.residual = [[0] * n for _ in range(n)]
        for u, v, capacity in edges:
            self.original[u][v] += capacity
            self.residual[u][v] += capacity
        self.balance = [0] * n  # incoming minus outgoing pseudoflow
        self.kind = [FREE] * n
        self.parent = [-1] * n
        self.ds = [0] * n
        self.dt = [0] * n
        self.kind[source] = SOURCE_TREE
        self.kind[sink] = SINK_TREE
        self.Ds = 0
        self.Dt = 0
        self.forward = True
        self.orphaned = [False] * n
        self.steps = 0

    def push(self, u: int, v: int, amount: int) -> None:
        self.residual[u][v] -= amount
        self.residual[v][u] += amount
        if u != self.source and u != self.sink:
            self.balance[u] -= amount
        if v != self.source and v != self.sink:
            self.balance[v] += amount

    def root(self, vertex: int) -> int:
        current = vertex
        for _ in range(self.n):
            if self.parent[current] < 0:
                return current
            current = self.parent[current]
        return -1

    def path_bottleneck(self, vertex: int, kind: int) -> int:
        amount = MAX_RESULT + 1
        current = vertex
        for _ in range(self.n):
            parent = self.parent[current]
            if parent < 0:
                return amount
            if kind == SOURCE_TREE:
                amount = min(amount, self.residual[parent][current])
            else:
                amount = min(amount, self.residual[current][parent])
            current = parent
        return 0

    def _mark_orphan(self, vertex: int, queue: deque[int]) -> None:
        if not self.orphaned[vertex]:
            self.orphaned[vertex] = True
            queue.append(vertex)

    def _detach_children(self, vertex: int, kind: int,
                         queue: deque[int]) -> None:
        for child in range(self.n):
            if self.kind[child] == kind and self.parent[child] == vertex:
                self.parent[child] = -1
                self._mark_orphan(child, queue)

    def _adopt_t(self, vertex: int, queue: deque[int]) -> None:
        self.orphaned[vertex] = False
        old_label = self.dt[vertex]
        exact = -1
        for candidate in range(self.n):
            if (candidate != vertex and self.kind[candidate] == SINK_TREE
                    and self.residual[vertex][candidate] > 0
                    and self.dt[vertex] == self.dt[candidate] + 1):
                exact = candidate
                break
        if exact >= 0:
            self.parent[vertex] = exact
            return

        limit = self.Dt - (1 if self.forward else 0)
        best_label = self.n * 4
        for candidate in range(self.n):
            if (candidate != vertex and self.kind[candidate] == SINK_TREE
                    and self.residual[vertex][candidate] > 0
                    and self.dt[candidate] <= limit):
                best_label = min(best_label, self.dt[candidate])
        parent = -1
        if best_label < self.n * 4:
            for candidate in range(self.n):
                if (candidate != vertex and self.kind[candidate] == SINK_TREE
                        and self.residual[vertex][candidate] > 0
                        and self.dt[candidate] == best_label):
                    parent = candidate
                    break
        if parent >= 0 and best_label + 1 > old_label:
            self._detach_children(vertex, SINK_TREE, queue)
            self.parent[vertex] = parent
            self.dt[vertex] = best_label + 1
            return

        self._detach_children(vertex, SINK_TREE, queue)
        self.parent[vertex] = -1
        self.kind[vertex] = FREE
        if self.balance[vertex] > 0:
            self.kind[vertex] = SOURCE_TREE
            self.ds[vertex] = self.Ds + (1 if self.forward else 0)

    def _adopt_s(self, vertex: int, queue: deque[int]) -> None:
        self.orphaned[vertex] = False
        old_label = self.ds[vertex]
        exact = -1
        for candidate in range(self.n):
            if (candidate != vertex and self.kind[candidate] == SOURCE_TREE
                    and self.residual[candidate][vertex] > 0
                    and self.ds[vertex] == self.ds[candidate] + 1):
                exact = candidate
                break
        if exact >= 0:
            self.parent[vertex] = exact
            return

        limit = self.Ds - (0 if self.forward else 1)
        best_label = self.n * 4
        for candidate in range(self.n):
            if (candidate != vertex and self.kind[candidate] == SOURCE_TREE
                    and self.residual[candidate][vertex] > 0
                    and self.ds[candidate] <= limit):
                best_label = min(best_label, self.ds[candidate])
        parent = -1
        if best_label < self.n * 4:
            for candidate in range(self.n):
                if (candidate != vertex and self.kind[candidate] == SOURCE_TREE
                        and self.residual[candidate][vertex] > 0
                        and self.ds[candidate] == best_label):
                    parent = candidate
                    break
        if parent >= 0 and best_label + 1 > old_label:
            self._detach_children(vertex, SOURCE_TREE, queue)
            self.parent[vertex] = parent
            self.ds[vertex] = best_label + 1
            return

        self._detach_children(vertex, SOURCE_TREE, queue)
        self.parent[vertex] = -1
        self.kind[vertex] = FREE
        if self.balance[vertex] < 0:
            self.kind[vertex] = SINK_TREE
            self.dt[vertex] = self.Dt + (0 if self.forward else 1)

    def _repair_orphans(self, kind: int, queue: deque[int]) -> None:
        while queue:
            vertex = queue.popleft()
            self.orphaned[vertex] = False
            if self.kind[vertex] != kind:
                continue
            if kind == SINK_TREE:
                self._adopt_t(vertex, queue)
            else:
                self._adopt_s(vertex, queue)

    def drain_t_excess(self, vertex: int) -> None:
        root = self.root(vertex)
        if root < 0:
            return
        queue: deque[int] = deque()
        current = vertex
        while self.balance[current] > 0 and self.parent[current] >= 0:
            parent = self.parent[current]
            amount = min(self.balance[current], self.residual[current][parent])
            if amount > 0:
                self.push(current, parent, amount)
            if self.residual[current][parent] == 0 and self.balance[current] >= 0:
                self.parent[current] = -1
                self._mark_orphan(current, queue)
                break
            if self.balance[current] == 0:
                break
            current = parent
        if root != self.sink and self.kind[root] == SINK_TREE and self.balance[root] >= 0:
            self.parent[root] = -1
            self._mark_orphan(root, queue)
        self._repair_orphans(SINK_TREE, queue)

    def drain_s_deficit(self, vertex: int) -> None:
        root = self.root(vertex)
        if root < 0:
            return
        queue: deque[int] = deque()
        current = vertex
        while self.balance[current] < 0 and self.parent[current] >= 0:
            parent = self.parent[current]
            amount = min(-self.balance[current], self.residual[parent][current])
            if amount > 0:
                self.push(parent, current, amount)
            if self.residual[parent][current] == 0 and self.balance[current] <= 0:
                self.parent[current] = -1
                self._mark_orphan(current, queue)
                break
            if self.balance[current] == 0:
                break
            current = parent
        if root != self.source and self.kind[root] == SOURCE_TREE and self.balance[root] <= 0:
            self.parent[root] = -1
            self._mark_orphan(root, queue)
        self._repair_orphans(SOURCE_TREE, queue)

    def repair_pseudoflow(self) -> None:
        while True:
            work = False
            for vertex in range(self.n):
                if self.kind[vertex] == SINK_TREE and self.balance[vertex] > 0:
                    self.drain_t_excess(vertex)
                    work = True
                    break
            if work:
                continue
            for vertex in range(self.n):
                if self.kind[vertex] == SOURCE_TREE and self.balance[vertex] < 0:
                    self.drain_s_deficit(vertex)
                    work = True
                    break
            if not work:
                return

    def augment(self, v: int, w: int) -> bool:
        root_s = self.root(v)
        root_t = self.root(w)
        if root_s < 0 or root_t < 0:
            return False
        connector = self.residual[v][w]
        if connector <= 0:
            return False
        bottleneck_s = self.path_bottleneck(v, SOURCE_TREE)
        bottleneck_t = self.path_bottleneck(w, SINK_TREE)
        if root_s == self.source and root_t == self.sink:
            amount = connector
        elif root_s == self.source:
            amount = min(bottleneck_s, connector)
        elif root_t == self.sink:
            amount = min(connector, bottleneck_t)
        else:
            amount = min(self.balance[root_s], bottleneck_s, connector,
                         bottleneck_t, -self.balance[root_t])
        if amount <= 0:
            return False
        self.push(v, w, amount)
        self.repair_pseudoflow()
        return True

    def run(self) -> int:
        phases = 0
        while phases <= 4 * self.n + 4:
            phases += 1
            if self.forward:
                restart = True
                while restart:
                    restart = False
                    for v in range(self.n):
                        if self.kind[v] != SOURCE_TREE or self.ds[v] != self.Ds:
                            continue
                        for w in range(self.n):
                            if self.residual[v][w] <= 0 or self.kind[w] == SOURCE_TREE:
                                continue
                            if self.kind[w] == FREE:
                                self.kind[w] = SOURCE_TREE
                                self.parent[w] = v
                                self.ds[w] = self.Ds + 1
                                continue
                            if self.kind[w] == SINK_TREE:
                                self.steps += 1
                                if self.steps > 100000:
                                    return -1
                                if self.augment(v, w):
                                    restart = True
                                    break
                        if restart:
                            break
                if not any(self.kind[v] == SOURCE_TREE and self.ds[v] == self.Ds + 1
                           for v in range(self.n)):
                    break
                self.Ds += 1
            else:
                restart = True
                while restart:
                    restart = False
                    for w in range(self.n):
                        if self.kind[w] != SINK_TREE or self.dt[w] != self.Dt:
                            continue
                        for v in range(self.n):
                            if self.residual[v][w] <= 0 or self.kind[v] == SINK_TREE:
                                continue
                            if self.kind[v] == FREE:
                                self.kind[v] = SINK_TREE
                                self.parent[v] = w
                                self.dt[v] = self.Dt + 1
                                continue
                            if self.kind[v] == SOURCE_TREE:
                                self.steps += 1
                                if self.steps > 100000:
                                    return -1
                                if self.augment(v, w):
                                    restart = True
                                    break
                        if restart:
                            break
                if not any(self.kind[v] == SINK_TREE and self.dt[v] == self.Dt + 1
                           for v in range(self.n)):
                    break
                self.Dt += 1
            self.forward = not self.forward

        source_side = [self.kind[v] == SOURCE_TREE for v in range(self.n)]
        queue = deque(v for v in range(self.n) if source_side[v])
        while queue:
            u = queue.popleft()
            for v in range(self.n):
                if self.residual[u][v] > 0 and not source_side[v]:
                    source_side[v] = True
                    queue.append(v)
        return sum(capacity for u in range(self.n) for v in range(self.n)
                   if source_side[u] and not source_side[v]
                   for capacity in (self.original[u][v],))


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, source, sink, edges = parsed
    return _EIBFS(n, source, sink, edges).run()
