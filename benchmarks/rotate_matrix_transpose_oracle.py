"""Oracle for pinned Python matrix operation transpose."""
from rotate_matrix_oracle_common import expected_output as _expected_output

def expected_output(values, capacity=None):
    return _expected_output(values, 'transpose', capacity)
