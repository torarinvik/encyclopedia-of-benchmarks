"""Independent result oracle for the bounded BM25 inverted-index contract."""

from __future__ import annotations

from fractions import Fraction

MAX_DOCUMENTS = 32
MAX_TERMS_PER_DOCUMENT = 64
MAX_INPUT_LENGTH = 2114
MAX_OUTPUT_LENGTH = MAX_DOCUMENTS


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -2, b""
    document_count = values[0]
    if not 0 <= document_count <= MAX_DOCUMENTS:
        return -2, b""
    offset = 1
    documents: list[tuple[int, list[int]]] = []
    seen_ids: set[int] = set()
    for _ in range(document_count):
        if offset + 2 > len(values) - 1:
            return -2, b""
        document_id, term_count = values[offset:offset + 2]
        offset += 2
        if (not 0 <= document_id <= 255 or document_id in seen_ids
                or not 0 <= term_count <= MAX_TERMS_PER_DOCUMENT
                or offset + term_count > len(values) - 1):
            return -2, b""
        terms = values[offset:offset + term_count]
        if any(not 1 <= term <= 255 for term in terms):
            return -2, b""
        seen_ids.add(document_id)
        documents.append((document_id, terms))
        offset += term_count
    if offset != len(values) - 1 or not 1 <= values[-1] <= 255:
        return -2, b""

    query_term = values[-1]
    document_frequency = sum(query_term in terms for _, terms in documents)
    if document_frequency == 0:
        return 0, b""
    total_terms = sum(len(terms) for _, terms in documents)
    if total_terms == 0:
        return 0, b""
    scored: list[tuple[Fraction, int]] = []
    for document_id, terms in documents:
        frequency = terms.count(query_term)
        if not frequency:
            continue
        length = len(terms)
        # IDF is one positive multiplier shared by every result for this query.
        denominator = 8 * total_terms * frequency + 3 * total_terms + 9 * len(documents) * length
        score = Fraction(frequency, denominator)
        scored.append((score, document_id))
    scored.sort(key=lambda item: (-item[0], item[1]))
    output = bytes(document_id for _, document_id in scored)
    return len(output), output
