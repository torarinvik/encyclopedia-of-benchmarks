"""Unexecuted closed-form full-range corpus for the future benchmark suite."""
from math import factorial
from itertools import permutations

P = 998244353


def encode(values):
    return b"".join(value.to_bytes(4, "little") for value in values)


def permutation_rank(permutation):
    available = list(range(len(permutation)))
    result = 0
    for position, image in enumerate(permutation):
        digit = available.index(image)
        result += digit * factorial(len(permutation)-position-1)
        available.pop(digit)
    return result


def cases(degrees=None, include_extra=True):
    """Yield name, packed input, expected count, and expected bytes.

    These identities use no FFT reference and cover the entire proposed degree
    range. Materializing the degree-nine cases needs multi-megabyte buffers.
    When degrees is provided, skip other degrees before allocating their data.
    """
    for n in (1, 2, 3, 4, 5, 6, 7, 8, 9):
        if degrees is not None and n not in degrees:
            continue
        count = factorial(n)
        identity = [1] + [0] * (count-1)
        values = [(73*i+19) % P for i in range(count)]
        payload = encode(values)
        yield f"left_identity_{n}", [n, *identity, *values], 4*count, payload
        yield f"right_identity_{n}", [n, *values, *identity], 4*count, payload
        all_ones = [1] * count
        yield f"constant_convolution_{n}", [n, *all_ones, *all_ones], 4*count, encode([count % P]*count)
        if n >= 2:
            # The sign character is multiplicative: sign(q)sign(r)=sign(q∘r).
            # Pair it with a dense nonconstant function, so both operands have
            # full support and the reference does not use a Fourier transform.
            signs = []
            for permutation in permutations(range(n)):
                inversions = sum(permutation[i] > permutation[j]
                                 for i in range(n) for j in range(i+1, n))
                signs.append(1 if inversions % 2 == 0 else P-1)
            signed_sum = sum(sign * value for sign, value in zip(signs, values)) % P
            sign_payload = encode([(sign*signed_sum) % P for sign in signs])
            yield f"sign_character_left_{n}", [n, *signs, *values], 4*count, sign_payload
            yield f"sign_character_right_{n}", [n, *values, *signs], 4*count, sign_payload
            even_indicator = [1 if sign == 1 else 0 for sign in signs]
            even_sum = sum(value for sign, value in zip(signs, values) if sign == 1) % P
            odd_sum = (sum(values)-even_sum) % P
            parity_payload = encode([even_sum if sign == 1 else odd_sum for sign in signs])
            yield f"even_subgroup_left_{n}", [n, *even_indicator, *values], 4*count, parity_payload
            # Two full-support functions probe noncommuting composition. For
            # a(q)=q[i]+1 and b(r)=r[j]+1, fix t=p[j]. If q[i]=t then
            # q^-1(t)=i; otherwise each distinct pair of image constraints
            # has (n-2)! completions. This gives the output without an FFT.
            order = list(permutations(range(n)))
            first_image = [p[0]+1 for p in order]
            second_image = [p[1]+1 for p in order]
            total_images = n*(n+1)//2
            def coordinate_output(left_index, right_index):
                remaining_positions = total_images-(left_index+1)
                return encode([
                    (factorial(n-1)*(p[right_index]+1)*(left_index+1)
                     + factorial(n-2)*(total_images-(p[right_index]+1))*remaining_positions) % P
                    for p in order
                ])
            yield f"coordinate_left_first_{n}", [n, *first_image, *second_image], 4*count, coordinate_output(0, 1)
            yield f"coordinate_right_first_{n}", [n, *second_image, *first_image], 4*count, coordinate_output(1, 0)
        if n >= 3:
            # Multiplication by 2e + 3s is a weighted sum of the original
            # function and a left or right translation by the swap s=(0 1).
            # Since s is its own inverse, translate each output permutation
            # directly; no subgroup transform or pair accumulation is needed.
            sparse = [0] * count
            sparse[0], sparse[factorial(n-1)] = 2, 3
            swap = [1, 0, *range(2, n)]
            left_output, right_output = [], []
            for rank, p in enumerate(permutations(range(n))):
                left_translation = tuple(swap[p[i]] for i in range(n))
                right_translation = tuple(p[swap[i]] for i in range(n))
                left_output.append((2*values[rank] + 3*values[permutation_rank(left_translation)]) % P)
                right_output.append((2*values[rank] + 3*values[permutation_rank(right_translation)]) % P)
            yield f"two_support_left_{n}", [n, *sparse, *values], 4*count, encode(left_output)
            yield f"two_support_right_{n}", [n, *values, *sparse], 4*count, encode(right_output)
            if n <= 5:
                # Exercise the reference's three-entry support boundary using
                # both adjacent transpositions and both multiplication orders.
                second_swap = [0, 2, 1, *range(3, n)]
                sparse[factorial(n-2)] = 5
                left_output, right_output = [], []
                for rank, p in enumerate(permutations(range(n))):
                    left_translation = tuple(second_swap[p[i]] for i in range(n))
                    right_translation = tuple(p[second_swap[i]] for i in range(n))
                    left_output.append((2*values[rank]
                        + 3*values[permutation_rank(tuple(swap[p[i]] for i in range(n)))]
                        + 5*values[permutation_rank(left_translation)]) % P)
                    right_output.append((2*values[rank]
                        + 3*values[permutation_rank(tuple(p[swap[i]] for i in range(n)))]
                        + 5*values[permutation_rank(right_translation)]) % P)
                yield f"three_support_left_{n}", [n, *sparse, *values], 4*count, encode(left_output)
                yield f"three_support_right_{n}", [n, *values, *sparse], 4*count, encode(right_output)
            # Lexicographic ranks for swaps (0,1), (1,2), and their two
            # distinct products. This probes composition order at full size.
            left_rank = factorial(n-1)
            right_rank = factorial(n-2)
            left_first = left_rank + right_rank
            right_first = 2*left_rank
            left = [0] * count
            right = [0] * count
            left[left_rank] = 1
            right[right_rank] = 1
            expected = [0] * count
            expected[left_first] = 1
            yield f"noncommuting_left_first_{n}", [n, *left, *right], 4*count, encode(expected)
            expected[left_first] = 0
            expected[right_first] = 1
            yield f"noncommuting_right_first_{n}", [n, *right, *left], 4*count, encode(expected)
    # Preserve the largest parseable extra-word case without executing a transform.
    if include_extra:
        count = factorial(9)
        yield "maximum_frame_extra_word", [9, *([0]*(2*count)), 0], -1, b""
