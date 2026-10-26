"""Independent address-demand model of Prolangs-C simulator FORMAT3_4."""
from collections.abc import Sequence

MEM_SIZE = 1 << 20
WORD_LIMIT = 1 << 24
INVALID_RESULT = -1
MAX_INPUT_LENGTH = 7


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) != 7:
        return INVALID_RESULT
    if any(type(v) is not int for v in values):
        return INVALID_RESULT
    pc, x_reg, b_reg, b0, b1, b2, b3 = values
    if not (0 <= pc <= MEM_SIZE - 4 and 0 <= x_reg < WORD_LIMIT and 0 <= b_reg < WORD_LIMIT):
        return INVALID_RESULT
    if any(not 0 <= byte <= 255 for byte in (b0, b1, b2, b3)):
        return INVALID_RESULT
    n_flag, i_flag = (b0 >> 1) & 1, b0 & 1
    x_flag, b_flag, p_flag, e_flag = (b1 >> 7) & 1, (b1 >> 6) & 1, (b1 >> 5) & 1, (b1 >> 4) & 1
    sic = n_flag == 0 and i_flag == 0
    fmt = 4 if e_flag and not sic else 3
    next_pc = pc + fmt
    if fmt == 4:
        if b_flag or p_flag:
            return INVALID_RESULT
        address = ((b1 & 0x0F) << 16) | (b2 << 8) | b3
        if x_flag:
            address += x_reg
    else:
        address = ((b1 & 0x0F) << 8) | b2
        if sic:
            # The source computes this field but its later n/i dispatch has no
            # SIC-mode arm, so FORMAT3_4 reaches the final return(0).
            return 0
        if b_flag and p_flag:
            return INVALID_RESULT
        if x_flag:
            address += x_reg
        if b_flag:
            address += b_reg
        if p_flag:
            address = address - 4096 + next_pc if address >= 2048 else address + next_pc
    if n_flag == 1 and i_flag == 0:  # Indirect mode requires memory dereference.
        return INVALID_RESULT
    if address < 0:  # Negative effective addresses are outside this bounded profile.
        return INVALID_RESULT
    if n_flag == 0 and i_flag == 1 and address >= WORD_LIMIT:
        return INVALID_RESULT
    return address
