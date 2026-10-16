"""Independent oracle for the pinned C# inverted-index contract."""

from __future__ import annotations

MAX_DOCS = 256
MAX_WORDS_PER_DOC = 256
MAX_TOTAL_WORDS = 4096
MAX_QUERY_TERMS = 16
MAX_ID = 65535
MAX_INPUT_LENGTH = 4627
FNV_OFFSET = 14695981039346656037
FNV_PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1


def _fnv_i64_record(values: list[int]) -> int:
    digest = FNV_OFFSET
    for value in values:
        bits = value & MASK64
        for shift in range(0, 64, 8):
            digest = ((digest ^ ((bits >> shift) & 0xFF)) * FNV_PRIME) & MASK64
    return digest & MASK63


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the sorted document-set hash or -1 for an invalid packed input."""
    if (
        not isinstance(values, (list, tuple))
        or not 3 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return -1

    doc_count = values[0]
    if not 0 <= doc_count <= MAX_DOCS:
        return -1
    cursor = 1
    documents: dict[int, set[int]] = {}
    total_words = 0
    for _ in range(doc_count):
        if cursor + 2 > len(values):
            return -1
        doc_id, word_count = values[cursor : cursor + 2]
        cursor += 2
        if not 0 <= doc_id < MAX_DOCS or doc_id in documents:
            return -1
        if not 1 <= word_count <= MAX_WORDS_PER_DOC:
            return -1
        total_words += word_count
        if total_words > MAX_TOTAL_WORDS or cursor + word_count > len(values):
            return -1
        words = values[cursor : cursor + word_count]
        if any(not 0 <= word_id <= MAX_ID for word_id in words):
            return -1
        # C# Split(' ').Distinct() keeps one exact, case-sensitive token per document.
        documents[doc_id] = set(words)
        cursor += word_count

    if cursor + 2 > len(values):
        return -1
    operation, term_count = values[cursor : cursor + 2]
    cursor += 2
    if operation not in (0, 1) or not 1 <= term_count <= MAX_QUERY_TERMS:
        return -1
    if cursor + term_count != len(values):
        return -1
    terms = values[cursor:]
    if any(not 0 <= term_id <= MAX_ID for term_id in terms):
        return -1

    if operation == 0:
        matching = [doc_id for doc_id, words in documents.items() if all(term in words for term in terms)]
    else:
        matching = [doc_id for doc_id, words in documents.items() if any(term in words for term in terms)]
    matching.sort()
    return _fnv_i64_record([len(matching), *matching])
