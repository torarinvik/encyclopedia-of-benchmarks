"""Small ROBDD relational-product reachability reference."""


class Manager:
    def __init__(self, variable_count):
        self.variable_count = variable_count
        self.nodes = [None, None]  # Terminal IDs are 0 and 1.
        self.unique = {}

    def make(self, variable, low, high):
        if low == high:
            return low
        key = (variable, low, high)
        known = self.unique.get(key)
        if known is not None:
            return known
        result = len(self.nodes)
        self.nodes.append(key)
        self.unique[key] = result
        return result

    def variable(self, node):
        return self.variable_count if node < 2 else self.nodes[node][0]

    def children_at(self, node, variable):
        if node >= 2 and self.nodes[node][0] == variable:
            return self.nodes[node][1], self.nodes[node][2]
        return node, node

    def apply(self, operation, left, right):
        cache = {}

        def visit(a, b):
            if operation == "and":
                if a == 0 or b == 0:
                    return 0
                if a == 1:
                    return b
                if b == 1 or a == b:
                    return a
            else:
                if a == 1 or b == 1:
                    return 1
                if a == 0:
                    return b
                if b == 0 or a == b:
                    return a
            pair = (a, b)
            if pair in cache:
                return cache[pair]
            variable = min(self.variable(a), self.variable(b))
            a0, a1 = self.children_at(a, variable)
            b0, b1 = self.children_at(b, variable)
            result = self.make(variable, visit(a0, b0), visit(a1, b1))
            cache[pair] = result
            return result

        return visit(left, right)

    def from_truth_table(self, bits, variable_count):
        def build(variable, prefix):
            if variable == variable_count:
                return int(bits[prefix])
            low = build(variable + 1, prefix * 2)
            high = build(variable + 1, prefix * 2 + 1)
            return self.make(variable, low, high)

        return build(0, 0)

    def exists_prefix(self, root, quantified_variables):
        cache = {}

        def visit(node):
            if node < 2:
                return node
            if node in cache:
                return cache[node]
            variable, low, high = self.nodes[node]
            low_result, high_result = visit(low), visit(high)
            if variable < quantified_variables:
                result = self.apply("or", low_result, high_result)
            else:
                result = self.make(variable, low_result, high_result)
            cache[node] = result
            return result

        return visit(root)

    def rename_suffix(self, root, first_variable):
        cache = {}

        def visit(node):
            if node < 2:
                return node
            if node in cache:
                return cache[node]
            variable, low, high = self.nodes[node]
            result = self.make(variable - first_variable, visit(low), visit(high))
            cache[node] = result
            return result

        return visit(root)

    def evaluate(self, root, assignment, variable_count=None):
        variable_count = self.variable_count if variable_count is None else variable_count
        node = root
        while node >= 2:
            variable, low, high = self.nodes[node]
            node = high if (assignment >> (variable_count - variable - 1)) & 1 else low
        return node


def parse(values):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= 133
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m, initial_mask, invariant_mask = values[:4]
    if not 1 <= n <= 3 or not 0 <= m <= 1:
        return None
    state_count = 1 << n
    state_mask = (1 << state_count) - 1
    relation_length = 1 << (2 * n + m)
    if (initial_mask < 0 or initial_mask & ~state_mask
            or invariant_mask < 0 or invariant_mask & ~state_mask
            or len(values) != 4 + relation_length
            or any(value not in (0, 1) for value in values[4:])):
        return None
    return n, m, initial_mask, invariant_mask, values[4:]


def expected(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, m, reached_mask, invariant_mask, relation_bits = parsed
    variable_count = 2 * n + m
    manager = Manager(variable_count)
    relation = manager.from_truth_table(relation_bits, variable_count)
    state_count = 1 << n

    for _ in range(state_count + 1):
        reached_bits = tuple((reached_mask >> state) & 1 for state in range(state_count))
        reached = manager.from_truth_table(reached_bits, n)
        product = manager.apply("and", reached, relation)
        next_set = manager.exists_prefix(product, n + m)
        next_set = manager.rename_suffix(next_set, n + m)
        joined = manager.apply("or", reached, next_set)
        if joined == reached:
            break
        reached_mask = sum(manager.evaluate(joined, state, n) << state
                           for state in range(state_count))
    else:
        return -1

    violation = int((reached_mask & ~invariant_mask) != 0)
    return (reached_mask << 1) | violation
