const pack = @import("ziggy-pack.zig");

const std = @import("std");

const testing = std.testing;

test "null pack size" {
    const n = null;
    try testing.expect(1 == pack.packSize(n));
}

test "null pack" {
    const n = null;
    var buffer = [_]u8{0} ** pack.packSize(n);
    var i: usize = 0;
    pack.pack(&buffer, &i, n);
    const expecation = [_]u8{0xc0};
    try testing.expectEqualSlices(u8, &expecation, &buffer);
}

test "bool true pack size" {
    const n = true;
    try testing.expect(1 == pack.packSize(n));
}

test "bool true size" {
    const packtest = true;
    var buffer = [_]u8{0} ** pack.packSize(packtest);
    var i: usize = 0;
    pack.pack(&buffer, &i, packtest);
    const expecation = [_]u8{0xc3};
    try testing.expectEqualSlices(u8, &expecation, &buffer);
}

test "bool false pack size" {
    const n = false;
    try testing.expect(1 == pack.packSize(n));
}

test "float 32 99.112122 size pack" {
    const packtest: f32 = 99.112122;

    try testing.expectEqual(5, pack.packSize(packtest));
}

test "float 32 99.112122 pack" {
    const packtest: f32 = 99.112122;
    const expectation = [_]u8{ 0xCa, 0x42, 0xc6, 0x39, 0x68 };

    var buffer = [_]u8{0} ** pack.packSize(packtest);
    var i: usize = 0;
    pack.pack(&buffer, &i, packtest);
    try testing.expectEqualSlices(u8, &expectation, &buffer);
}

test "float 64 0.128129 size pack" {
    const packtest: f64 = 0.128129;

    try testing.expectEqual(9, pack.packSize(packtest));
}

test "float 64  0.128129 pack" {
    const packtest: f64 = 0.128129;
    const expectation = [_]u8{ 0xCB, 0x3F, 0xC0, 0x66, 0x87, 0xF4, 0x55, 0xA7, 0xD2 };

    var buffer = [_]u8{0} ** pack.packSize(packtest);
    var i: usize = 0;
    pack.pack(&buffer, &i, packtest);
    try testing.expectEqualSlices(u8, &expectation, &buffer);
}

test "Int 8 -95 pack" {
    const packtest: i8 = -95;
    const expectation = [_]u8{ 0xdc, 0xa1 };
    var buffer = [_]u8{0} ** pack.packSize(packtest);
    var i: usize = 0;
    pack.pack(&buffer, &i, packtest);
    try testing.expectEqualSlices(u8, &expectation, &buffer);
}

test "Int 8 95 pack" {
    const packtest: i8 = 95;
    const expectation = [_]u8{ 0xdc, 95 };
    var buffer = [_]u8{0} ** pack.packSize(packtest);
    var i: usize = 0;
    pack.pack(&buffer, &i, packtest);
    try testing.expectEqualSlices(u8, &expectation, &buffer);
}

test "Int 16 Max Int pack" {
    const packtest: i16 = std.math.maxInt(i16);
    const expectation = [_]u8{ 0xdd, 0x7f, 0xff };
    var buffer = [_]u8{0} ** pack.packSize(packtest);
    var i: usize = 0;
    pack.pack(&buffer, &i, packtest);
    try testing.expectEqualSlices(u8, &expectation, &buffer);
}

test "Int 16 Min Int pack" {
    const packtest: i16 = std.math.minInt(i16);
    const expectation = [_]u8{ 0xdd, 0x80, 0x0 };
    var buffer = [_]u8{0} ** pack.packSize(packtest);
    var i: usize = 0;
    pack.pack(&buffer, &i, packtest);
    try testing.expectEqualSlices(u8, &expectation, &buffer);
}

test "Int 32 Max Int pack" {
    const packtest: i32 = std.math.maxInt(i32);
    const expectation = [_]u8{ 0xde, 0x7f, 0xff, 0xff, 0xff };
    var buffer = [_]u8{0} ** pack.packSize(packtest);
    var i: usize = 0;
    pack.pack(&buffer, &i, packtest);
    try testing.expectEqualSlices(u8, &expectation, &buffer);
}

test "Int 32 Min Int pack" {
    const packtest: i32 = std.math.minInt(i32);
    const expectation = [_]u8{ 0xde, 0x80, 0, 0, 0 };
    var buffer = [_]u8{0} ** pack.packSize(packtest);
    var i: usize = 0;
    pack.pack(&buffer, &i, packtest);
    try testing.expectEqualSlices(u8, &expectation, &buffer);
}

test "Int 64 Max Int pack" {
    const packtest: i64 = std.math.maxInt(i64);
    const expectation = [_]u8{ 0xdf, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
    var buffer = [_]u8{0} ** pack.packSize(packtest);
    var i: usize = 0;
    pack.pack(&buffer, &i, packtest);
    try testing.expectEqualSlices(u8, &expectation, &buffer);
}

test "Int 64 Min Int pack" {
    const packtest: i64 = std.math.minInt(i64);
    const expectation = [_]u8{ 0xdf, 0x80, 0, 0, 0, 0, 0, 0, 0 };
    var buffer = [_]u8{0} ** pack.packSize(packtest);
    var i: usize = 0;
    pack.pack(&buffer, &i, packtest);
    try testing.expectEqualSlices(u8, &expectation, &buffer);
}
