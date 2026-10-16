"""Contract oracle for the pinned Python email-address validator."""

from __future__ import annotations

MAX_LOCAL_PART_LENGTH = 64
MAX_DOMAIN_LENGTH = 255
MAX_SOURCE_LENGTH = MAX_LOCAL_PART_LENGTH + 1 + MAX_DOMAIN_LENGTH
MAX_INPUT_LENGTH = 100002

LOCAL_ALLOWED = frozenset(
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    ".(!#$%&'*+-/=?^_`{|}~)"
)
DOMAIN_ALLOWED = frozenset(
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-"
)


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the source boolean for an ASCII-code-point sequence.

    Preserve two quirks in the pinned source: `@` is accepted with both parts
    empty, and a domain ending in a hyphen is accepted by its suffix typo.
    """
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1
    if len(values) > MAX_SOURCE_LENGTH:
        return 0
    if any(value < 0 or value > 0x10FFFF for value in values):
        return -1
    if any(value > 127 for value in values):
        return 0
    text = "".join(chr(value) for value in values)
    if text.count("@") != 1:
        return 0
    local, domain = text.split("@")
    if len(local) > MAX_LOCAL_PART_LENGTH or len(domain) > MAX_DOMAIN_LENGTH:
        return 0
    if any(char not in LOCAL_ALLOWED for char in local):
        return 0
    if local.startswith(".") or local.endswith(".") or ".." in local:
        return 0
    if any(char not in DOMAIN_ALLOWED for char in domain):
        return 0
    if domain.startswith("-") or domain.endswith("."):
        return 0
    return int(not (domain.startswith(".") or domain.endswith(".") or ".." in domain))
