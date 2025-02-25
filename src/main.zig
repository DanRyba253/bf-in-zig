const std = @import("std");
const options = @import("options");

pub fn main() !void {
    var memory = [_]u8{0} ** (1 + std.math.maxInt(u16));
    var address_pointer: u16 = 0;

    const stdin = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(stdin);
    const input = br.reader();

    const stdout = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout);
    const output = bw.writer();

    @setEvalBranchQuota(2000000000);

    comptime var source = options.source;
    const bfAst = comptime comptimeParseBfAst(&source);

    genProgram(bfAst, &memory, &address_pointer, input, output);

    try bw.flush();
}

const BfExpr = union(enum) {
    incAddr,
    decAddr,
    incMem,
    decMem,
    inp,
    out,
    loop: BfAst,
};

const BfAst = []const BfExpr;

fn comptimeParseBfAst(source: *[]const u8) BfAst {
    var bfAst: BfAst = &.{};
    while (source.len > 0) {
        const command = source.*[0];
        source.* = source.*[1..];
        switch (command) {
            '>' => bfAst = bfAst ++ &[1]BfExpr{.incAddr},
            '<' => bfAst = bfAst ++ &[1]BfExpr{.decAddr},
            '+' => bfAst = bfAst ++ &[1]BfExpr{.incMem},
            '-' => bfAst = bfAst ++ &[1]BfExpr{.decMem},
            '.' => bfAst = bfAst ++ &[1]BfExpr{.out},
            ',' => bfAst = bfAst ++ &[1]BfExpr{.inp},
            '[' => bfAst = bfAst ++ &[1]BfExpr{.{ .loop = comptimeParseBfAst(source) }},
            ']' => return bfAst,
            else => {},
        }
    }
    return bfAst;
}

inline fn genProgram(
    comptime bfAst: BfAst,
    memory: []u8,
    addressPointer: *u16,
    input: anytype,
    output: anytype,
) void {
    inline for (bfAst) |bfExpr| switch (bfExpr) {
        .incAddr => addressPointer.* +%= 1,
        .decAddr => addressPointer.* -%= 1,
        .incMem => memory[addressPointer.*] +%= 1,
        .decMem => memory[addressPointer.*] -%= 1,
        .out => output.writeByte(memory[addressPointer.*]) catch {},
        .inp => {
            const old_memory = memory[addressPointer.*];
            memory[addressPointer.*] = input.readByte() catch old_memory;
        },
        .loop => |loopBody| {
            while (memory[addressPointer.*] != 0) {
                genProgram(loopBody, memory, addressPointer, input, output);
            }
        },
    };
}
