function d = defect_u(U, METHOD, SV_TOLERANCE)
% 20080301 KZ, WT
% 20160408 WB
% 20180824 W. Bruzda, name[at]uj.edu.pl : name = w.bruzda
%
% http://chaos.if.uj.edu.pl/~karol/hadamard/
% https://github.com/matrix-toolbox/
%
% Dephased defect of a unitary (Hadamard) matrix U.
%
% Based on the idea of W. Tadej and K. Zyczkowski
% see: Linear Algebra Appl. 429, pp. 447-481 (2008)
% ------------------------------------------------------------------------------
% exemplary call for U = unitary matrix:
% >> defect_u(U, METHOD, SV_TOLERANCE);
%
% Possible METHOD values:
% 'R' - rank of matrix R
% 'S' - given SV_TOLERANCE the rank of R is expressed as the number of non-zero singular values of R
%       useful when dealing with approximate U elements
% 'T' - method of tangent spaces...
%
% Exemplary usage: (let F be a Fourier matrix)
% >> defect_u(F)             % default METHOD = 'R'
% >> defect_u(F, 'R')
% >> defect_u(F, 'S', 1e-10) % custom SV_TOLERANCE
% >> defect_u(F, 'S')        % default SV_TOLERANCE = 1e-12
% >> defect_u(F, 'T')
% >> defect_u(F, 'R', 1e-12) % SV_TOLERANCE is ignored in this case
% >> defect_u(F, 'T', 1e-12) % SV_TOLERANCE is ignored in this case

% >> version % 9.1.0.441655 (R2016b)

    N = size(U, 1);

    if ~exist('METHOD') % default method
        if VERBOSE_MODE
            disp(sprintf('Method: ''R'''));
        end
        d = dR(U, N);
        return
    end

    switch METHOD
        case 'R'
            if VERBOSE_MODE
                disp(sprintf('Method: ''R'''));
            end
            d = dR(U, N);
        case 'S'
            if ~exist('SV_TOLERANCE') || ~isnumeric(SV_TOLERANCE)
                SV_TOLERANCE = 1e-13; % default SV_TOLERANCE
            end
            if VERBOSE_MODE
                disp(sprintf('Method: ''S'' with ''SV_TOLERANCE'' = %g', SV_TOLERANCE));
            end
            d = dS(U, N, SV_TOLERANCE);
        case 'T'
            if VERBOSE_MODE
                disp(sprintf('method: ''T'''));
            end
            d = dT(U, N);
        otherwise
            error('METHOD not implemented!');
    end
end

function R = get_R(U, N)
    tau = N * (N - 1) / 2;
    R = zeros(2 * tau, N * N); % system of linear equations matrix split onto real and imaginary part
    t = -1;
    for row = 1 : N - 1
        for next_row = row + 1 : N
            t = t + 2;         % start with index = 1
            for k = 1 : N
                M = U(row, k) * U(next_row, k)';
                MR = real(M);
                MI = imag(M);
                R(t + 0, mod(row - 1, N) * N + k) = MR;
                R(t + 1, mod(row - 1, N) * N + k) = MI;
                R(t + 0, mod(next_row - 1, N) * N + k) = -MR;
                R(t + 1, mod(next_row - 1, N) * N + k) = -MI;
            end
        end
    end
end

function d = dR(U, N)
% The method of calculating the defect in this version is extremaly sensitive to
% small deviations from exact values. That is because of the MATLAB methods used
% to estimate the rank of a matrix. User shall provide as accurate matrix values
% as possible. For instance, replacing 1.000000 with 0.999998 would result in an
% untrustworthy outcome! This problem should be solved by considering "non-zero"
% singular values of the matrix "R". See "dS(...)" below.
    if VERBOSE_MODE
        disp('Wait... Preparing matrix ''R''...');
    end
    R = get_R(U, N);
    if VERBOSE_MODE
        disp('Wait... Getting rank of ''R''...');
    end
    d = (N - 1) * (N - 1) - rank(R); % dephased defect value = d(H) != D(H)
end

function d = dS(U, N, SV_TOLERANCE)
    if VERBOSE_MODE
        disp('Wait... Preparing matrix ''R''...');
    end
    R = get_R(U, N);
    if VERBOSE_MODE
        disp('Wait... Getting SVD of ''R''...');
    end
    NZSV_R = sum((svd(R) > SV_TOLERANCE)); % non-zero SV of R
    d = (N - 1) * (N - 1) - NZSV_R;
end

function d = dT(U, N)
    % 2004---- WT
    % 20120703 WT and KZ - minor update (Zakopane)
    P = real(U);
    R = imag(U);
    T = [];
    % T = matrix of images of tangent vectors (no zeros) to manifold of unitary
    % matrices at U under mapping DF (Jacobian of F), where
    % F : R^(2*N^2) -> R^(N^2) maps the set of complex matrices to real matrices
    % by squaring the moduli of entries (preserving each element position),
    % eventually rank(T) is the size of tangent space image

    if VERBOSE_MODE
        disp('Wait... Getting dimension of the tangent space...');
    end
    % image of vectors (A, 0), where A - basis of a anti-symmetric real part 
    for k = 1 : (N - 1),
        for l = (k + 1) : N,
            V = zeros(N ^ 2, 1);
            V(((k - 1) * N + 1) : ((k - 1) * N + N), 1) = transpose(P(k, :) .* P(l, :) + R(k, :) .* R(l, :));
            V(((l - 1) * N + 1) : ((l - 1) * N + N), 1) = - V(((k - 1) * N + 1) : ((k - 1) * N + N), 1);
            T = [T V];
        end;
    end;

    % image of vectors (0, S), where S - basis of a symmetric imaginary part - excluding zeros
    for k = 1 : (N - 1),
        for l = (k + 1) : N,
            V = zeros(N ^ 2, 1);
            V(((k - 1) * N + 1) : ((k - 1) * N + N), 1) = transpose(- P(k, :) .* R(l, :) + R(k, :) .* P(l, :));
            V(((l - 1) * N + 1) : ((l - 1) * N + N), 1) = - V(((k - 1) * N + 1) : ((k - 1) * N + N), 1);
            T = [T V];
        end;
    end;
    d = (N - 1) * (N - 1) - rank(T);
end


function verbose=VERBOSE_MODE
% Toggle:
%   verbose = false  - to suppress all displays except for the defect value
%   verbose = true   - to display everything (helpful when dealing with really big matrices, to get a hint what's currently going on)
    verbose = false;
end

