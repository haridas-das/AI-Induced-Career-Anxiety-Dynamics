%% =========================================================================
%  AKM Model — Theoretical Estimates + Equilibrium Test 
%  =========================================================================
%  Reference:
%    Islam, S., et al. (2026). Data in Brief. DOI:10.1016/j.dib.2026.112924
%
%  ROOT CAUSES OF PREVIOUS BAD FIGURES — fixed here:
%
%    The parameter c = 0.75 is a FRACTION (proportion of population).
%    The ODE uses  dA/dt = alpha*A*(1 - A/c).
%    If A is passed as a COUNT (e.g. A0 = 2095), then A/c = 2095/0.75 = 2793,
%    so (1 - A/c) = -2792 — a massive NEGATIVE value that immediately crushes A.
%    FIX: pass all state variables as PROPORTIONS (fractions of N0), not counts.
%         y0 = [A0/N0; K0/N0; M0/N0] = [0.6638; 0.2684; 0.0678]
%    The ODE, closed-form E*, and all theoretical formulas are then consistent.
%
%  BUG 2 — yline() calls appear in legend as "data1","data2","data3" (Fig 2):
%    FIX: add 'HandleVisibility','off' to every yline() call.
%
%  REQUIRES:  akm_moode.m  in the same folder.
% =========================================================================

clear; clc; close all;

%% ── Output directories ───────────────────────────────────────────────────
outDir_fig = fullfile(pwd, 'result figures', 'fig');
outDir_png = fullfile(pwd, 'result figures', 'png');
if ~exist(outDir_fig,'dir'); mkdir(outDir_fig); end
if ~exist(outDir_png,'dir'); mkdir(outDir_png); end
axS = {'FontSize',26,'LineWidth',2,'FontName','Times'};

%% =========================================================================
%  SECTION 1 — Parameters and Initial Conditions
%% =========================================================================
p.alpha = 0.30;   % logistic anxiety growth rate
p.c     = 0.75;   % carrying capacity  (FRACTION — proportions only)
p.beta  = 0.40;   % A->K peer-learning rate
p.delta = 0.25;   % A->K mentoring rate
p.gamma = 0.20;   % K->M employment-confidence rate
p.mu    = 0.05;   % per-compartment exit rate

N0 = 3156;                        % total respondents
A0_cnt = 2095;  K0_cnt = 847;  M0_cnt = 214;   % counts from Tables 4 & 2

%% ── CRITICAL: initial conditions as PROPORTIONS ──────────────────────────
%  c = 0.75 is a fraction. The logistic term  alpha*A*(1 - A/c)  only makes
%  sense when A is also a fraction (0 <= A <= 1). Feeding counts (A0=2095)
%  gives A/c = 2095/0.75 = 2793, making (1-A/c) hugely negative and
%  collapsing A to zero in the first time step. Always use proportions.
y0 = [A0_cnt/N0;  K0_cnt/N0;  M0_cnt/N0];   % [0.6638; 0.2684; 0.0678]

fprintf('\n  Initial conditions (proportions):\n');
fprintf('    A0 = %.4f  (%.2f%% of N0 = %d students)\n', y0(1), 100*y0(1), A0_cnt);
fprintf('    K0 = %.4f  (%.2f%% of N0 = %d students)\n', y0(2), 100*y0(2), K0_cnt);
fprintf('    M0 = %.4f  (%.2f%% of N0 = %d students)\n', y0(3), 100*y0(3), M0_cnt);
fprintf('    Check 1-A0/c = 1 - %.4f/%.2f = %+.4f  ', y0(1), p.c, 1-y0(1)/p.c);
if (1-y0(1)/p.c) > 0
    fprintf('[positive ✓ — logistic growth acts correctly]\n\n');
else
    fprintf('[NEGATIVE ✗ — units mismatch!]\n\n');
end

opts   = odeset('RelTol',1e-8,'AbsTol',1e-10,'MaxStep',0.01);
tshort = [0, 10];
tlong  = [0, 150];

%% =========================================================================
%  SECTION 2 — Theoretical Estimates (closed-form)
%% =========================================================================

%% ── Fixed points ─────────────────────────────────────────────────────────
f0 = p.c*(1 - p.mu/p.alpha);
fprintf('\n  Fixed points:\n');
fprintf('    E0 = (0, 0, 0)\n');
fprintf('    E1 = (f0, 0, 0)  f0 = c*(1-mu/alpha) = %.6f\n', f0);

%% ── Reproduction numbers ─────────────────────────────────────────────────
Ra  = p.alpha / p.mu;
R0  = (p.beta*p.mu + p.delta*p.gamma) / (p.mu*(p.gamma+p.mu));
Phi = p.beta + p.delta*p.gamma/p.mu;

fprintf('\n  Reproduction numbers:\n');
fprintf('    Ra  = alpha/mu                              = %.4f\n', Ra);
fprintf('    R0  = (beta*mu+delta*gamma)/[mu*(gamma+mu)] = %.4f\n', R0);
fprintf('    Phi = beta + delta*gamma/mu                 = %.4f\n', Phi);

%% ── Existence conditions ─────────────────────────────────────────────────
C1_lhs = p.alpha*(p.gamma+p.mu);  C1_rhs = p.mu*Phi;
C2_lhs = Phi;                     C2_rhs = p.gamma+p.mu;
C1_ok  = C1_lhs > C1_rhs;
C2_ok  = C2_lhs > C2_rhs;
E_exists = C1_ok && C2_ok;

fprintf('\n  Existence conditions for E*:\n');
fprintf('    C1 [A*>0]: %.5f > %.5f  =>  %s\n', C1_lhs, C1_rhs, ok_str(C1_ok));
fprintf('    C2 [K*,M*>0]: %.5f > %.5f  =>  %s\n', C2_lhs, C2_rhs, ok_str(C2_ok));
fprintf('    => E* exists: %s\n', ok_str(E_exists));

%% ── Closed-form E* (all in proportions, consistent with y0) ─────────────
%common  = p.c*(1 - p.mu*Phi/(p.alpha*(p.gamma+p.mu)));
R0  = (p.beta*p.mu + p.delta*p.gamma) / (p.mu*(p.gamma+p.mu));
Astar   =  p.c*(1 - p.mu/p.alpha*R0)
Kstar   = (p.c*p.mu/(p.gamma+p.mu))*(R0-1)*(1 - p.mu*R0/p.alpha);
Mstar   = (p.c*p.gamma/(p.gamma+p.mu))*(R0-1)*(1 - p.mu*R0/p.alpha);
Nstar   = p.c*R0 * (1 - p.mu*R0/p.alpha)


% As percentages (for plotting and printing)
Ap = 100*Astar;  Kp = 100*Kstar;  Mp = 100*Mstar;

fprintf('\n  Closed-form E* (proportions of N0):\n');
fprintf('    A* = %.6f  =>  %.2f%%  (%.0f students)\n', Astar, Ap, Astar*N0);
fprintf('    K* = %.6f  =>  %.2f%%  (%.0f students)\n', Kstar, Kp, Kstar*N0);
fprintf('    M* = %.6f  =>  %.2f%%  (%.0f students)\n', Mstar, Mp, Mstar*N0);
fprintf('    N* = %.6f  (active population fraction)\n', Nstar);

%% ── Jacobian at E0 ───────────────────────────────────────────────────────
lam1 = p.alpha-p.mu;  lam2 = -(p.gamma+p.mu);  lam3 = -p.mu;
fprintf('\n  Jacobian eigenvalues at E0:\n');
fprintf('    lambda1 = alpha-mu    = %+.4f  ', lam1);
if lam1<0; fprintf('[<0 stable]\n'); else; fprintf('[>0 UNSTABLE]\n'); end
fprintf('    lambda2 = -(gamma+mu) = %+.4f  [<0 always]\n', lam2);
fprintf('    lambda3 = -mu         = %+.4f  [<0 always]\n', lam3);

%% ── Routh-Hurwitz at E1 ──────────────────────────────────────────────────
lam1_E1 = -(p.alpha-p.mu);
c1_E1   =  p.gamma+2*p.mu-p.beta;
c2_E1   =  p.mu*(p.gamma+p.mu-p.beta)-p.delta*p.gamma;
fprintf('\n  Routh-Hurwitz at E1:\n');
fprintf('    lambda1 = -(alpha-mu)       = %+.4f  %s\n', lam1_E1, rh(lam1_E1<0,'alpha>mu'));
fprintf('    c1 = gamma+2mu-beta         = %+.4f  %s\n', c1_E1,   rh(c1_E1>0,'beta<gamma+2mu'));
fprintf('    c2 = mu*(gamma+mu-beta)-... = %+.4f  %s\n', c2_E1,   rh(c2_E1>0,'beta<...'));

%% =========================================================================
%  SECTION 3 — Numerical Equilibrium Test with tlong simulation 
%% =========================================================================

[~, Yl] = ode45(@(t,y) akm_moode(t,y,p), tlong, y0, opts);
Aeq=Yl(end,1); Keq=Yl(end,2); Meq=Yl(end,3);

fprintf('\n  Numerical E* (T=300 yr):\n');
fprintf('    A* = %.6f  =>  %.2f%%  (%.0f students)\n', Aeq, 100*Aeq, Aeq*N0);
fprintf('    K* = %.6f  =>  %.2f%%  (%.0f students)\n', Keq, 100*Keq, Keq*N0);
fprintf('    M* = %.6f  =>  %.2f%%  (%.0f students)\n', Meq, 100*Meq, Meq*N0);

%% ── Comparison table ─────────────────────────────────────────────────────
fprintf('\n  Theory vs Numerics:\n');
fprintf('  %-6s %14s %14s %14s\n','','Theory (%%N0)','Num (%%N0)','|Error|');
fprintf('  %s\n',repmat('-',1,50));
th_v = [Ap, Kp, Mp];
nm_v = [100*Aeq, 100*Keq, 100*Meq];
lb   = {'A*','K*','M*'};
for i=1:3
    fprintf('  %-6s %14.4f %14.4f %14.2e\n', lb{i}, th_v(i), nm_v(i), abs(th_v(i)-nm_v(i)));
end
fprintf('\n  Max error = %.2e%%  ', max(abs(th_v-nm_v)));
if max(abs(th_v-nm_v)) < 0.01
    fprintf('=> EXCELLENT agreement\n');
elseif max(abs(th_v-nm_v)) < 0.1
    fprintf('=> GOOD agreement\n');
else
    fprintf('=> WARNING: increase T or check parameters\n');
end

%% ── Verify residuals ─────────────────────────────────────────────────────
res = akm_moode(0, [Aeq; Keq; Meq], p);
fprintf('\n  ODE residuals at numerical E*:\n');
fprintf('    |dA/dt|=%.2e   |dK/dt|=%.2e   |dM/dt|=%.2e\n',...
        abs(res(1)),abs(res(2)),abs(res(3)));
if max(abs(res)) < 1e-6
    fprintf('    => All < 1e-6: confirmed equilibrium ✓\n');
end

%% =========================================================================
%  FIGURE 1 — Baseline trajectory + theoretical asymptotes
%% =========================================================================
[ts, Ys] = ode45(@(t,y) akm_moode(t,y,p), tshort, y0, opts);

h1=figure('Name','Fig1: Baseline + Theory','Position',[60 60 1200 700]);
hold on;
plot(ts, 100*Ys(:,1),'r-','LineWidth',3,'DisplayName','Career anxiety (A(t))');
plot(ts, 100*Ys(:,2),'b-','LineWidth',3,'DisplayName','AI-Knowledgeable (K(t))');
plot(ts, 100*Ys(:,3),'g-','LineWidth',3,'DisplayName','Job-market confidence (M(t))');

% Asymptotes — HandleVisibility off so they don't pollute the legend
yline(Ap,'r--','LineWidth',2,'HandleVisibility','off',...
      'Label',sprintf('A^* = %.2f%%',Ap),...
      'LabelHorizontalAlignment','left','LabelVerticalAlignment','top','FontSize',18,'FontName','Times');
yline(Kp,'b--','LineWidth',2,'HandleVisibility','off',...
      'Label',sprintf('K^* = %.2f%%',Kp),...
      'LabelHorizontalAlignment','left','LabelVerticalAlignment','bottom','FontSize',18,'FontName','Times');
yline(Mp,'g--','LineWidth',2,'HandleVisibility','off',...
      'Label',sprintf('M^* = %.2f%%',Mp),...
      'LabelHorizontalAlignment','left','LabelVerticalAlignment','top','FontSize',18,'FontName','Times');

% End-of-line values
text(tshort(2)+0.1, 100*Ys(end,1), sprintf('%.1f%%',100*Ys(end,1)),...
     'Color','r','FontSize',20,'FontWeight','bold','FontName','Times','VerticalAlignment','middle');
text(tshort(2)+0.1, 100*Ys(end,2), sprintf('%.1f%%',100*Ys(end,2)),...
     'Color','b','FontSize',20,'FontWeight','bold','FontName','Times','VerticalAlignment','middle');
text(tshort(2)+0.1, 100*Ys(end,3), sprintf('%.1f%%',100*Ys(end,3)),...
     'Color','g','FontSize',20,'FontWeight','bold','FontName','Times','VerticalAlignment','middle');

xlabel('Time (years)','FontSize',26,'FontName','Times');
ylabel('% of N_0','FontSize',26,'FontName','Times');
% title({sprintf('Baseline AKM  |  R_0 = %.3f,  R_a = %.1f,  \\Phi = %.3f', R0, Ra, Phi),...
%        'Solid = numerical (t = 0\rightarrow10)  |  Dashed = theoretical E^*'},...
%       'FontSize',20,'FontName','Times');
legend('Location','best','FontSize',30,'FontName','Times'); % east
xlim([0, tshort(2)+1.2]); ylim([0,100]);
set(gca,axS{:}); box on;
saveas(h1,fullfile(outDir_fig,'Fig1_baseline_theory.fig'));
print(h1,fullfile(outDir_png,'Fig1_baseline_theory.png'),'-dpng','-r300');
fprintf('\n  Saved: Fig1_baseline_theory\n');

%% =========================================================================
%  FIGURE 2 — Convergence to E* on log-time axis
%% =========================================================================
t_check = [0.5, 1, 2, 5, 10, 30, 100, 300];
nT = numel(t_check);
Ac = zeros(1,nT); Kc = zeros(1,nT); Mc = zeros(1,nT);
for i = 1:nT
    [~,Yc] = ode45(@(t,y) akm_moode(t,y,p),[0 t_check(i)],y0,opts);
    Ac(i)=100*Yc(end,1); Kc(i)=100*Yc(end,2); Mc(i)=100*Yc(end,3);
end

h2 = figure('Name','Fig2: Convergence to E*','Position',[80 80 1200 700]);
hold on;
plot(t_check, Ac,'ro-','LineWidth',2.5,'MarkerSize',12,...
     'MarkerFaceColor','r','DisplayName','A(t)');
plot(t_check, Kc,'bs-','LineWidth',2.5,'MarkerSize',12,...
     'MarkerFaceColor','b','DisplayName','K(t)');
plot(t_check, Mc,'g^-','LineWidth',2.5,'MarkerSize',12,...
     'MarkerFaceColor','g','DisplayName','M(t)');

% Asymptotes — HandleVisibility off (BUG 2 fix)
% yline(Ap,'r--','LineWidth',2,'HandleVisibility','off',...
%       'Label',sprintf('A^*=%.2f%%',Ap),...
%       'LabelHorizontalAlignment','right','FontSize',18,'FontName','Times');
% yline(Kp,'b--','LineWidth',2,'HandleVisibility','off',...
%       'Label',sprintf('K^*=%.2f%%',Kp),...
%       'LabelHorizontalAlignment','right','FontSize',18,'FontName','Times');

yline(Ap,'r--','LineWidth',2,'HandleVisibility','off',...
      'Label',sprintf('A^* = %.2f%%', Ap),...
      'LabelHorizontalAlignment','right',...
      'LabelVerticalAlignment','top',...
      'FontSize',20,'FontName','Times','FontWeight','bold');
yline(Kp,'b--','LineWidth',2,'HandleVisibility','off',...
      'Label',sprintf('K^* = %.2f%%', Kp),...
      'LabelHorizontalAlignment','right',...
      'LabelVerticalAlignment','bottom',...
      'FontSize',20,'FontName','Times','FontWeight','bold');

yline(Mp,'g--','LineWidth',2,'HandleVisibility','off',...
      'Label',sprintf('M^*=%.2f%%',Mp),...
      'LabelHorizontalAlignment','right','FontSize',20,'FontName','Times');

set(gca,'XScale','log',axS{:});
xlabel('Time (years, log scale)','FontSize',30,'FontName','Times');
ylabel('% of N_0','FontSize',30,'FontName','Times');
% title({'Convergence of Numerical Solution to Theoretical E^*',...
%        'Dashed lines: closed-form E^* (A^*, K^*, M^*)'},...
%       'FontSize',20,'FontName','Times');
legend('Location','best','FontSize',30,'FontName','Times');
ylim([0,100]); box on;
saveas(h2,fullfile(outDir_fig,'Fig2_convergence.fig'));
print(h2,fullfile(outDir_png,'Fig2_convergence.png'),'-dpng','-r300');
fprintf('  Saved: Fig2_convergence\n');

 
%% =========================================================================
%  FIGURE 3 — Theory vs Numerics as alpha varies  (A*, K*, M* each separate)
%% =========================================================================
alpha_vec = linspace(0.06, 1.0, 50);
Ath_A = zeros(size(alpha_vec));   Anum_A = zeros(size(alpha_vec));
Ath_K = zeros(size(alpha_vec));   Anum_K = zeros(size(alpha_vec));
Ath_M = zeros(size(alpha_vec));   Anum_M = zeros(size(alpha_vec));
 
% for i = 1:numel(alpha_vec)
%     qi       = p;
%     qi.alpha = alpha_vec(i);
%     Phi_i    = qi.beta + qi.delta*qi.gamma/qi.mu;
%     R0_i     = (qi.beta*qi.mu + qi.delta*qi.gamma)/(qi.mu*(qi.gamma+qi.mu));
%     C1_i     = qi.alpha*(qi.gamma+qi.mu) > qi.mu*Phi_i;
%     C2_i     = Phi_i > (qi.gamma+qi.mu);
%     if C1_i && C2_i
%         cm_i     = qi.c*(1 - qi.mu*Phi_i/(qi.alpha*(qi.gamma+qi.mu)));
%         Ath_A(i) = 100*cm_i;
%         Ath_K(i) = 100*(qi.c*qi.mu/(qi.gamma+qi.mu))*(1-qi.mu*R0_i/qi.alpha)*(R0_i-1);
%         Ath_M(i) = 100*(qi.c*qi.gamma/(qi.gamma+qi.mu))*(1-qi.mu*R0_i/qi.alpha)*(R0_i-1);
%     end
%     [~,Yqi]  = ode45(@(t,y) akm_moode(t,y,qi), tlong, y0, opts);
%     Anum_A(i) = 100*Yqi(end,1);
%     Anum_K(i) = 100*Yqi(end,2);
%     Anum_M(i) = 100*Yqi(end,3);
% end
 
for i = 1:numel(alpha_vec)
    qi       = p;
    qi.alpha = alpha_vec(i);

    R0_i = (qi.beta*qi.mu + qi.delta*qi.gamma) / (qi.mu*(qi.gamma+qi.mu));

    C1_i = R0_i < qi.alpha/qi.mu;
    C2_i = R0_i > 1;

    if C1_i && C2_i
        exists_vec(i) = true;
        Ath_A(i) = 100 * qi.c*(1 - qi.mu*R0_i/qi.alpha);
        Ath_K(i) = 100 * qi.c*qi.mu*(R0_i-1)/(qi.gamma+qi.mu) * (1 - qi.mu*R0_i/qi.alpha);
        Ath_M(i) = 100 * qi.c*qi.gamma*(R0_i-1)/(qi.gamma+qi.mu) * (1 - qi.mu*R0_i/qi.alpha);
        Ath_N(i) = 100 * qi.c*R0_i * (1 - qi.mu*R0_i/qi.alpha);
    end

    [~,Yqi]   = ode45(@(t,y) akm_moode(t,y,qi), tlong, y0, opts);
    Anum_A(i) = 100*Yqi(end,1);
    Anum_K(i) = 100*Yqi(end,2);
    Anum_M(i) = 100*Yqi(end,3);
    Anum_N(i) = 100*sum(Yqi(end,:));
end

%% ── Fig 3a: A* vs alpha ──────────────────────────────────────────────────
h3a = figure('Name','Fig3a: A* theory vs numeric','Position',[100 100 1100 650]);
hold on;
plot(alpha_vec, Ath_A,  'r-', 'LineWidth',2.5,  'DisplayName','A^* theoretical');
plot(alpha_vec, Anum_A, 'r--','LineWidth',6, 'DisplayName','A^* numerical');
xline(p.mu,   'k:','LineWidth',2,'HandleVisibility','off',...
      'Label','\alpha=\mu','LabelHorizontalAlignment','right',...
      'LabelVerticalAlignment','top','FontSize',18,'FontName','Times');
xline(p.alpha,'k--','LineWidth',1.5,'HandleVisibility','off',...
      'Label','Baseline','LabelHorizontalAlignment','right',...
      'LabelVerticalAlignment','bottom','FontSize',18,'FontName','Times');
xlabel('\alpha  (anxiety growth rate)','FontSize',26,'FontName','Times');
ylabel('A^*  (% of N_0)','FontSize',26,'FontName','Times');
legend('Location','best','FontSize',20,'FontName','Times');
ylim([0,100]); set(gca,axS{:}); box on;
xlim([0 1]);
saveas(h3a,fullfile(outDir_fig,'Fig3a_Astar_alpha_sweep.fig'));
print(h3a,fullfile(outDir_png,'Fig3a_Astar_alpha_sweep.png'),'-dpng','-r300');
fprintf('  Saved: Fig3a_Astar_alpha_sweep\n');
 
%% ── Fig 3b: K* vs alpha ──────────────────────────────────────────────────
h3b = figure('Name','Fig3b: K* theory vs numeric','Position',[120 120 1100 650]);
hold on;
plot(alpha_vec, Ath_K,  'b-', 'LineWidth',2.5,  'DisplayName','K^* theoretical');
plot(alpha_vec, Anum_K, 'b--','LineWidth',6, 'DisplayName','K^* numerical');
xline(p.mu,   'k:','LineWidth',2,'HandleVisibility','off',...
      'Label','\alpha=\mu','LabelHorizontalAlignment','right',...
      'LabelVerticalAlignment','top','FontSize',18,'FontName','Times');
xline(p.alpha,'k--','LineWidth',1.5,'HandleVisibility','off',...
      'Label','Baseline','LabelHorizontalAlignment','right',...
      'LabelVerticalAlignment','bottom','FontSize',18,'FontName','Times');
xlabel('\alpha  (anxiety growth rate)','FontSize',26,'FontName','Times');
ylabel('K^*  (% of N_0)','FontSize',26,'FontName','Times');
legend('Location','best','FontSize',20,'FontName','Times');
ylim([0,100]); set(gca,axS{:}); box on;
xlim([0 1]);
saveas(h3b,fullfile(outDir_fig,'Fig3b_Kstar_alpha_sweep.fig'));
print(h3b,fullfile(outDir_png,'Fig3b_Kstar_alpha_sweep.png'),'-dpng','-r300');
fprintf('  Saved: Fig3b_Kstar_alpha_sweep\n');
 
%% ── Fig 3c: M* vs alpha ──────────────────────────────────────────────────
h3c = figure('Name','Fig3c: M* theory vs numeric','Position',[140 140 1100 650]);
hold on;
plot(alpha_vec, Ath_M,  'g-', 'LineWidth',2.5,  'DisplayName','M^* theoretical');
plot(alpha_vec, Anum_M, 'g--','LineWidth',6, 'DisplayName','M^* numerical');
xline(p.mu,   'k:','LineWidth',2,'HandleVisibility','off',...
      'Label','\alpha=\mu','LabelHorizontalAlignment','right',...
      'LabelVerticalAlignment','top','FontSize',18,'FontName','Times');
xline(p.alpha,'k--','LineWidth',1.5,'HandleVisibility','off',...
      'Label','Baseline','LabelHorizontalAlignment','right',...
      'LabelVerticalAlignment','bottom','FontSize',18,'FontName','Times');
xlabel('\alpha  (anxiety growth rate)','FontSize',26,'FontName','Times');
ylabel('M^*  (% of N_0)','FontSize',26,'FontName','Times');
legend('Location','best','FontSize',20,'FontName','Times');
ylim([0,100]); set(gca,axS{:}); box on;
xlim([0 1]);
saveas(h3c,fullfile(outDir_fig,'Fig3c_Mstar_alpha_sweep.fig'));
print(h3c,fullfile(outDir_png,'Fig3c_Mstar_alpha_sweep.png'),'-dpng','-r300');
fprintf('  Saved: Fig3c_Mstar_alpha_sweep\n');
 
%% ── Fig 3d: All three on one axes ────────────────────────────────────────
h3d = figure('Name','Fig3d: All compartments theory vs numeric','Position',[160 160 1200 700]);
hold on;
% Theoretical (solid)
plot(alpha_vec, Ath_A, 'r-', 'LineWidth',3,   'DisplayName','A^* theory');
plot(alpha_vec, Ath_K, 'b-', 'LineWidth',3,   'DisplayName','K^* theory');
plot(alpha_vec, Ath_M, 'g-', 'LineWidth',3,   'DisplayName','M^* theory');
% Numerical (dashed, same colour)
plot(alpha_vec, Anum_A,'r--','LineWidth',6,    'DisplayName','A^* numerical');
plot(alpha_vec, Anum_K,'b--','LineWidth',6,    'DisplayName','K^* numerical');
plot(alpha_vec, Anum_M,'g--','LineWidth',6,    'DisplayName','M^* numerical');
% Boundary markers
xline(p.mu,   'k:','LineWidth',2,'HandleVisibility','off',...
      'Label','\alpha=\mu','LabelHorizontalAlignment','right',...
      'LabelVerticalAlignment','top','FontSize',30,'FontName','Times');
xline(p.alpha,'k--','LineWidth',1.5,'HandleVisibility','off',...
      'Label','Baseline \alpha','LabelHorizontalAlignment','right',...
      'LabelVerticalAlignment','top','FontSize',30,'FontName','Times');
xlabel('\alpha  (anxiety growth rate)','FontSize',30,'FontName','Times');
ylabel('Equilibrium compartment (% of N_0)','FontSize',26,'FontName','Times');
legend('Location','best','FontSize',30,'FontName','Times','NumColumns',2);
ylim([0,100]); set(gca,axS{:}); box on;
xlim([0 1]);
saveas(h3d,fullfile(outDir_fig,'Fig3d_all_compartments_alpha_sweep.fig'));
print(h3d,fullfile(outDir_png,'Fig3d_all_compartments_alpha_sweep.png'),'-dpng','-r300');
fprintf('  Saved: Fig3d_all_compartments_alpha_sweep\n');
 
%% =========================================================================
%  FINAL SUMMARY
%% =========================================================================
fprintf('\n');
disp('╔══════════════════════════════════════════════════════════════════╗');
disp('║   FINAL SUMMARY                                                  ║');
disp('╠══════════════════════════════════════════════════════════════════╣');
fprintf('  Parameters:  alpha=%.2f  c=%.2f  beta=%.2f  delta=%.2f  gamma=%.2f  mu=%.3f\n',...
        p.alpha,p.c,p.beta,p.delta,p.gamma,p.mu);
fprintf('  Ra=%.2f   R0=%.4f   Phi=%.4f\n', Ra, R0, Phi);
fprintf('\n  %-10s %12s %12s %12s\n','','A* (%%N0)','K* (%%N0)','M* (%%N0)');
fprintf('  %-10s %12.4f %12.4f %12.4f\n','Theory', Ap,     Kp,     Mp);
fprintf('  %-10s %12.4f %12.4f %12.4f\n','Numeric',100*Aeq,100*Keq,100*Meq);
fprintf('  %-10s %12.2e %12.2e %12.2e\n','|Error|',...
        abs(Ap-100*Aeq),abs(Kp-100*Keq),abs(Mp-100*Meq));
disp('╚══════════════════════════════════════════════════════════════════╝');
 
%% =========================================================================
%  LOCAL HELPER FUNCTIONS
%% =========================================================================
function s = ok_str(v)
    if v; s='SATISFIED ✓'; else; s='NOT satisfied ✗'; end
end
 
function s = rh(v, cond)
    if v; s=sprintf('[>0, %s ✓]',cond); else; s=sprintf('[≤0, %s VIOLATED ✗]',cond); end
end
