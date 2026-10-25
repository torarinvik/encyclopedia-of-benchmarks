"""Independent truth-table remapping oracle for Ghostscript ROP3 transforms."""

MAX_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
INVALID_RESULT = -1
MODE_NAMES = (
    "rop3_invert_D", "rop3_invert_S", "rop3_invert_T",
    "rop3_know_D_0", "rop3_know_D_1", "rop3_know_S_0", "rop3_know_S_1",
    "rop3_know_T_0", "rop3_know_T_1", "rop3_swap_S_T",
    "rop3_use_D_when_S_0", "rop3_use_D_when_S_1",
    "rop3_use_D_when_T_0", "rop3_use_D_when_T_1", "rop3_not",
)


def expected_result(values):
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if len(values) > MAX_PARSEABLE_INPUT_LENGTH or len(values) != MAX_INPUT_LENGTH:
        return INVALID_RESULT
    mode, code = values
    if type(mode) is not int or not 0 <= mode < len(MODE_NAMES):
        return INVALID_RESULT
    if type(code) is not int or not 0 <= code <= 255:
        return INVALID_RESULT
    result = 0
    for index in range(8):
        d, s, t = index & 1, (index >> 1) & 1, (index >> 2) & 1
        source_index = index
        forced = None
        if mode == 0:
            source_index ^= 1
        elif mode == 1:
            source_index ^= 2
        elif mode == 2:
            source_index ^= 4
        elif 3 <= mode <= 8:
            dimension = (mode - 3) // 2
            pinned_value = (mode - 3) & 1
            source_index = (index & ~(1 << dimension)) | (pinned_value << dimension)
        elif mode == 9:
            source_index = (index & ~6) | ((s << 2) | (t << 1))
        elif 10 <= mode <= 13:
            dimension = 1 if mode < 12 else 2
            required = (mode - 10) & 1
            selected = s if dimension == 1 else t
            if selected == required:
                forced = d
        elif mode == 14:
            forced = 1 - ((code >> index) & 1)
        value = forced if forced is not None else ((code >> source_index) & 1)
        result |= value << index
    return result
