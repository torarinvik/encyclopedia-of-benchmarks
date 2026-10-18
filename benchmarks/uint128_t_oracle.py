"""Oracle adapter for the pinned C++ 128-bit unsigned division/remainder methods."""

from uint_fixed_width_oracle import expected_output as _expected_output


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    return _expected_output(128, values, output_capacity, output_is_null,
                            input_is_null, input_length)
