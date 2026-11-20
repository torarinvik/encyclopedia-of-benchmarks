//! Pratt binding-power parser for a bounded integer token grammar.
use std::slice;

const INVALID_RESULT: i64 = i64::MIN;
const MAX_TOKENS: usize = 15;

struct PrattParser<'a> {
    values: &'a [i64],
    count: usize,
    position: usize,
    invalid: bool,
}

impl PrattParser<'_> {
    fn expression(&mut self, minimum_binding_power: i64) -> i64 {
        if self.position >= self.count {
            self.invalid = true;
            return 0;
        }
        let offset = 1 + 2 * self.position;
        self.position += 1;
        let kind = self.values[offset];
        let mut left = match kind {
            1 => self.values[offset + 1],
            3 => -self.expression(25),
            5 => {
                let grouped = self.expression(0);
                if self.invalid || self.position >= self.count
                    || self.values[1 + 2 * self.position] != 6
                {
                    self.invalid = true;
                    return 0;
                }
                self.position += 1;
                grouped
            }
            _ => {
                self.invalid = true;
                return 0;
            }
        };
        if self.invalid { return 0; }

        while self.position < self.count {
            let operator = self.values[1 + 2 * self.position];
            let binding_power = match operator { 2 | 3 => 10, 4 => 20, _ => -1 };
            if binding_power < minimum_binding_power { break; }
            self.position += 1;
            let right = self.expression(binding_power + 1);
            if self.invalid { return 0; }
            match operator {
                2 => left += right,
                3 => left -= right,
                _ => left *= right,
            }
        }
        left
    }
}

#[no_mangle]
pub unsafe extern "C" fn pratt_expression_evaluation(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=32).contains(&length) { return INVALID_RESULT; }
    let values = slice::from_raw_parts(input, length);
    let count_value = values[0];
    if count_value < 1 || count_value > MAX_TOKENS as i64 { return INVALID_RESULT; }
    let count = count_value as usize;
    if length != 1 + 2 * count { return INVALID_RESULT; }
    for token in 0..count {
        let kind = values[1 + 2 * token];
        let payload = values[2 + 2 * token];
        if kind == 1 {
            if !(0..=9).contains(&payload) { return INVALID_RESULT; }
        } else if (2..=6).contains(&kind) {
            if payload != 0 { return INVALID_RESULT; }
        } else {
            return INVALID_RESULT;
        }
    }
    let mut parser = PrattParser { values, count, position: 0, invalid: false };
    let result = parser.expression(0);
    if parser.invalid || parser.position != count { return INVALID_RESULT; }
    result
}
