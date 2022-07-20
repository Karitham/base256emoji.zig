const std = @import("std");
const unicode = std.unicode;
const testing = std.testing;

const emojis = "🚀🪐☄🛰🌌🌑🌒🌓🌔🌕🌖🌗🌘🌍🌏🌎🐉☀💻🖥💾💿😂❤😍🤣😊🙏💕😭😘👍😅👏😁🔥🥰💔💖💙😢🤔😆🙄💪😉☺👌🤗💜😔😎😇🌹🤦🎉💞✌✨🤷😱😌🌸🙌😋💗💚😏💛🙂💓🤩😄😀🖤😃💯🙈👇🎶😒🤭❣😜💋👀😪😑💥🙋😞😩😡🤪👊🥳😥🤤👉💃😳✋😚😝😴🌟😬🙃🍀🌷😻😓⭐✅🥺🌈😈🤘💦✔😣🏃💐☹🎊💘😠☝😕🌺🎂🌻😐🖕💝🙊😹🗣💫💀👑🎵🤞😛🔴😤🌼😫⚽🤙☕🏆🤫👈😮🙆🍻🍃🐶💁😲🌿🧡🎁⚡🌞🎈❌✊👋😰🤨😶🤝🚶💰🍓💢🤟🙁🚨💨🤬✈🎀🍺🤓😙💟🌱😖👶🥴▶➡❓💎💸⬇😨🌚🦋😷🕺⚠🙅😟😵👎🤲🤠🤧📌🔵💅🧐🐾🍒😗🤑🌊🤯🐷☎💧😯💆👆🎤🙇🍑❄🌴💣🐸💌📍🥀🤢👅💡💩👐📸👻🤐🤮🎼🥵🚩🍎🍊👼💍📣🥂";
const utf8_emojis = table();
const codepoints = countCodePoints(emojis);

fn countCodePoints(in: []const u8) usize {
    @setEvalBranchQuota(5000);
    return unicode.utf8CountCodepoints(in) catch 0;
}

fn table() [codepoints]u21 {
    @setEvalBranchQuota(1500);
    var r: [codepoints]u21 = undefined;
    var view = unicode.Utf8View.initUnchecked(emojis).iterator();
    var i: usize = 0;
    while (view.nextCodepoint()) |c| : (i += 1) r[i] = c;
    return r;
}

pub fn decode(in: []const u8, out: []u8) !usize {
    var view = unicode.Utf8View.initUnchecked(in).iterator();
    var i: usize = 0;
    while (view.nextCodepoint()) |c| : (i += 1) {
        for (utf8_emojis) |c1, j| if (c1 == c) {
            out[i] = @intCast(u8, j);
        };
    }
    return i;
}

pub fn decodeBuf(in: []const u8, out: []u8) ![]u8 {
    const n = try decode(in, out);
    return out[0..n];
}

pub fn encode(in: []const u8, out: []u8) !usize {
    var i: usize = 0;
    for (in) |c| {
        i += try unicode.utf8Encode(utf8_emojis[c], out[i..]);
    }
    return i;
}

pub fn encodeBuf(in: []const u8, out: []u8) ![]u8 {
    const n = try encode(in, out);
    return out[0..n];
}

test "decode" {
    const in = "😴🌟😅😬🤘🤤😻👏";
    const out = "hi juan!";

    var buf: [unicode.utf8CountCodepoints(in) catch 0]u8 = undefined;
    _ = try decode(in, &buf);
    try testing.expectEqualSlices(u8, out, &buf);
}

test "encode" {
    {
        const in = "hi juan!";
        const out = "😴🌟😅😬🤘🤤😻👏";
        var buf: [in.len * 4]u8 = undefined;
        try testing.expectEqualSlices(u8, out, try encodeBuf(in, &buf));
    }
    {
        const in = "yes mani !";
        const out = "🏃✋🌈😅🌷🤤😻🌟😅👏";
        var buf: [in.len * 4]u8 = undefined;
        try testing.expectEqualSlices(u8, out, try encodeBuf(in, &buf));
    }
}

test "encode rate" {
    const repeat = 10000000;

    var i: usize = 0;
    const in = "hi juan!";
    var buf: [in.len * 4]u8 = undefined;

    const start_t = std.time.nanoTimestamp();
    while (i < repeat) : (i += 1) std.mem.doNotOptimizeAway(try encodeBuf(in, &buf));
    const end_t = std.time.nanoTimestamp();

    std.debug.print("took: {} for {} iter. {} ns/op\n", .{
        std.fmt.fmtDuration(@intCast(u64, end_t - start_t)),
        repeat,
        @intToFloat(f64, end_t - start_t) / repeat,
    });
}

test "decode rate" {
    const repeat = 1000000;

    var i: usize = 0;
    const in = "😴🌟😅😬🤘🤤😻👏";
    var buf: [in.len * 4]u8 = undefined;

    const start_t = std.time.nanoTimestamp();
    while (i < repeat) : (i += 1) std.mem.doNotOptimizeAway(try decodeBuf(in, &buf));
    const end_t = std.time.nanoTimestamp();

    std.debug.print("took: {} for {} iter. {} ns/op\n", .{
        std.fmt.fmtDuration(@intCast(u64, end_t - start_t)),
        repeat,
        @intToFloat(f64, end_t - start_t) / repeat,
    });
}
