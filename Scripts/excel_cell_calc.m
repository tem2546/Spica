%Spica
%”ŽšÀ•W‚ÆExcel‚ÌƒZƒ‹ˆÊ’u‚Ì•ÏŠ·
function cell = excel_cell_calc(pos)
    alp = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    column = pos(1);
    row = pos(2);
    a = 26;
    i = 1;
    while a >= 26
        a = floor(column/26);
        b = mod(column,26);
        num(i) = b;
        i = i + 1;
    end
    if all(a)
        num = [a,num];
    end
    column = alp(num);
    cell = strcat(column,num2str(row));
end