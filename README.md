# Ziggy Pack
![testing workflow](https://github.com/vikingfacer/ziggypack/actions/workflows/main.yml/badge.svg)

Ziggy Pack is a message pack library for zig written is zig.
Ziggy Pack uses compile time reflection to get buffer size, pack and (soon)unpack.

## Basic usage

```zig
const std = @import("std");
const pack = @import("ziggy-pack.zig");

const testmsg = struct {
    a: [5]u32 = [_]u32{
    f: bool = false,
    nil: @Type(.Null) = null,
    int32: i32 = -3,
    unt64: u64 = 4,
};

pub fn main() !u8 {
    const testmsg1 = testmsg{};
    // get the size of the buffer you'll need
    const ps = pack.packSize(testmsg1);
    var a = [_]u8{0} ** ps;

    // pack the struct
    var i: usize = 0;
    pack.pack(a[0..a.len], &i, testmsg1);

    return 0;
}
```
## what is done?

### pack
- [x] nil
- [x] false
- [x] true
- [x] float-32
- [x] float-64
- [x] uint-8
- [x] uint-16
- [x] uint-32
- [x] uint-64
- [x] int-8
- [x] int-16
- [x] int-32
- [x] int-64
- [x] fixstr(needs testing)
- [x] str-8(needs testing)
- [x] str-16(needs testing)
- [x] str-32(needs testing)
- [x] fixarray(needs testing)
- [x] array-16(needs testing)
- [x] array-32(needs testing)
- [x] fixmap(needs testing)
- [x] map-16(needs testing)
- [x] map-32(needs testing)

### unpack (not implemented)
- [ ] nil
- [ ] false
- [ ] true
- [ ] float-32
- [ ] float-64
- [ ] uint-8
- [ ] uint-16
- [ ] uint-32
- [ ] uint-64
- [ ] int-8
- [ ] int-16
- [ ] int-32
- [ ] int-64
- [ ] fixstr
- [ ] str-8
- [ ] str-16
- [ ] str-32
- [ ] fixarray
- [ ] array-16
- [ ] array-32
- [ ] fixmap
- [ ] map-16
- [ ] map-32

#### Is not implemented and will not be implemented
- positive-fixint
- negative-fixint
- (never-used)
- bin-8
- bin-16
- bin-32
- ext-8
- ext-16
- ext-32
- fixext-1
- fixext-2
- fixext-4
- fixext-8
- fixext-16

