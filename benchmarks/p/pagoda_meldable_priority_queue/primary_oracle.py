"""Pagoda parent/extreme-link reference for bounded priority-queue traces."""

INVALID_RESULT = -1
MAX_QUEUES = 8
MAX_OPERATIONS = 64
MAX_PRIORITY = 1000
MIN_PRIORITY = -1000
MAX_VALID_INPUT_WORDS = 258
MAX_PARSEABLE_INPUT_WORDS = 259


def _frame(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_WORDS
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    queue_count, operation_count = values[:2]
    if (not 1 <= queue_count <= MAX_QUEUES
            or not 0 <= operation_count <= MAX_OPERATIONS
            or len(values) != 2 + 4 * operation_count
            or len(values) > MAX_VALID_INPUT_WORDS):
        return None
    return queue_count, operation_count


def expected_output(values, input_is_null=False, input_length=None):
    frame = _frame(values, input_is_null, input_length)
    if frame is None:
        return INVALID_RESULT
    _, operation_count = frame

    keys = [0] * MAX_OPERATIONS
    leftmost = [-1] * MAX_OPERATIONS
    rightmost = [-1] * MAX_OPERATIONS
    roots = [-1] * MAX_QUEUES
    node_count = 0

    def extreme_branch(root, right_branch):
        if root < 0:
            return []
        pointer = rightmost[root] if right_branch else leftmost[root]
        if not 0 <= pointer < node_count:
            return []
        branch = []
        node = pointer
        while True:
            branch.append(node)
            if node == root:
                return branch
            # On a right branch d is the parent link; on a left branch g is.
            node = rightmost[node] if right_branch else leftmost[node]
            if not 0 <= node < node_count or len(branch) > node_count:
                return []

    def meld(g_root, d_root):
        if g_root < 0:
            return d_root
        if d_root < 0:
            return g_root

        right_branch = extreme_branch(g_root, True)
        left_branch = extreme_branch(d_root, False)
        if not right_branch or not left_branch:
            return -1

        i = 0
        j = 0
        central = -1
        central_leftmost = -1
        central_rightmost = -1
        while i < len(right_branch) or j < len(left_branch):
            take_g = (j >= len(left_branch)
                      or (i < len(right_branch)
                          and keys[right_branch[i]] > keys[left_branch[j]]))
            if take_g:
                node = right_branch[i]
                i += 1
                kept_leftmost = leftmost[node]
            else:
                node = left_branch[j]
                j += 1
                kept_rightmost = rightmost[node]

            if central >= 0:
                if take_g:
                    # G contributes the right edge; the chain's left extreme
                    # remains the one already present in the central subtree.
                    rightmost[central] = node
                    leftmost[central] = (-1 if central_leftmost == central
                                         else central_leftmost)
                else:
                    # D contributes the left edge.
                    leftmost[central] = node
                    rightmost[central] = (-1 if central_rightmost == central
                                          else central_rightmost)

            if take_g:
                new_leftmost = node if kept_leftmost < 0 else kept_leftmost
                new_rightmost = central_rightmost if central >= 0 else node
            else:
                new_leftmost = central_leftmost if central >= 0 else node
                new_rightmost = node if kept_rightmost < 0 else kept_rightmost

            leftmost[node] = new_leftmost
            rightmost[node] = new_rightmost
            central = node
            central_leftmost = new_leftmost
            central_rightmost = new_rightmost
        return central

    inserted_priorities = []
    result = 0
    for operation_index in range(operation_count):
        offset = 2 + 4 * operation_index
        opcode, first, second, priority = values[offset:offset + 4]

        if opcode == 1:
            if (not 0 <= first < frame[0] or second != 0
                    or not MIN_PRIORITY <= priority <= MAX_PRIORITY
                    or priority in inserted_priorities or node_count >= MAX_OPERATIONS):
                return INVALID_RESULT
            inserted_priorities.append(priority)
            node = node_count
            node_count += 1
            keys[node] = priority
            leftmost[node] = node
            rightmost[node] = node
            merged = meld(roots[first], node)
            if merged < 0:
                return INVALID_RESULT
            roots[first] = merged
        elif opcode == 2:
            if (not 0 <= first < frame[0] or not 0 <= second < frame[0]
                    or first == second or priority != 0):
                return INVALID_RESULT
            merged = meld(roots[first], roots[second])
            roots[first] = merged
            roots[second] = -1
        elif opcode in (3, 4):
            if (not 0 <= first < frame[0] or second != 0 or priority != 0
                    or roots[first] < 0):
                return INVALID_RESULT
            root = roots[first]
            result += (operation_index + 1) * (keys[root] + 1001)
            if opcode == 4:
                old_leftmost = leftmost[root]
                old_rightmost = rightmost[root]
                left_child = -1
                right_child = -1
                if old_leftmost != root:
                    child = old_leftmost
                    while 0 <= child < node_count and leftmost[child] != root:
                        child = leftmost[child]
                    if child < 0 or child >= node_count or leftmost[child] != root:
                        return INVALID_RESULT
                    left_child = child
                if old_rightmost != root:
                    child = old_rightmost
                    while 0 <= child < node_count and rightmost[child] != root:
                        child = rightmost[child]
                    if child < 0 or child >= node_count or rightmost[child] != root:
                        return INVALID_RESULT
                    right_child = child

                if left_child >= 0:
                    leftmost[left_child] = old_leftmost
                    if rightmost[left_child] < 0:
                        rightmost[left_child] = left_child
                if right_child >= 0:
                    rightmost[right_child] = old_rightmost
                    if leftmost[right_child] < 0:
                        leftmost[right_child] = right_child
                # Section 3.4 removes the root by melding D+G: right then left.
                roots[first] = meld(right_child, left_child)
                leftmost[root] = -1
                rightmost[root] = -1
        else:
            return INVALID_RESULT

    return result
