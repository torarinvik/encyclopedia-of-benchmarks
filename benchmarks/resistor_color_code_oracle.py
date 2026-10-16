"""Oracle for the pinned Python resistor-color-code formatting behavior."""

from __future__ import annotations

MAX_TEXT_LENGTH = 41
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 1
COLOR_NAMES = (
    "Black", "Brown", "Red", "Orange", "Yellow", "Green",
    "Blue", "Violet", "Grey", "White", "Gold", "Silver",
)
SIGNIFICANT = {name: value for value, name in enumerate(COLOR_NAMES[:10])}
MULTIPLIERS = {
    **{name: 10**value for value, name in enumerate(COLOR_NAMES[:10])},
    "Gold": 10**-1,
    "Silver": 10**-2,
}
TOLERANCES = {
    "Brown": 1, "Red": 2, "Orange": 0.05, "Yellow": 0.02,
    "Green": 0.5, "Blue": 0.25, "Violet": 0.1, "Grey": 0.01,
    "Gold": 5, "Silver": 10,
}
TEMPERATURES = {
    "Black": 250, "Brown": 100, "Red": 50, "Orange": 15,
    "Yellow": 25, "Green": 20, "Blue": 10, "Violet": 5, "Grey": 1,
}


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return -1, b""
    text_length = values[0]
    if not 1 <= text_length <= MAX_TEXT_LENGTH or len(values) != text_length + 1:
        return -1, b""
    if any(not 0 <= byte <= 127 for byte in values[1:]):
        return -1, b""
    try:
        colors = bytes(values[1:]).decode("ascii").split(",")
    except UnicodeDecodeError:
        return -1, b""
    band_count = len(colors)
    if not 3 <= band_count <= 6 or any(color not in COLOR_NAMES for color in colors):
        return -1, b""

    significant_count = 2 if band_count <= 4 else 3
    if any(color not in SIGNIFICANT for color in colors[:significant_count]):
        return -1, b""
    multiplier_color = colors[significant_count]
    if multiplier_color not in MULTIPLIERS:
        return -1, b""
    if band_count >= 4 and colors[significant_count + 1] not in TOLERANCES:
        return -1, b""
    if band_count == 6 and colors[5] not in TEMPERATURES:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""

    significant_digits = int("".join(str(SIGNIFICANT[color]) for color in colors[:significant_count]))
    resistance = significant_digits * MULTIPLIERS[multiplier_color]
    tolerance_color = colors[significant_count + 1] if band_count >= 4 else None
    tolerance = 20 if tolerance_color is None else TOLERANCES[tolerance_color]
    temperature_color = colors[5] if band_count == 6 else None
    temperature = 0 if temperature_color is None else TEMPERATURES[temperature_color]
    if temperature == 0:
        answer = f"{resistance}Ω ±{tolerance}% "
    else:
        answer = f"{resistance}Ω ±{tolerance}% {temperature} ppm/K"
    output = answer.encode("utf-8")
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
