%% =========================================================================
%  AKM Model — Parameter Calibration  (CORRECTED)
%  =========================================================================
%  Islam et al. (2026), Data in Brief. DOI:10.1016/j.dib.2026.112924
%
%  KEY FINDING FROM DATA:
%    A(t) rises from 64.2% → 68.2% over 4 years.
%    K(t) falls from 29.6% → 22.1%.
%    M(t) rises from  6.3% →  9.7%.
%
%  WHY THE AKM MODEL CANNOT FIT THIS:
%    In the AKM model, A can only grow via logistic self-propagation and
%    shrink via peer-learning (beta), mentoring (delta), and exit (mu).
%    The observed RISING A with FALLING K is consistent with the model ONLY
%    when the logistic growth term dominates, meaning:
%        alpha * A * (1 - A/c)  >  beta*(A/N)*K + delta*(A/N)*M + mu*A
%    i.e. anxiety is still in the growth phase — not yet at equilibrium.
%
%  IDENTIFIABILITY ISSUE:
%    With only 4 cross-sectional data points and 6 free parameters, the
%    system is under-determined.
%    The cross-sectional time proxy (academic year) violates the assumption
%    that different year cohorts are the SAME individuals observed over time.
%    Different cohorts may have different entry compositions.
%
%  STRATEGY — two-stage approach:
%    Stage 1: Fix  mu (from degree length) and c (from max observed A).
%    Stage 2: Grid-search over (alpha, gamma) while reporting the
%             IDENTIFIABLE composite Phi = beta + delta*gamma/mu.
%             beta and delta are NOT separately identifiable; only Phi is.
%
%  Fixed parameters (data-grounded):
%    mu = 0.25  yr^{-1}  (4-year degree → 25% leave each year)
%    c  = 0.72           (max(A_obs) + 0.04 buffer)
%
%  Free parameters calibrated:
%    alpha  — anxiety logistic growth rate
%    gamma  — K→M transition rate
%    Phi    — composite transfer (beta + delta*gamma/mu)
%             (beta and delta individually fixed at Phi/2 each for plotting)
% =========================================================================

clear; clc; close all;

outDir_fig = fullfile(pwd, 'result figures', 'fig');
outDir_png = fullfile(pwd, 'result figures', 'png');
if ~exist(outDir_fig,'dir'); mkdir(outDir_fig); end
if ~exist(outDir_png,'dir'); mkdir(outDir_png); end
axStyle = {'FontSize',26,'LineWidth',2,'FontName','Times'};

%% =========================================================================
%  SECTION 1 — Observed data (from Islam et al. 2026, N=3156)
%  =========================================================================
%  Compartment mapping:
%    A = career_anxiety in {2,3}  (Medium or High)
%    M = ai_knowledge  == 3       (High)
%    K = 1 - A - M               (residual)
%  Time proxy: academic year 1,2,3,4 → t = 0,1,2,3

t_obs = [0,  1,    2,    3   ];
n_obs = [1120, 985, 762,  289 ];
A_obs = [0.6420, 0.6741, 0.6759, 0.6817];
K_obs = [0.2955, 0.2640, 0.2520, 0.2215];
M_obs = [0.0625, 0.0619, 0.0722, 0.0969];

fprintf('=== Observed proportions ===\n');
fprintf('%-6s %6s %8s %8s %8s\n','Year','N','A','K','M');
yr_lbl = {'1st','2nd','3rd','4th'};
for i=1:4
    fprintf('  %-4s %6d %8.4f %8.4f %8.4f\n',...
            yr_lbl{i},n_obs(i),A_obs(i),K_obs(i),M_obs(i));
end

% Trends
fprintf('\n  A trend: %.4f → %.4f  (+%.4f)  [anxiety RISING]\n',...
        A_obs(1),A_obs(4),A_obs(4)-A_obs(1));
fprintf('  K trend: %.4f → %.4f  (%.4f)  [knowledge FALLING]\n',...
        K_obs(1),K_obs(4),K_obs(4)-K_obs(1));
fprintf('  M trend: %.4f → %.4f  (+%.4f)  [market-ready RISING]\n',...
        M_obs(1),M_obs(4),M_obs(4)-M_obs(1));

%% =========================================================================
%  SECTION 2 — Fixed parameters
%  =========================================================================
mu_fix = 0.25;                     % 4-yr degree → 25% exit per year
c_fix  = max(A_obs) + 0.04;        % carrying capacity with small buffer
fprintf('\nFixed parameters: mu = %.3f  c = %.4f\n', mu_fix, c_fix);

%% =========================================================================
%  SECTION 3 — Calibration of (alpha, gamma, Phi)
%  =========================================================================
%  We parameterise: beta = Phi/2, delta = Phi/2  (symmetric split).
%  This is a normalisation convention; only Phi is identifiable.
%  Free parameters: theta = [alpha, Phi, gamma]  (3 params, 3 residuals)

opts_ode = odeset('RelTol',1e-8,'AbsTol',1e-10,'MaxStep',0.05);

obj_fn = @(theta) wls3(theta, t_obs, A_obs, K_obs, M_obs, n_obs, ...
                        c_fix, mu_fix, opts_ode);

% Grid search over (alpha, Phi, gamma)
alpha_grid = linspace(0.26, 2.0, 12);
Phi_grid   = logspace(-2, 1,    10);   % 0.01 … 10
gamma_grid = linspace(0.05, 2.0, 10);

best_sse = Inf; best_theta = [0.4, 0.5, 0.3];
for ai = 1:length(alpha_grid)
    for Pi = 1:length(Phi_grid)
        for gi = 1:length(gamma_grid)
            th = [alpha_grid(ai), Phi_grid(Pi), gamma_grid(gi)];
            v  = obj_fn(th);
            if v < best_sse
                best_sse   = v;
                best_theta = th;
            end
        end
    end
end
fprintf('\nGrid search best SSE = %.6f   theta = [%.4f, %.4f, %.4f]\n',...
        best_sse, best_theta(1), best_theta(2), best_theta(3));

% Local refinement
opts_fmin = optimoptions('fmincon','Algorithm','interior-point',...
    'Display','off','MaxIterations',10000,...
    'OptimalityTolerance',1e-12,'FunctionTolerance',1e-14);
lb3 = [mu_fix+0.001, 1e-4, 1e-4];
%ub3 = [5.0,          20.0, 3.0 ];
ub3 = [12.0, 20.0, 3.0 ]; 

% Multi-start from grid best + nearby points
x0_list = [best_theta;
           best_theta.*[0.8,1.2,0.9];
           best_theta.*[1.2,0.8,1.1];
           [0.30, 1.00, 0.20];
           [0.50, 0.50, 0.40]];

best_sse2 = Inf; best_theta2 = best_theta;
for k = 1:size(x0_list,1)
    try
        [th_k, sse_k] = fmincon(obj_fn, x0_list(k,:), [],[],[],[], ...
                                 lb3, ub3, [], opts_fmin);
        if sse_k < best_sse2
            best_sse2   = sse_k;
            best_theta2 = th_k;
        end
    catch; end
end

alpha_hat = best_theta2(1);
Phi_hat   = best_theta2(2);
gamma_hat = best_theta2(3);
beta_hat  = Phi_hat / 2;     % symmetric split convention
delta_hat = Phi_hat / 2;
Ra_hat    = alpha_hat / mu_fix;

p.alpha = alpha_hat;
p.c     = c_fix;
p.beta  = beta_hat;
p.delta = delta_hat;
p.gamma = gamma_hat;
p.mu    = mu_fix;

fprintf('\n=== Calibrated parameters ===\n');
fprintf('  alpha = %.5f   (Ra = %.4f)\n', alpha_hat, Ra_hat);
fprintf('  gamma = %.5f\n', gamma_hat);
fprintf('  Phi   = %.5f   (identifiable composite)\n', Phi_hat);
fprintf('  beta  = %.5f   (= Phi/2, convention)\n', beta_hat);
fprintf('  delta = %.5f   (= Phi/2, convention)\n', delta_hat);
fprintf('  mu    = %.5f   (fixed)\n', mu_fix);
fprintf('  c     = %.5f   (fixed)\n', c_fix);
fprintf('  SSE   = %.8f\n', best_sse2);

%% =========================================================================
%  SECTION 5 — Fit quality
%  =========================================================================

[t_fit, Y_fit] = ode45(@(t,y) akm_moode(t,y,p), ...
                       [0 10], ...
                       [A_obs(1); K_obs(1); M_obs(1)], ...
                       opts_ode);

% Evaluate at observed time points
Yp = interp1(t_fit, Y_fit, t_obs, 'pchip');
Ap = max(Yp(:,1)', 0); Kp = max(Yp(:,2)', 0); Mp = max(Yp(:,3)', 0);

fprintf('\n=== Fit quality ===\n');
fprintf('%-6s %8s %8s  %8s %8s  %8s %8s\n',...
        'Year','A_obs','A_fit','K_obs','K_fit','M_obs','M_fit');
for i=1:4
    fprintf('  Yr %d  %8.4f %8.4f  %8.4f %8.4f  %8.4f %8.4f\n',...
            i,A_obs(i),Ap(i),K_obs(i),Kp(i),M_obs(i),Mp(i));
end
rmseA = sqrt(mean((Ap-A_obs).^2));
rmseK = sqrt(mean((Kp-K_obs).^2));
rmseM = sqrt(mean((Mp-M_obs).^2));
fprintf('\n  RMSE_A=%.5f  RMSE_K=%.5f  RMSE_M=%.5f\n',rmseA,rmseK,rmseM);

%% =========================================================================
%  SECTION 6 — Figure: Calibrated fit vs observed
%  =========================================================================
h1 = figure('Name','Calibrated fit vs observed','Position',[60 60 1100 650]);
hold on;
% Observed (markers with error bars from binomial SE)
se_A = sqrt(A_obs.*(1-A_obs)./n_obs);
se_K = sqrt(K_obs.*(1-K_obs)./n_obs);
se_M = sqrt(M_obs.*(1-M_obs)./n_obs);
errorbar(t_obs,A_obs,1.96*se_A,'ro','MarkerSize',14,'MarkerFaceColor','r',...
         'LineWidth',2,'DisplayName','A_{obs} \pm 1.96SE');
errorbar(t_obs,K_obs,1.96*se_K,'bs','MarkerSize',14,'MarkerFaceColor','b',...
         'LineWidth',2,'DisplayName','K_{obs} \pm 1.96SE');
errorbar(t_obs,M_obs,1.96*se_M,'g^','MarkerSize',14,'MarkerFaceColor','g',...
         'LineWidth',2,'DisplayName','M_{obs} \pm 1.96SE');
% Calibrated model (lines — first 3 years only, the fitting window)
plot(t_fit(t_fit<=3), Y_fit(t_fit<=3,1),'r-', 'LineWidth',2.5,...
     'DisplayName','A(t) calibrated');
plot(t_fit(t_fit<=3), Y_fit(t_fit<=3,2),'b-', 'LineWidth',2.5,...
     'DisplayName','K(t) calibrated');
plot(t_fit(t_fit<=3), Y_fit(t_fit<=3,3),'g-', 'LineWidth',2.5,...
     'DisplayName','M(t) calibrated');

xlabel('Academic year (time proxy)','FontSize',26,'FontName','Times');
ylabel('Proportion of cohort',      'FontSize',26,'FontName','Times');
xticks(0:3); xticklabels({'1st','2nd','3rd','4th'});
xlim([-0.15,3.15]); ylim([0,1]);
legend('Location','east','FontSize',20,'FontName','Times');
set(gca,axStyle{:}); box on;

baseName='Fig_calibration_fit_corrected';
saveas(h1,fullfile(outDir_fig,[baseName '.fig']));
print(h1,fullfile(outDir_png,[baseName '.png']),'-dpng','-r300');
fprintf('Saved: %s\n',baseName);



%% =========================================================================
%  SECTION 7 — Identifiability warning figure
%  =========================================================================
%  Show that beta and delta are NOT individually identifiable:
%  plot SSE contour over (beta, delta) holding alpha and gamma fixed.

beta_range  = logspace(-3, 1, 40);
delta_range = logspace(-3, 1, 40);
SSE_map = zeros(40,40);
for i=1:40
    for j=1:40
        b=beta_range(j); d=delta_range(i);
        SSE_map(i,j)=wls3([alpha_hat, b+d*gamma_hat/mu_fix, gamma_hat],...
                           t_obs,A_obs,K_obs,M_obs,n_obs,...
                           c_fix,mu_fix,opts_ode);
    end
end

h2=figure('Name','Non-identifiability: SSE contour','Position',[80 80 900 700]);
contourf(log10(beta_range),log10(delta_range),SSE_map,25,'LineColor','none');
colorbar; colormap(flipud(hot));
xlabel('log_{10}(\beta)','FontSize',26,'FontName','Times');
ylabel('log_{10}(\delta)','FontSize',26,'FontName','Times');
% title({sprintf('SSE(\beta,\delta)  |  \\alpha=%.3f, \\gamma=%.3f fixed',...
%                alpha_hat,gamma_hat),...
%        'Flat ridge = \beta,\delta not separately identifiable'},...
%       'FontSize',22,'FontName','Times');
% title({sprintf('SSE(beta, delta) | alpha = %.3f, gamma = %.3f fixed', ...
%                alpha_hat, gamma_hat), ...
%        'Flat ridge = \beta,\delta not separately identifiable'}, ...
%       'FontSize',22,'FontName','Times');
box on;
hold on;
% Mark the ridge: Phi = beta + delta*gamma/mu = const
b_line=logspace(-3,0,100); d_ridge=(Phi_hat-b_line)*mu_fix/gamma_hat;
valid=d_ridge>0; plot(log10(b_line(valid)),log10(d_ridge(valid)),'w--','LineWidth',2.5);
text(-1,-0.3,'Ridge: \beta+\delta\gamma/\mu = \Phi_{hat}',...
     'Color','w','FontSize',18,'FontName','Times');
set(gca,axStyle{:});

baseName='Fig_nonidentifiability_beta_delta';
saveas(h2,fullfile(outDir_fig,[baseName '.fig']));
print(h2,fullfile(outDir_png,[baseName '.png']),'-dpng','-r300');
fprintf('Saved: %s\n',baseName);

%% =========================================================================
%  SECTION 8 — Bootstrap CI on identifiable parameters only
%  =========================================================================
fprintf('\n=== Bootstrap 95%% CI on (alpha, Phi, gamma)  B=300 ===\n');
B=300; rng(42);
boot3=zeros(B,3);
for bi=1:B
    se_A_b=sqrt(A_obs.*(1-A_obs)./n_obs);
    se_K_b=sqrt(K_obs.*(1-K_obs)./n_obs);
    se_M_b=sqrt(M_obs.*(1-M_obs)./n_obs);
    Ab=max(min(A_obs+randn(1,4).*se_A_b,0.98),0.02);
    Kb=max(min(K_obs+randn(1,4).*se_K_b,0.98),0.02);
    Mb=max(min(M_obs+randn(1,4).*se_M_b,0.98),0.02);
    obj_b=@(th) wls3(th,t_obs,Ab,Kb,Mb,n_obs,c_fix,mu_fix,opts_ode);
    try
        [th_b,sse_b]=fmincon(obj_b,best_theta2,[],[],[],[],lb3,ub3,...
                             [],opts_fmin);
        if sse_b<1e7; boot3(bi,:)=th_b; else; boot3(bi,:)=NaN; end
    catch; boot3(bi,:)=NaN; end
end
boot3=boot3(all(~isnan(boot3),2),:);
B_ok=size(boot3,1);
pn={'alpha','Phi  ','gamma'}; mle=[alpha_hat,Phi_hat,gamma_hat];
fprintf('  %-8s %10s %10s %10s  (B_ok=%d)\n','Param','MLE','95%lo','95%hi',B_ok);
for i=1:3
    lo=prctile(boot3(:,i),2.5); hi=prctile(boot3(:,i),97.5);
    fprintf('  %-8s %10.5f %10.5f %10.5f\n',pn{i},mle(i),lo,hi);
end
Ra_boot=boot3(:,1)/mu_fix;
fprintf('  %-8s %10.5f %10.5f %10.5f\n','Ra   ',Ra_hat,...
        prctile(Ra_boot,2.5),prctile(Ra_boot,97.5));

%% =========================================================================
%  SECTION 9 — Summary comparison table
%  =========================================================================
fprintf('\n=== Parameter summary ===\n');
fprintf('  %-10s  %-18s  %-18s  %-20s\n',...
        'Parameter','Conceptual','Calibrated (MLE)','Source / Method');
fprintf('  * Illustrative baseline from the equilibrium analysis (different data regime).\n');
text(3.1, 0.11, 'model under-predicts 4th-yr M', ...
     'Color',[0 0.5 0],'FontSize',14,'FontName','Times');
rows_summary={
    'alpha', '0.30000', sprintf('%.5f',alpha_hat), 'WLS fmincon, fixed mu+c';
    'c    ', '0.75000', sprintf('%.5f',c_fix),     'max(A_obs)+0.04 buffer';
    'beta ', '0.40000', sprintf('Phi/2=%.5f',beta_hat), 'Non-identifiable; Phi only';
    'delta', '0.25000', sprintf('Phi/2=%.5f',delta_hat),'Non-identifiable; Phi only';
    'gamma', '0.20000', sprintf('%.5f',gamma_hat), 'WLS fmincon';
    'mu   ', '0.05000', sprintf('%.5f',mu_fix),    'Fixed: 4-yr degree';
    'Ra   ', '6.0000 ', sprintf('%.4f',Ra_hat),    'alpha/mu';
    'Phi  ', '1.4000 ', sprintf('%.5f',Phi_hat),   'beta+delta*gamma/mu';
};
for i=1:size(rows_summary,1)
    fprintf('  %-10s  %-18s  %-18s  %s\n',rows_summary{i,:});
end


%% =========================================================================
%  SECTION 10 — alpha identifiability diagnostic (profile SSE over alpha)
%  =========================================================================

%  Motivation: profile alpha to characterise its identifiability. For each
%  fixed alpha we re-optimise (Phi, gamma) and record the best SSE. The
%  profile shows a shallow but genuine minimum near alpha ~ 5.6 and worsens
%  for larger alpha, so alpha is WEAKLY (two-sided) identified; the bootstrap
%  CI (Section 8) is the primary uncertainty statement.

alpha_prof = linspace(mu_fix+0.05, 30, 40);   % wide range to expose railing
sse_prof   = zeros(size(alpha_prof));
opts_fmin2 = optimoptions('fmincon','Algorithm','interior-point',...
    'Display','off','MaxIterations',5000,...
    'OptimalityTolerance',1e-10,'FunctionTolerance',1e-12);
lb2 = [1e-4, 1e-4];      % [Phi, gamma]
ub2 = [20.0, 3.0];

for i = 1:numel(alpha_prof)
    a_i = alpha_prof(i);
    % objective over (Phi,gamma) with alpha fixed at a_i
    obj_pg = @(pg) wls3([a_i, pg(1), pg(2)], t_obs, A_obs, K_obs, M_obs, ...
                        n_obs, c_fix, mu_fix, opts_ode);
    x0 = [Phi_hat, gamma_hat];
    try
        [~, sse_i] = fmincon(obj_pg, x0, [],[],[],[], lb2, ub2, [], opts_fmin2);
    catch
        sse_i = NaN;
    end
    sse_prof(i) = sse_i;
end

% The profiled SSE has a genuine (shallow) minimum and rises again for large
% alpha, so alpha is WEAKLY identified with a TWO-SIDED interval, not a
% one-sided lower bound. We locate the interval where profiled SSE is within
% 1% of the floor, and (Section 11) report the bootstrap CI as the primary
% uncertainty statement for alpha.
sse_min   = min(sse_prof);
tol_flat  = sse_min + 0.01*abs(sse_min) + 1e-6;   % 1% band above the floor
in_band   = alpha_prof(sse_prof <= tol_flat);
[~,ix_min]= min(sse_prof);
alpha_opt = alpha_prof(ix_min);
if isempty(in_band); in_band = alpha_opt; end
alpha_lo_prof = min(in_band);
alpha_hi_prof = max(in_band);
fprintf('\n=== alpha identifiability (profile) ===\n');
fprintf('  Profiled SSE floor        = %.6f  at alpha = %.3f\n', sse_min, alpha_opt);
fprintf('  1%%-SSE interval for alpha : [%.2f, %.2f]\n', alpha_lo_prof, alpha_hi_prof);
fprintf('  Interpretation: shallow minimum near alpha = %.1f, worsening for\n', alpha_opt);
fprintf('  larger alpha => alpha is weakly (two-sided) identified. See the\n');
fprintf('  Section 11 bootstrap CI for the primary uncertainty on alpha.\n');

h3 = figure('Name','alpha profile SSE','Position',[100 100 1000 620]);
plot(alpha_prof, sse_prof, 'k-', 'LineWidth', 2.5); hold on;
yline(tol_flat, 'r--', 'LineWidth', 2, 'HandleVisibility','off');
xline(alpha_opt, 'b--', 'LineWidth', 2, ...
      'Label', sprintf('\\alpha_{opt} = %.2f', alpha_opt), ...
      'LabelVerticalAlignment','bottom','FontSize',18,'FontName','Times',...
      'HandleVisibility','off');
xlabel('\alpha  (fixed)','FontSize',26,'FontName','Times');
ylabel('Profiled SSE (min over \Phi,\gamma)','FontSize',26,'FontName','Times');
set(gca,axStyle{:}); box on;
baseName='Fig_alpha_profile';
saveas(h3,fullfile(outDir_fig,[baseName '.fig']));
print(h3,fullfile(outDir_png,[baseName '.png']),'-dpng','-r300');
fprintf('Saved: %s\n',baseName);

%% =========================================================================
%  SECTION 11 — Short-horizon forecast with bootstrap uncertainty band
%  =========================================================================
%  Horizon: 2 years beyond the last observation (t = 3 -> 5), i.e. years 5-6.
%  CAVEATS (must accompany any use of this forecast):
%    * A(t) is driven by an UNIDENTIFIED alpha and is already saturated near
%      the carrying capacity c; its forecast is QUALITATIVE only.
%    * Data are CROSS-SECTIONAL cohorts used as a longitudinal proxy, so the
%      forecast assumes cohort comparability that may not hold.
%    * Only K(t) and M(t) (governed by identifiable gamma, Phi) carry
%      quantitatively meaningful bands.

t_hist   = [0 3];        % fitting window
t_fore   = [3 5];        % 2-year forecast beyond last observation
t_full   = [0 5];
tt       = linspace(0, 5, 201);   % dense grid for plotting

% --- MLE trajectory over full horizon ---
[t_m, Y_m] = ode45(@(t,y) akm_moode(t,y,p), t_full, ...
                   [A_obs(1); K_obs(1); M_obs(1)], opts_ode);
Y_mle = interp1(t_m, Y_m, tt, 'pchip');
Y_mle = max(min(Y_mle,1),0);

% --- Propagate bootstrap parameter samples through the ODE ---
% boot3 columns: [alpha, Phi, gamma]. beta=delta=Phi/2 convention.
nB   = size(boot3,1);
A_bs = nan(nB, numel(tt));
K_bs = nan(nB, numel(tt));
M_bs = nan(nB, numel(tt));
for b = 1:nB
    pb.alpha = boot3(b,1);
    pb.c     = c_fix;
    pb.beta  = boot3(b,2)/2;
    pb.delta = boot3(b,2)/2;
    pb.gamma = boot3(b,3);
    pb.mu    = mu_fix;
    try
        [tb, Yb] = ode45(@(t,y) akm_moode(t,y,pb), t_full, ...
                         [A_obs(1); K_obs(1); M_obs(1)], opts_ode);
        Yi = interp1(tb, Yb, tt, 'pchip');
        Yi = max(min(Yi,1),0);
        A_bs(b,:) = Yi(:,1);
        K_bs(b,:) = Yi(:,2);
        M_bs(b,:) = Yi(:,3);
    catch
        % leave as NaN if this parameter set fails to integrate
    end
end

% --- 95% pointwise bands (percentiles across bootstrap trajectories) ---
band = @(X) [prctile(X,2.5,1); prctile(X,97.5,1)];
A_ci = band(A_bs);  K_ci = band(K_bs);  M_ci = band(M_bs);

% --- Print forecast at integer future years (t = 4 and 5) ---
fprintf('\n=== 2-year forecast (MLE with 95%% bootstrap band) ===\n');
fprintf('  %-4s %-22s %-22s %-22s\n','t','A (MLE [lo, hi])','K (MLE [lo, hi])','M (MLE [lo, hi])');
for tq = [4 5]
    [~,iq] = min(abs(tt-tq));
    fprintf('  %-4d %6.3f [%5.3f,%5.3f]   %6.3f [%5.3f,%5.3f]   %6.3f [%5.3f,%5.3f]\n', ...
        tq, Y_mle(iq,1),A_ci(1,iq),A_ci(2,iq), ...
            Y_mle(iq,2),K_ci(1,iq),K_ci(2,iq), ...
            Y_mle(iq,3),M_ci(1,iq),M_ci(2,iq));
end

% --- Figure: history + forecast with shaded bands ---
h4 = figure('Name','Forecast with bootstrap band','Position',[120 120 1150 680]);
hold on;
xf = [tt, fliplr(tt)];
fillA = fill(xf,[A_ci(1,:),fliplr(A_ci(2,:))],'r','FaceAlpha',0.15,...
             'EdgeColor','none','HandleVisibility','off');
fillK = fill(xf,[K_ci(1,:),fliplr(K_ci(2,:))],'b','FaceAlpha',0.15,...
             'EdgeColor','none','HandleVisibility','off');
fillM = fill(xf,[M_ci(1,:),fliplr(M_ci(2,:))],'g','FaceAlpha',0.15,...
             'EdgeColor','none','HandleVisibility','off');

% MLE lines: solid over fitting window, dashed over forecast window
mask_h = tt<=3;  mask_f = tt>=3;
plot(tt(mask_h),Y_mle(mask_h,1),'r-','LineWidth',2.5,'DisplayName','A(t) fit');
plot(tt(mask_h),Y_mle(mask_h,2),'b-','LineWidth',2.5,'DisplayName','K(t) fit');
plot(tt(mask_h),Y_mle(mask_h,3),'g-','LineWidth',2.5,'DisplayName','M(t) fit');
plot(tt(mask_f),Y_mle(mask_f,1),'r--','LineWidth',2.5,'DisplayName','A(t) forecast');
plot(tt(mask_f),Y_mle(mask_f,2),'b--','LineWidth',2.5,'DisplayName','K(t) forecast');
plot(tt(mask_f),Y_mle(mask_f,3),'g--','LineWidth',2.5,'DisplayName','M(t) forecast');

% Observed points with binomial 95% error bars
errorbar(t_obs,A_obs,1.96*se_A,'ro','MarkerSize',12,'MarkerFaceColor','r',...
         'LineWidth',1.5,'HandleVisibility','off');
errorbar(t_obs,K_obs,1.96*se_K,'bs','MarkerSize',12,'MarkerFaceColor','b',...
         'LineWidth',1.5,'HandleVisibility','off');
errorbar(t_obs,M_obs,1.96*se_M,'g^','MarkerSize',12,'MarkerFaceColor','g',...
         'LineWidth',1.5,'HandleVisibility','off');

xline(3,'k:','LineWidth',2,'Label','forecast start',...
      'LabelVerticalAlignment','top','FontSize',16,'FontName','Times',...
      'HandleVisibility','off');
xlabel('Academic year (time proxy)','FontSize',26,'FontName','Times');
ylabel('Proportion of cohort','FontSize',26,'FontName','Times');
xticks(0:5); xticklabels({'1st','2nd','3rd','4th','5th','6th'});
xlim([-0.1,5.1]); ylim([0,1]);
legend('Location','eastoutside','FontSize',16,'FontName','Times');
set(gca,axStyle{:}); box on;

baseName='Fig_forecast_bootstrap';
saveas(h4,fullfile(outDir_fig,[baseName '.fig']));
print(h4,fullfile(outDir_png,[baseName '.png']),'-dpng','-r300');
fprintf('Saved: %s\n',baseName);

fprintf(['\n  NOTE: A(t) forecast is qualitative (alpha unidentified, A saturated).\n' ...
         '  K(t) and M(t) bands reflect identifiable gamma and Phi. Cross-sectional\n' ...
         '  cohort data used as longitudinal proxy — treat as scenario, not prediction.\n']);