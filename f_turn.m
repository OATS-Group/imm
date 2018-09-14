%
% A coordinated turn model for extended IMM filter demonstration
%
%

function x_k = f_turn(x,param)

    dt = param{1};
    w = x(5);
    if w == 0
        coswt = cos(w*dt);
        coswto = cos(w*dt)-1;
        coswtopw = 0;

        sinwt = sin(w*dt);
        sinwtpw = dt;
    else
        coswt = cos(w*dt);
        coswto = cos(w*dt)-1;
        coswtopw = coswto/w;

        sinwt = sin(w*dt);
        sinwtpw = sinwt/w;
    end

    F = [1 0 sinwtpw    coswtopw  0;...
         0 1 -coswtopw  sinwtpw   0;...
         0 0 coswt      -sinwt    0;...
         0 0 sinwt      coswt     0;...
         0 0 0          0         1];
    x_k = F*x;




