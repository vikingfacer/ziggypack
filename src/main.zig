const std = @import("std");

const msg = struct {
    float32: f32 = 0.02,
    float64: f64 = 0.0444,
};

const testmsg = struct {
    a: [5]u32 = [_]u32{ 1, 2, 3, 4, 5 },
    t: bool = true,
    f: bool = false,
    nil: @Type(.Null) = null,
    int8: i8 = -1,
    int16: i16 = -2,
    int32: i32 = -3,
    int64: i64 = -4,
    unt8: u8 = 1,
    unt16: u16 = 2,
    unt32: u32 = 3,
    unt64: u64 = 4,
    m: msg = msg{},
};

pub fn main() !u8 {
    const testmsg1 = testmsg{};
    const ps = packSize(testmsg1);
    var a = [_]u8{0} ** ps;
    std.debug.print("a len: {}\n", .{a.len});

    var i: usize = 0;
    pack(a[0..a.len], &i, testmsg1);

    for (a) |item| {
        std.debug.print("{x}", .{item});
    }
    return 0;
}
const hbm = 0x001F;
const obm = 0x00FF;
const tbm = 0x0FFF;
const fbm = 0xFFFF;

// to make this comptime I need to figure out the size first for the buffer aka Array
fn packSize(data: anytype) comptime_int {

    // obm: one byte mask
    // tbm: two byte mask
    // fbm: four byte mask

    var pack_size: usize = 0;
    // this part is for struct

    switch (@typeInfo(@TypeOf(data))) {
        .Bool => {
            pack_size += 1;
        },
        .Float => |f| {
            if (f.bits == 32 or f.bits == 64) {
                pack_size += 1 + f.bits / 8;
            } else {
                @compileError("MsgPack does not support Float 16 or Float 128");
            }
        },
        .Int => |i| {
            pack_size += 1 + (i.bits / 8);
        },
        .Array => |a| {
            // parse as str
            if (a.sentinel != null and @TypeOf(a.child) == u8) {
                if (a.len <= 31) {
                    pack_size += 1;
                } else if (a.len > 31 and a.len <= obm) {
                    pack_size += 2;
                } else if (a.len > obm and a.len <= tbm) {
                    pack_size += 3;
                } else if (a.len > tbm and a.len <= fbm) {
                    pack_size += 5;
                } else {
                    @compileError("[_:0]u8 is too large for MsgPack");
                }
                pack_size += a.len;
            } else {
                // parse as array
                if (a.len <= 15) {
                    pack_size += 1;
                } else if (a.len > 15 and a.len <= obm) {
                    pack_size += 3;
                } else if (a.len > tbm and a.len <= fbm) {
                    pack_size += 5;
                } else {
                    @compileError("[]Type is too large for MsgPack");
                }
                pack_size += a.len * packSize(a.child);
            }
        },
        .Struct => |s| {
            // parse as array
            if (s.fields.len <= 15) {
                pack_size += 1;
            } else if (s.fields.len > 15 and s.fields.len <= obm) {
                pack_size += 3;
            } else if (s.fields.len > tbm and s.fields.len <= fbm) {
                pack_size += 5;
            } else {
                @compileError("[]Type is too large for MsgPack");
            }
            inline for (s.fields) |f| {
                pack_size += packSize(f.name);
                pack_size += packSize(@field(data, f.name));
            }
        },
        .Null => {
            pack_size += 1;
        },
        .Pointer => |p| {
            // string liters
            const slice = std.builtin.TypeInfo.Pointer.Size.Slice;
            if (p.child == u8 and p.size == slice and p.is_const) {
                if (data.len <= 31) {
                    pack_size += 1;
                } else if (data.len > 31 and data.len <= obm) {
                    pack_size += 2;
                } else if (data.len > obm and data.len <= tbm) {
                    pack_size += 3;
                } else if (data.len > tbm and data.len <= fbm) {
                    pack_size += 4;
                } else {
                    @compileError("[]const u8 is too large for MsgPack");
                }
                pack_size += data.len;
            } else {
                @compileError("Cannot Parse Pointer Type");
            }
        },
        .Optional => {},
        .Type => {},
        else => |u| {
            @compileLog(u);
            @compileError("Type not supported");
        },
    }
    return pack_size;
}

fn pack(pack_buf: []u8, packIndex: *usize, data: anytype) void {
    const toBytes = std.mem.toBytes;
    const copy = std.mem.copy;
    switch (@typeInfo(@TypeOf(data))) {
        .Null => {
            pack_buf[packIndex.*] = 0xc0;
            packIndex.* += 1;
        },
        .Bool => {
            pack_buf[packIndex.*] = if (data) 0xc3 else 0xc2;
            packIndex.* += 1;
        },
        .Float => |f| {
            if (f.bits == 32) {
                pack_buf[packIndex.*] = 0xca;
            } else if (f.bits == 64) {
                pack_buf[packIndex.*] = 0xcb;
            } else {
                //should throw error here cannot pack non 32/64 float
            }
            packIndex.* += 1;
            const float_bytes = toBytes(data);
            copy(u8, pack_buf[packIndex.*..pack_buf.len], &float_bytes);
            packIndex.* += float_bytes.len;
        },
        .Int => |i| {
            const signedness = std.builtin.Signedness;
            var int_header: u8 = switch (i.bits) {
                8 => 0x0c,
                16 => 0x0d,
                32 => 0x0e,
                64 => 0x0f,
                else => {
                    //throw error
                },
            };
            if (i.signedness == signedness.signed) {
                int_header |= 0xd0;
            } else {
                int_header |= 0xc0;
            }
            pack_buf[packIndex.*] = int_header;
            packIndex.* += 1;
            const int_bytes = toBytes(@byteSwap(@TypeOf(data), data));
            copy(u8, pack_buf[packIndex.*..pack_buf.len], &int_bytes);
            packIndex.* += int_bytes.len;
        },
        .Array => |a| {
            if (a.sentinel) |sent| {
                // do the same as string literals
                _ = sent;
            } else {
                switch (data.len) {
                    0...0x0f => {},
                    0x10...tbm => {},
                    tbm + 1...fbm => {},
                    else => {
                        //throw error
                    },
                }

                for (data) |item| {
                    pack(pack_buf, packIndex, item);
                }
            }
        },
        .Pointer => |p| {
            // string liters
            const slice = std.builtin.TypeInfo.Pointer.Size.Slice;
            if (p.child == u8 and p.size == slice and p.is_const) {
                switch (data.len) {
                    0...hbm => {
                        const header = 0b10100000 | @truncate(u8, data.len);
                        pack_buf[packIndex.*] = header;
                        packIndex.* += 1;
                    },
                    (hbm + 1)...obm => {
                        const header = 0xd9;
                        pack_buf[packIndex.*] = header;
                        packIndex.* += 1;
                        const size_bytes = @truncate(u8, data.len);
                        pack_buf[packIndex.*] = size_bytes;
                        packIndex.* += 1;
                    },
                    (obm + 1)...tbm => {
                        const header = 0xda;
                        pack_buf[packIndex.*] = header;
                        packIndex.* += 1;
                        const size_bytes = toBytes(@byteSwap(u16, @truncate(u16, data.len)));
                        copy(u8, pack_buf[packIndex.*..pack_buf.len], &size_bytes);
                        packIndex.* += size_bytes.len;
                    },
                    (tbm + 1)...fbm => {
                        const header = 0xdb;
                        pack_buf[packIndex.*] = header;
                        packIndex.* += 1;
                        const size_bytes = toBytes(@byteSwap(u32, @truncate(u32, data.len)));
                        copy(u8, pack_buf[packIndex.*..pack_buf.len], &size_bytes);
                        packIndex.* += size_bytes.len;
                    },
                    else => {
                        // throw error
                    },
                }
                copy(u8, pack_buf[packIndex.*..pack_buf.len], data);
                packIndex.* += data.len;
            }
        },

        .Struct => |s| {
            inline for (s.fields) |f| {
                pack(pack_buf, packIndex, f.name);
                pack(pack_buf, packIndex, @field(data, f.name));
            }
        },
        else => {},
    }
}
