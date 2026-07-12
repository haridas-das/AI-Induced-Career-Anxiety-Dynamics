%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sensitivity Analysis for R0
% Analytical normalized sensitivity indices + LHS with Spearman and PRCC
%
% Verified against symbolic differentiation (baseline beta=0.40, delta=0.25,
% gamma=0.20, mu=0.05, R0=5.6):
%   S_beta = +0.2857   S_delta = +0.7143
%   S_gamma= -0.0857   S_mu    = -0.9143   (S_alpha = S_c = 0)
%   Consistency check: S_beta + S_delta = 1.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all; clc;

%% ============================================================
% Baseline parameters (Table 1)
%% ============================================================
alpha = 0.30;
c     = 0.75;
beta  = 0.40;
delta = 0.25;
gamma = 0.20;
mu    = 0.05;

%% ============================================================
% Basic reproduction number
%% ============================================================
R0 = (beta*mu + delta*gamma)/(mu*(gamma+mu));
fprintf('\nBaseline R0 = %.4f\n\n',R0);

%% ============================================================
% Analytical normalized sensitivity indices
%   S_q = (dR0/dq)*(q/R0)
% alpha and c do not appear in R0  =>  indices are exactly 0.
%% ============================================================
den = (gamma+mu)*(beta*mu + delta*gamma);

S_alpha = 0;
S_c     = 0;
S_beta  =  beta*mu/(beta*mu + delta*gamma);
S_delta =  delta*gamma/(beta*mu + delta*gamma);
S_gamma =  gamma*mu*(delta-beta)/den;                              % <-- mu factor added
S_mu    = -(beta*mu^2 + 2*delta*gamma*mu + delta*gamma^2)/den;     % original form (correct)

Sens = [S_alpha; S_c; S_beta; S_delta; S_gamma; S_mu];

fprintf('Consistency check S_beta + S_delta = %.4f (should be 1)\n\n', S_beta+S_delta);

disp('Analytical sensitivity indices')
disp(table(["alpha";"c";"beta";"delta";"gamma";"mu"],Sens,...
    'VariableNames',{'Parameter','Sensitivity'}))

%% ============================================================
% Latin Hypercube Sampling  (+/-20% ranges)
%% ============================================================
N = 5000;
X = lhsdesign(N,6,'criterion','maximin','iterations',100);

LB = [0.24 0.60 0.32 0.20 0.16 0.04];
UB = [0.36 0.90 0.48 0.30 0.24 0.06];
P  = LB + X.*(UB-LB);

A = P(:,1);  C = P(:,2);  B = P(:,3);
D = P(:,4);  G = P(:,5);  M = P(:,6);

% Sampled R0
R = (B.*M + D.*G)./(M.*(G+M));

names = ["alpha";"c";"beta";"delta";"gamma";"mu"];

%% ============================================================
% Spearman rank correlation (unconditional)
%% ============================================================
rho_s = zeros(6,1); p_s = zeros(6,1);
for i = 1:6
    [rho_s(i),p_s(i)] = corr(P(:,i),R,'Type','Spearman');
end
disp(' ')
disp('Spearman rank correlation')
disp(table(names,rho_s,p_s,'VariableNames',{'Parameter','Spearman','pValue'}))

%% ============================================================
% PRCC (partial rank correlation coefficient)
%   Rank-transform inputs and output, regress each input and the
%   output on the remaining inputs, then correlate the residuals.
%% ============================================================
Rr = tiedrank(R);
Pr = zeros(size(P));
for j = 1:6
    Pr(:,j) = tiedrank(P(:,j));
end
Z0   = [ones(N,1) Pr];          % design with intercept + all ranked inputs
prcc = zeros(6,1); p_pr = zeros(6,1);
for i = 1:6
    others = [1, setdiff(2:7, i+1)];   % intercept + all columns except input i
    Z = Z0(:,others);
    ri = Pr(:,i) - Z*(Z\Pr(:,i));       % residual of input i
    rr = Rr      - Z*(Z\Rr);            % residual of output
    [prcc(i),p_pr(i)] = corr(ri,rr,'Type','Pearson');
end
disp(' ')
disp('PRCC results')
disp(table(names,prcc,p_pr,'VariableNames',{'Parameter','PRCC','pValue'}))

%% ============================================================
% Side-by-side comparison:  Analytical vs PRCC
%% ============================================================
figure('Color','w','Position',[200 150 900 500])
Y = [Sens prcc];
bar(Y,'grouped','LineWidth',1.5)
grid on; box on
set(gca,'FontSize',30,'FontName','Times')
xticklabels({'\alpha','c','\beta','\delta','\gamma','\mu'})
ylabel('Sensitivity measure','FontSize',30)
legend({'Analytical','PRCC'},'Location','southoutside',...
       'Orientation','horizontal','FontSize',14)
% title('Comparison of Analytical Sensitivity and PRCC','FontSize',30)
ylim([-1.1 1.1])

exportgraphics(gcf,'Fig_Sensitivity_PRCC.pdf','ContentType','vector')
exportgraphics(gcf,'Fig_Sensitivity_PRCC.png','Resolution',600)

disp(' ')
disp('Figure saved.')