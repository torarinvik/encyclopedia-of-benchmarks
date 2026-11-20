"""Wieferich-prime count benchmark references."""

from .independent_oracle import wieferich_prime_count_up_to_limit_independent
from .primary_oracle import wieferich_prime_count_up_to_limit

__all__ = [
    "wieferich_prime_count_up_to_limit",
    "wieferich_prime_count_up_to_limit_independent",
]
