"""Bounded oracle for the source-compatible simple blockchain benchmark."""

from __future__ import annotations

import hashlib

MIN_DIFFICULTY = 1
MAX_DIFFICULTY = 2
MIN_CHAIN_LEN = 1
MAX_CHAIN_LEN = 8
MAX_DATA_LEN = 64
MAX_TIMESTAMP = (1 << 31) - 1
NONCE_ATTEMPTS = 4096
MIN_DATA_BYTE = 0
MAX_DATA_BYTE = 127
MAX_OUTPUT_BYTES = 24 + 88 * MAX_CHAIN_LEN
MAX_INPUT_VALUES = 3 + (MAX_CHAIN_LEN - 1) * (2 + MAX_DATA_LEN)
MAX_INPUT_BYTES = MAX_INPUT_VALUES * 8
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _pack_i64(value: int) -> bytes:
    return int(value).to_bytes(8, "little", signed=True)


def _header(index: int, timestamp_sec: int, data: bytes, previous_hash: str, nonce: int) -> bytes:
    # The bounded timestamp domain is exactly representable as binary64 and its
    # Python float string spelling is always the decimal integer followed by .0.
    return (
        f"{index}{timestamp_sec}.0".encode("ascii")
        + data
        + previous_hash.encode("ascii")
        + str(nonce).encode("ascii")
    )


def _valid_chain(blocks: list[dict[str, object]], difficulty: int) -> bool:
    target = "0" * difficulty
    for index in range(1, len(blocks)):
        current = blocks[index]
        previous = blocks[index - 1]
        if current["previous_hash"] != previous["hash"]:
            return False
        digest = str(current["hash"])
        if not digest.startswith(target):
            return False
        recomputed = hashlib.sha256(
            _header(
                index,
                int(current["timestamp_sec"]),
                bytes(current["data"]),
                str(current["previous_hash"]),
                int(current["nonce"]),
            )
        ).hexdigest()
        if digest != recomputed:
            return False
    return True


def expected_result(values: list[int] | tuple[int, ...], output_capacity: int = MAX_OUTPUT_BYTES) -> tuple[int, bytes]:
    """Return `(written_bytes_or_error, output_bytes)` for the packed ABI."""
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_VALUES:
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    difficulty, chain_len, genesis_timestamp = values[:3]
    if not MIN_DIFFICULTY <= difficulty <= MAX_DIFFICULTY or not MIN_CHAIN_LEN <= chain_len <= MAX_CHAIN_LEN:
        return -1, b""
    if not 0 <= genesis_timestamp <= MAX_TIMESTAMP:
        return -1, b""

    timestamps = [genesis_timestamp]
    data_items = [b"Genesis Block"]
    cursor = 3
    for _ in range(1, chain_len):
        if cursor + 2 > len(values):
            return -1, b""
        timestamp_sec = values[cursor]
        data_len = values[cursor + 1]
        cursor += 2
        if not 0 <= timestamp_sec <= MAX_TIMESTAMP or not 0 <= data_len <= MAX_DATA_LEN:
            return -1, b""
        if cursor + data_len > len(values):
            return -1, b""
        data_values = values[cursor : cursor + data_len]
        if any(not MIN_DATA_BYTE <= value <= MAX_DATA_BYTE for value in data_values):
            return -1, b""
        timestamps.append(timestamp_sec)
        data_items.append(bytes(data_values))
        cursor += data_len
    if cursor != len(values):
        return -1, b""

    blocks: list[dict[str, object]] = []
    previous_hash = "0"
    target = "0" * difficulty
    for index, (timestamp_sec, data) in enumerate(zip(timestamps, data_items)):
        for nonce in range(NONCE_ATTEMPTS):
            digest = hashlib.sha256(_header(index, timestamp_sec, data, previous_hash, nonce)).hexdigest()
            if digest.startswith(target):
                blocks.append(
                    {
                        "index": index,
                        "timestamp_sec": timestamp_sec,
                        "data": data,
                        "previous_hash": previous_hash,
                        "nonce": nonce,
                        "hash": digest,
                    }
                )
                previous_hash = digest
                break
        else:
            return -3, b""

    valid = int(_valid_chain(blocks, difficulty))
    payload = bytearray()
    payload.extend(_pack_i64(0))
    payload.extend(_pack_i64(chain_len))
    for block in blocks:
        payload.extend(_pack_i64(int(block["index"])))
        payload.extend(_pack_i64(int(block["timestamp_sec"])))
        payload.extend(_pack_i64(int(block["nonce"])))
        payload.extend(str(block["hash"]).encode("ascii"))
    payload.extend(_pack_i64(valid))

    if type(output_capacity) is not int or output_capacity < len(payload):
        return -2, b""
    return len(payload), bytes(payload)
