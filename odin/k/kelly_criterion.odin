package kelly_criterion
import "core:c"

SCALE::i64=1_000_000
MIN_PROBABILITY_MICRO::i64=1
MAX_PROBABILITY_MICRO::i64=999_999
MIN_RATIO_MICRO::i64=1_000
MAX_RATIO_MICRO::i64=100_000_000
MAX_INPUT_LENGTH::c.size_t=3
INVALID_RESULT::f64=-1e300

@(export)
kelly_criterion::proc "c" (values:[^]i64,length:c.size_t)->f64 {
    if values==nil||length!=2||length>MAX_INPUT_LENGTH do return INVALID_RESULT
    probability_micro,ratio_micro:=values[0],values[1]
    if probability_micro<MIN_PROBABILITY_MICRO||probability_micro>MAX_PROBABILITY_MICRO||ratio_micro<MIN_RATIO_MICRO||ratio_micro>MAX_RATIO_MICRO do return INVALID_RESULT
    win_probability:=f64(probability_micro)/f64(SCALE)
    win_loss_ratio:=f64(ratio_micro)/f64(SCALE)
    loss_probability:=1.0-win_probability
    return (win_probability*win_loss_ratio-loss_probability)/win_loss_ratio
}
