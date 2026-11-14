"""High-precision reference for the bounded five-body workload.

The profile's initial binary64 constants are shared with the primary reference;
the integration and energy calculations below use decimal arithmetic.
"""

from decimal import Decimal, localcontext
import struct

from b.benchmarkgame_nbody_oracle import INITIAL_BODIES


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not 0 <= values[0] <= 1000):
        return -1, b""
    with localcontext() as context:
        context.prec = 40
        bodies = [[Decimal.from_float(value) for value in body] for body in INITIAL_BODIES]
        step_size = Decimal.from_float(0.01)

        for axis in range(3):
            momentum = sum((body[3 + axis] * body[6] for body in bodies), Decimal(0))
            bodies[0][3 + axis] = -momentum / bodies[0][6]

        def energy():
            total = Decimal(0)
            for i, body in enumerate(bodies):
                total += body[6] * sum((component * component for component in body[3:6]), Decimal(0)) / 2
                for other in bodies[i + 1:]:
                    squared_distance = sum(((body[axis] - other[axis]) ** 2 for axis in range(3)), Decimal(0))
                    total -= body[6] * other[6] / squared_distance.sqrt()
            return total

        initial = energy()
        for _ in range(values[0]):
            for i, body in enumerate(bodies):
                for other in bodies[i + 1:]:
                    separation = [body[axis] - other[axis] for axis in range(3)]
                    squared_distance = sum((component * component for component in separation), Decimal(0))
                    factor = step_size / (squared_distance * squared_distance.sqrt())
                    for axis in range(3):
                        body[axis + 3] -= separation[axis] * other[6] * factor
                        other[axis + 3] += separation[axis] * body[6] * factor
            for body in bodies:
                for axis in range(3):
                    body[axis] += step_size * body[axis + 3]
        return 16, struct.pack("<2d", float(initial), float(energy()))
