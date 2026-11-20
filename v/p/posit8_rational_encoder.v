module posit8_rational_encoder

const max_count = 32
const max_words = 66

fn positive_units(code u8) u64 {
  mut cursor := 6
  regime_bit := (code >> cursor) & 1
  mut run := 0
  for cursor >= 0 && ((code >> cursor) & 1) == regime_bit {
    run++
    cursor--
  }
  regime := if regime_bit != 0 { run - 1 } else { -run }
  if cursor >= 0 { cursor-- }
  mut exponent := 0
  for _ in 0 .. 2 {
    exponent <<= 1
    if cursor >= 0 {
      exponent |= int((code >> cursor) & 1)
      cursor--
    }
  }
  width := cursor + 1
  fraction := if width == 0 { 0 } else { int(code) & ((1 << width) - 1) }
  significand := (1 << width) + fraction
  shift := 4 * regime + exponent + 24 - width
  return u64(significand) << shift
}

fn compare_ratio_to_unit(scaled u64, denominator u64, unit u64) int {
  quotient := scaled / denominator
  remainder := scaled % denominator
  if quotient < unit { return -1 }
  if quotient > unit { return 1 }
  if remainder == 0 { return 0 }
  return 1
}

fn encode_one(numerator i64, denominator i64) u8 {
  if numerator == 0 { return 0 }
  negative := numerator < 0
  magnitude := u64(if negative { -numerator } else { numerator })
  scaled := magnitude << 24
  mut chosen := u8(0)
  if compare_ratio_to_unit(scaled, u64(denominator), 1) <= 0 {
    chosen = 1
  } else if compare_ratio_to_unit(scaled, u64(denominator), positive_units(127)) >= 0 {
    chosen = 127
  } else {
    mut low := 1
    mut high := 127
    for low < high {
      middle := low + (high - low) / 2
      if compare_ratio_to_unit(scaled, u64(denominator), positive_units(u8(middle))) > 0 { low = middle + 1 } else { high = middle }
    }
    upper := u8(low)
    lower := upper - 1
    midpoint := positive_units(lower) + positive_units(upper)
    midpoint_comparison := compare_ratio_to_unit(scaled << 1, u64(denominator), midpoint)
    if midpoint_comparison < 0 { chosen = lower }
    else if midpoint_comparison > 0 { chosen = upper }
    else if (lower & 1) == 0 { chosen = lower }
    else { chosen = upper }
  }
  if negative { return u8(256 - int(chosen)) }
  return chosen
}

@[export: 'posit8_rational_encoder']
pub fn posit8_rational_encoder(input &i64, length usize, mut output &u8, capacity usize) i64 {
  if length < 1 || length > max_words { return -1 }
  unsafe {
    if input == nil { return -1 }
    count_word := input[0]
    if count_word < 0 || count_word > max_count || length != usize(1 + count_word * 2) { return -1 }
    count := int(count_word)
    for index in 0 .. count {
      numerator := input[1 + 2 * index]
      denominator := input[2 + 2 * index]
      if numerator < -2147483648 || numerator > 2147483648 || denominator < 1 || denominator > 2147483648 { return -1 }
    }
    if output == nil || capacity < count { return -2 }
    mut staged := [max_count]u8{}
    for index in 0 .. count { staged[index] = encode_one(input[1 + 2 * index], input[2 + 2 * index]) }
    for index in 0 .. count { output[index] = staged[index] }
    return i64(count)
  }
}
