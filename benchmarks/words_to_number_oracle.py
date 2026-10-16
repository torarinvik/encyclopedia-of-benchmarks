"""Bounded source-compatible oracle for Java WordsToNumber.convert."""
from __future__ import annotations

MAX_INPUT = 128
MAX_OUTPUT_BYTES = 64
MAX_FRACTIONAL_WORDS = 3
MAX_OUTPUT_BYTES = 64
ERROR_NULL_INPUT = -3
ERROR_UNKNOWN_WORD = -4
ERROR_UNEXPECTED_WORD = -5
ERROR_AFTER_POINT = -6
ERROR_MISSING_DECIMAL = -7
ERROR_MULTIPLE_NEGATIVES = -8
ERROR_INVALID_NEGATIVE = -9
ERROR_INVALID_CONJUNCTION = -10

NUMBERS = {"zero":0,"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,
           "ten":10,"eleven":11,"twelve":12,"thirteen":13,"fourteen":14,"fifteen":15,"sixteen":16,"seventeen":17,"eighteen":18,"nineteen":19,
           "twenty":20,"thirty":30,"forty":40,"fifty":50,"sixty":60,"seventy":70,"eighty":80,"ninety":90}
SCALES = {"thousand":1000,"million":1000000,"billion":1000000000,"trillion":1000000000000}

class SourceError(Exception):
    def __init__(self, code: int): self.code=code

def _format_bigdecimal(whole: int, fraction: str | None, negative: bool) -> str:
    if fraction is None:
        digits=str(whole)
        zero=whole==0
        return ("-" if negative and not zero else "")+digits
    zero=whole==0 and all(ch=="0" for ch in fraction)
    text=(str(whole) if whole else "0")+"."+fraction
    return ("-" if negative and not zero else "")+text

def _parse(text: str) -> str:
    # Java preprocesses by trimming, splitting on any space/comma/hyphen, and lowercasing.
    tokens=[token.lower() for token in text.strip().replace(","," ").replace("-"," ").split(" ") if token]
    if not tokens: raise SourceError(ERROR_NULL_INPUT)
    negative=tokens[0]=="negative"
    if negative: tokens=tokens[1:]
    chunks=[]; current=0; prev_hundred=False; prev_scale=False; fraction=None
    i=0
    while i<len(tokens):
        word=tokens[i]
        if word=="and":
            if i+1>=len(tokens): raise SourceError(ERROR_INVALID_CONJUNCTION)
            next_word=tokens[i+1]
            number=NUMBERS.get(next_word)
            after=tokens[i+2] if i+2<len(tokens) else None
            if not (prev_hundred or prev_scale) or number is None or not (number>=10 or after is None or after=="point"):
                raise SourceError(ERROR_INVALID_CONJUNCTION)
            i+=1;continue
        if word=="hundred":
            if current>=10 or prev_scale: raise SourceError(ERROR_UNEXPECTED_WORD)
            if current==0: current=1
            current*=100;prev_hundred=True;i+=1;continue
        prev_hundred=False
        if word in SCALES:
            if current==0 or prev_scale: raise SourceError(ERROR_UNEXPECTED_WORD)
            next_chunk=current*SCALES[word]
            if chunks and not (len(str(chunks[-1]))>len(str(next_chunk))): raise SourceError(ERROR_UNEXPECTED_WORD)
            chunks.append(next_chunk);current=0;prev_scale=True;i+=1;continue
        prev_scale=False
        if word in NUMBERS:
            number=NUMBERS[word]
            if number==0 and not (current==0 and not chunks): raise SourceError(ERROR_UNEXPECTED_WORD)
            if current!=0 and not (len(str(current))>len(str(number))): raise SourceError(ERROR_UNEXPECTED_WORD)
            current+=number;i+=1;continue
        if word=="point":
            if current!=0: chunks.append(current)
            remainder=tokens[i+1:]
            if not remainder: raise SourceError(ERROR_MISSING_DECIMAL)
            if any(token not in NUMBERS for token in remainder): raise SourceError(ERROR_AFTER_POINT)
            if len(remainder)>MAX_FRACTIONAL_WORDS: raise SourceError(-1)
            fraction="".join(str(NUMBERS[token]) for token in remainder)
            current=0
            i=len(tokens);break
        if word=="negative": raise SourceError(ERROR_MULTIPLE_NEGATIVES if negative else ERROR_INVALID_NEGATIVE)
        raise SourceError(ERROR_UNKNOWN_WORD)
    if current!=0: chunks.append(current)
    total=sum(chunks)
    return _format_bigdecimal(total,fraction,negative)

def expected_result(values: list[int] | tuple[int, ...], output_capacity: int = MAX_OUTPUT_BYTES) -> tuple[int, bytes]:
    if (not isinstance(values,(list,tuple)) or len(values)<1 or len(values)>MAX_INPUT+1
            or any(type(value) is not int or not 0<=value<=255 for value in values)):
        return -1,b""
    length=values[0]
    if not 0<=length<=MAX_INPUT or len(values)!=length+1 or any(value<32 or value>126 for value in values[1:]):
        return -1,b""
    try:
        result=_parse(bytes(values[1:]).decode("ascii"))
    except SourceError as error:
        return error.code,b""
    output=result.encode("ascii")
    if output_capacity<len(output): return -2,b""
    return len(output),output
