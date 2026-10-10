// Reproducer: unpacked array concatenation used as a shift register.
//
// When the assigned array also appears inside the concatenation and has a
// descending range, every element ends up equal to the first item of the
// concatenation. Assigning the same expression to a different array, or using
// an ascending range, gives the result required by IEEE 1800-2023 10.10.
//
// Run with: scratch\run_concat_shift.ps1
class holder;
    logic [7:0] m [3:0];
    function void fill();
        m[0] = 8'd10; m[1] = 8'd11; m[2] = 8'd12; m[3] = 8'd13;
    endfunction
    function void show(string tag);
        $display("%s: [3]=%0d [2]=%0d [1]=%0d [0]=%0d", tag, m[3], m[2], m[1], m[0]);
    endfunction
endclass

module t;
    logic [7:0] a [3:0];   // descending range
    logic [7:0] c [3:0];
    logic [7:0] b [0:3];   // ascending range
    holder h;

    initial begin
        $display("expected for every descending case: [3]=99 [2]=13 [1]=12 [0]=11");
        $display("(except the last class case, expected [3]=10 [2]=13 [1]=12 [0]=11)");

        a[0] = 8'd10; a[1] = 8'd11; a[2] = 8'd12; a[3] = 8'd13;
        c = {8'd99, a[3:1]};
        $display("module, separate target : [3]=%0d [2]=%0d [1]=%0d [0]=%0d", c[3], c[2], c[1], c[0]);

        a = {8'd99, a[3:1]};
        $display("module, same array      : [3]=%0d [2]=%0d [1]=%0d [0]=%0d", a[3], a[2], a[1], a[0]);

        a[0] = 8'd10; a[1] = 8'd11; a[2] = 8'd12; a[3] = 8'd13;
        a = {'0, a[3:1]};
        $display("module, same array, '0  : [3]=%0d [2]=%0d [1]=%0d [0]=%0d (expected [3]=0 [2]=13 [1]=12 [0]=11)", a[3], a[2], a[1], a[0]);

        h = new();
        h.fill();
        h.m = {8'd99, h.m[3:1]};
        h.show("class,  same array      ");

        h.fill();
        h.m = {h.m[0], h.m[3:1]};
        h.show("class,  first item m[0] ");

        b[0] = 8'd10; b[1] = 8'd11; b[2] = 8'd12; b[3] = 8'd13;
        b = {b[1:3], 8'd99};
        $display("ascending [0:3], expected [0]=11 [1]=12 [2]=13 [3]=99");
        $display("module, same array      : [0]=%0d [1]=%0d [2]=%0d [3]=%0d", b[0], b[1], b[2], b[3]);
        $finish;
    end
endmodule
