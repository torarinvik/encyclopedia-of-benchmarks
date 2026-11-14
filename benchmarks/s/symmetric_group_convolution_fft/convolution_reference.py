"""Unexecuted research composition of the drafted group transforms.

Not a production implementation: the transform convention and asymptotic
workspace bounds have not been verified, and no benchmark ABI is supplied.
"""
from .forward_reference import P, forward, plan
from .inverse_reference import inverse


def convolve(n, a, b):
    left = forward(n, a)
    right = forward(n, b)
    products = {}
    if n == 1:
        return [left[(1,)][0] * right[(1,)][0] % P]
    for shape, (dimension, _, _) in plan(n).items():
        x, y = left[shape], right[shape]
        product = [0] * (dimension*dimension)
        for row in range(dimension):
            for inner in range(dimension):
                coefficient = x[row*dimension+inner]
                for col in range(dimension):
                    slot = row*dimension+col
                    product[slot] = (product[slot]+coefficient*y[inner*dimension+col]) % P
        products[shape] = product
    return inverse(n, products)
