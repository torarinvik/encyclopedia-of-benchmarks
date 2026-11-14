"""Unexecuted algebraic checks for the research references and generators."""
from .independent_oracle import convolve as pair_convolution
from .target_oracle import convolve as target_convolution
from .reference_cases import CASES
from .seminormal_reference import P, generator_columns, tableaux
from .forward_reference import forward
from .inverse_reference import inverse
from .convolution_reference import convolve as transform_convolution
from .abi_reference import expected as abi_expected, structured as structured_convolution


def apply(columns, vector):
    out = [0] * len(vector)
    for column, coefficient in enumerate(vector):
        for row, entry in columns[column]:
            out[row] = (out[row] + coefficient*entry) % P
    return out


def apply_sequence(generators, sequence, vector):
    for index in sequence:
        vector = apply(generators[index], vector)
    return vector


def check_small_references():
    for n, a, b, expected in CASES:
        if pair_convolution(n, a, b) != expected or target_convolution(n, a, b) != expected:
            raise ValueError("symmetric-group reference case mismatch")
        if transform_convolution(n, a, b) != expected:
            raise ValueError("transform convolution differs from the small reference case")
        if structured_convolution(n, a, b) != expected:
            raise ValueError("structured convolution differs from the small reference case")


def check_abi_boundaries():
    if abi_expected([1, 7, 11], 4) != (4, bytes((77, 0, 0, 0))):
        raise ValueError("degree-one ABI encoding mismatch")
    if abi_expected([1, 7, 11], 3) != (-2, b""):
        raise ValueError("short output must be rejected")
    if abi_expected([1, 7, 11], 4, output_is_null=True) != (-2, b""):
        raise ValueError("null output must be rejected")
    if abi_expected([1, 7], 0, output_is_null=True) != (-1, b""):
        raise ValueError("invalid input must take precedence over output errors")
    if abi_expected([], 0, input_is_null=True) != (-1, b""):
        raise ValueError("null input must be rejected")


def check_forward_convolution():
    """Check proposed forward blocks against independent small convolutions."""
    for n, a, b, expected in CASES:
        left, right, actual = forward(n, a), forward(n, b), forward(n, expected)
        if left.keys() != right.keys() or left.keys() != actual.keys():
            raise ValueError("Fourier block shapes differ")
        for shape, basis in tableaux(n).items():
            dimension = len(basis)
            product = [0] * (dimension*dimension)
            for i in range(dimension):
                for j in range(dimension):
                    for k in range(dimension):
                        product[i*dimension+j] = (product[i*dimension+j]
                            + left[shape][i*dimension+k]*right[shape][k*dimension+j]) % P
            if product != actual[shape]:
                raise ValueError("Fourier block product has incorrect order or values")
        if inverse(n, left) != a or inverse(n, right) != b or inverse(n, actual) != expected:
            raise ValueError("Fourier inversion failed to recover reference values")


def check_generator_relations(n):
    """Check involution, braid, commutation and restriction block grouping."""
    if not 1 <= n <= 5:
        raise ValueError("dense research checks are restricted to degree five")
    groups = tableaux(n)
    for basis in groups.values():
        generators = [generator_columns(basis, i) for i in range(n-1)]
        last_cells = [tableau[-1] for tableau in basis]
        for cell in set(last_cells):
            indices = [i for i, item in enumerate(last_cells) if item == cell]
            if indices[-1] - indices[0] + 1 != len(indices):
                raise ValueError("restriction blocks are not contiguous")
        for column in range(len(basis)):
            unit = [0] * len(basis)
            unit[column] = 1
            for i in range(n-1):
                if apply_sequence(generators, (i, i), unit) != unit:
                    raise ValueError("generator does not square to identity")
                if i < n-2 and (apply_sequence(generators, (i, i+1, i), unit)
                                != apply_sequence(generators, (i+1, i, i+1), unit)):
                    raise ValueError("adjacent braid relation failed")
                for j in range(i+2, n-1):
                    if apply_sequence(generators, (i, j), unit) != apply_sequence(generators, (j, i), unit):
                        raise ValueError("distant generators do not commute")
                if i < n-2:
                    for row, _ in generators[i][column]:
                        if last_cells[row] != last_cells[column]:
                            raise ValueError("subgroup generator crosses a restriction block")
