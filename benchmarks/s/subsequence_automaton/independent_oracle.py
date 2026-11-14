"""Independent linear-scan reference for the subsequence query profile."""
from .primary_oracle import parse


def expected(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    text, queries = parsed
    result = 0
    for index, query in enumerate(queries, 1):
        cursor = 0
        for symbol in text:
            if cursor < len(query) and query[cursor] == symbol:
                cursor += 1
        if cursor == len(query):
            result += index
    return result
