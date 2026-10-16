"""Bounded oracle for the Java WordBoggle trie/DFS benchmark."""

MAX_ROWS = 6
MAX_COLUMNS = 6
MAX_WORDS = 32
MAX_WORD_LENGTH = 15
MAX_INPUT_VALUES = 2 + MAX_ROWS * MAX_COLUMNS + 1 + MAX_WORDS * (MAX_WORD_LENGTH + 1)


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 4
            or len(values) > MAX_INPUT_VALUES
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    rows, columns = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return -1, b""
    cells = rows * columns
    cursor = 2 + cells
    if cursor >= len(values):
        return -1, b""
    count = values[cursor]
    cursor += 1
    if not 0 <= count <= MAX_WORDS:
        return -1, b""
    board = values[2:2 + cells]
    if any(not (65 <= c <= 90 or 97 <= c <= 122) for c in board):
        return -1, b""
    words = []
    for _ in range(count):
        if cursor >= len(values):
            return -1, b""
        n = values[cursor]
        cursor += 1
        if not 1 <= n <= MAX_WORD_LENGTH or cursor + n > len(values):
            return -1, b""
        word = values[cursor:cursor + n]
        cursor += n
        if any(not (65 <= c <= 90 or 97 <= c <= 122) for c in word):
            return -1, b""
        words.append(bytes(word))
    if cursor != len(values):
        return -1, b""

    rows_found = set()
    for word in set(words):
        if len(word) > cells:
            continue
        target = list(word)
        visited = [False] * cells

        def visit(position, index):
            if visited[position] or board[position] != target[index]:
                return False
            if index + 1 == len(target):
                return True
            visited[position] = True
            row, col = divmod(position, columns)
            for dr in (-1, 0, 1):
                for dc in (-1, 0, 1):
                    nr, nc = row + dr, col + dc
                    if (dr or dc) and 0 <= nr < rows and 0 <= nc < columns:
                        if visit(nr * columns + nc, index + 1):
                            visited[position] = False
                            return True
            visited[position] = False
            return False

        if any(visit(i, 0) for i in range(cells)):
            rows_found.add(word)
    output = b"".join(word + b"\0" for word in sorted(rows_found))
    return len(output), output
