"""References for the deterministic Cuckoo Filter operation trace."""

from .independent_oracle import expected_output as independent_expected_output
from .primary_oracle import expected_output as primary_expected_output

__all__ = ["primary_expected_output", "independent_expected_output"]
