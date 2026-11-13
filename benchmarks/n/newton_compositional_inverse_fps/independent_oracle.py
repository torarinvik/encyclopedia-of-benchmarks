"""Reference the existing package's independently structured Lagrange oracle.

The two benchmark profiles intentionally have the same input and output
contract; sharing this reference keeps the mathematical result consistent
without sharing either profile's numerical method.
"""

from c.compositional_inverse_of_formal_power_series.independent_oracle import expected_output
