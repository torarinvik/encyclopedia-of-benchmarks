@export("easter")
fn easter(year: Int64) abi("C") -> Int64:
    if year < 0 or year > 9999: return -1
    if year <= 1582: return 0
    let a = year % 19; let b = year / 100; let c = year % 100
    let d = b / 4; let e = b % 4; let f = (b + 8) / 25; let g = (b - f + 1) / 3
    let h = (19 * a + b - d - g + 15) % 30; let i = c / 4; let k = c % 4
    let r = (32 + 2 * e + 2 * i - h - k) % 7; let m = (a + 11 * h + 22 * r) / 451
    let date = h + r - 7 * m + 114
    return (date / 31) * 100 + date % 31 + 1
