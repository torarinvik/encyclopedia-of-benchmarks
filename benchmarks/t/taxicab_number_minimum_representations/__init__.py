"""Taxicab minimum-representation benchmark references."""

from .independent_oracle import taxicab_number_minimum_representations_independent
from .primary_oracle import taxicab_number_minimum_representations

__all__ = [
    "taxicab_number_minimum_representations",
    "taxicab_number_minimum_representations_independent",
]
