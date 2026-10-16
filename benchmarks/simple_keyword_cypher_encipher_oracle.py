"""Oracle for the pinned Python simple keyword cipher encipher operation."""
from simple_keyword_cypher_oracle_common import expected_output as _expected_output

def expected_output(values, capacity=None):
    return _expected_output(values, decipher=False, capacity=capacity)
