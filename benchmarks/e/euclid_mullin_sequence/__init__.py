"""Clean-room bounded Euclid–Mullin sequence benchmark references."""

from .independent_oracle import expected_result as independent_expected_result
from .primary_oracle import expected_result

__all__ = ["expected_result", "independent_expected_result"]
