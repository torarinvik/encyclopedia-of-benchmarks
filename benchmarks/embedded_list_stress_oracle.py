"""Oracle for a bounded, source-derived embedded list-processing kernel."""
from __future__ import annotations
import struct
from typing import Sequence

MAX_ITEMS = 32
MAX_PARSEABLE_INPUT_LENGTH = 4
MAX_OUTPUT_BYTES = 2
INVALID_RESULT = -1
OUTPUT_ERROR = -2

def _crc_byte(value: int, crc: int) -> int:
    for _ in range(8):
        mix = (value & 1) ^ (crc & 1)
        value >>= 1
        if mix: crc ^= 0x4002
        crc >>= 1
        if mix: crc |= 0x8000
        else: crc &= 0x7FFF
    return crc

def _crc16(value: int, crc: int) -> int:
    return _crc_byte((value >> 8) & 255, _crc_byte(value & 255, crc))

def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if (input_is_null or values is None or not isinstance(values, (tuple, list))
            or len(values) != 4 or (input_length is not None and input_length != len(values))
            or any(type(v) is not int or not -(2**63) <= v < 2**63 for v in values)):
        return INVALID_RESULT, b""
    n, seed, find_count, finder_idx = values
    if not 4 <= n <= MAX_ITEMS or not 1 <= seed <= 255 or not 0 <= find_count <= 32 or finder_idx not in (-1, 1):
        return INVALID_RESULT, b""
    # Nodes are [data16, idx, next-index]; both sentinels are regular list nodes.
    tail = n + 1
    nodes = [[0, 0, -1] for _ in range(n + 2)]
    nodes[0] = [0x8080, 0, 1]
    nodes[tail] = [0xFFFF, 0x7FFF, -1]
    for i in range(n):
        dat = ((((seed ^ i) & 15) << 3) | (i & 7))
        nodes[i + 1] = [((dat << 8) | dat) & 0xFFFF, 0, i + 2]
    nodes[n][2] = tail
    idx = 1
    p = nodes[0][2]
    while p != tail:
        if idx < n // 5:
            nodes[p][1] = idx
            idx += 1
        else:
            pat = idx ^ seed
            idx += 1
            nodes[p][1] = (((idx & 7) << 8) | pat) & 0x3FFF
        p = nodes[p][2]

    def compare(a: int, b: int, complex_cmp: bool) -> int:
        if complex_cmp:
            for node in (nodes[a], nodes[b]):
                if not node[0] & 0x80:
                    node[0] = (node[0] & 0xFF00) | 0x80 | ((node[0] ^ (node[0] >> 8) ^ seed) & 0x7F)
            return (nodes[a][0] & 127) - (nodes[b][0] & 127)
        for node in (nodes[a], nodes[b]):
            node[0] = (node[0] & 0xFF00) | ((node[0] >> 8) & 255)
        return nodes[a][1] - nodes[b][1]

    def sort(head: int, complex_cmp: bool) -> int:
        width = 1
        while True:
            p = head; new_head = -1; tail_out = -1; merges = 0
            while p >= 0:
                merges += 1
                q = p; psize = 0
                for _ in range(width):
                    psize += 1; q = nodes[q][2]
                    if q < 0: break
                qsize = width
                while psize > 0 or (qsize > 0 and q >= 0):
                    if psize == 0: e=q; q=nodes[q][2]; qsize-=1
                    elif qsize == 0 or q < 0: e=p; p=nodes[p][2]; psize-=1
                    elif compare(p,q,complex_cmp) <= 0: e=p; p=nodes[p][2]; psize-=1
                    else: e=q; q=nodes[q][2]; qsize-=1
                    if tail_out >= 0: nodes[tail_out][2]=e
                    else: new_head=e
                    tail_out=e
                p=q
            nodes[tail_out][2]=-1; head=new_head
            if merges <= 1: return head
            width *= 2

    def find(head: int, target_idx: int, target_data: int) -> int:
        p=head
        while p >= 0:
            if (nodes[p][1] == target_idx if target_idx >= 0 else (nodes[p][0] & 255) == target_data): return p
            p=nodes[p][2]
        return -1

    def reverse(head: int) -> int:
        prev=-1; cur=head
        while cur >= 0:
            nxt=nodes[cur][2]; nodes[cur][2]=prev; prev=cur; cur=nxt
        return prev

    head=sort(0,False)
    info_idx=finder_idx; info_data=0; result=0; found=missed=0
    for k in range(find_count):
        info_data=k & 255
        got=find(head,info_idx,info_data)
        head=reverse(head)
        if got < 0:
            missed+=1; first=nodes[head][2]
            if first>=0: result=(result+((nodes[first][0]>>8)&1))&0xFFFF
        else:
            found+=1
            if nodes[got][0]&1: result=(result+((nodes[got][0]>>9)&1))&0xFFFF
            nxt=nodes[got][2]
            if nxt>=0:
                nodes[got][2]=nodes[nxt][2]; nodes[nxt][2]=nodes[head][2]; nodes[head][2]=nxt
        if info_idx>=0: info_idx+=1
    result=(result+found*4-missed)&0xFFFF
    if finder_idx>0: head=sort(head,True)
    at=nodes[head][2]
    if at>=0:
        removed=nodes[at][2]
        nodes[at][0],nodes[removed][0]=nodes[removed][0],nodes[at][0]
        nodes[at][1],nodes[removed][1]=nodes[removed][1],nodes[at][1]
        nodes[at][2]=nodes[removed][2]; nodes[removed][2]=-1
        f=find(head,info_idx,info_data)
        if f<0:f=nodes[head][2]
        while f>=0: result=_crc16(nodes[head][0],result);f=nodes[f][2]
        nodes[removed][0],nodes[at][0]=nodes[at][0],nodes[removed][0]
        nodes[removed][1],nodes[at][1]=nodes[at][1],nodes[removed][1]
        nodes[removed][2]=nodes[at][2];nodes[at][2]=removed
    head=sort(head,False)
    f=nodes[head][2]
    while f>=0: result=_crc16(nodes[head][0],result);f=nodes[f][2]
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR, b""
    return 2,struct.pack("<H",result)
