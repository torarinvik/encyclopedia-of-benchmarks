"""Runtime oracle for bounded multi-step Nesterov parameter updates."""
import struct

MAX_INPUT_LENGTH = 76
MAX_OUTPUT_BYTES = 64


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 4
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    width, steps, lr_milli, momentum_milli = values[:4]
    if (not 1 <= width <= 8 or not 1 <= steps <= 8
            or not 0 <= lr_milli <= 1000 or not 0 <= momentum_milli <= 1000
            or len(values) != 4 + width * (steps + 1)):
        return -1, b""
    data = values[4:]
    if any(not -10000 <= x <= 10000 for x in data):
        return -1, b""
    scale = 1000.0
    params = [x / scale for x in data[:width]]
    gradients = data[width:]
    learning_rate = lr_milli / scale
    momentum = momentum_milli / scale
    velocity = [0.0] * width
    for step in range(steps):
        previous = velocity.copy()
        grad = gradients[step * width:(step + 1) * width]
        velocity = [momentum * velocity[i] - learning_rate * (grad[i] / scale)
                    for i in range(width)]
        params = [params[i] - momentum * previous[i] + (1.0 + momentum) * velocity[i]
                  for i in range(width)]
    payload = struct.pack("<" + "d" * width, *params)
    return len(payload), payload
