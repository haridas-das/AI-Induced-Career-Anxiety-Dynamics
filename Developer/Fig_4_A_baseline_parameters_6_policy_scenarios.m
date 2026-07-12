%% =========================================================================
%  Policy Scenarios — LOW Ra regime (conceptual / illustrative baseline)
%  =========================================================================
%  Model: akm_moode. Baseline = CONCEPTUAL parameters (Fig. 1 regime,
%  "Baseline value" column of Table tab:parameters), NOT the fitted MLE.
%  Ra = alpha/mu = 0.30/0.05 = 6  (anxiety NOT saturated -> A responds to policy).
%
%  PURPOSE: comparison against the high-Ra fitted regime. In this low-Ra
%  regime the alpha / Combined levers visibly reduce anxiety, whereas in the
%  fitted regime A stays pinned. The contrast is the point.
%
%  NOTE: these are illustrative parameters, not fitted to the survey; label
%  results accordingly in the paper.
%
%  Interventions (same levers as the high-Ra script):
%     Phi (A->K transfer) — scaled via common factor on beta AND delta.
%     gamma (K->M rate)   — scaled directly.
%     alpha (anxiety)     — scaled directly.
%  Requires akm_moode.m on the MATLAB path.
% =========================================================================

clear; clc; close all;

% --- Output directories --------------------------------------------------
outDir_fig = fullfile(pwd, 'result figures', 'fig');
outDir_png = fullfile(pwd, 'result figures', 'png');
if ~exist(outDir_fig,'dir'); mkdir(outDir_fig); end
if ~exist(outDir_png,'dir'); mkdir(outDir_png); end
axStyle = {'FontSize',20,'LineWidth',2,'FontName','Times'};

% --- Conceptual baseline parameters (Fig. 1 regime) ----------------------
base.alpha = 0.30;
base.c     = 0.75;
base.beta  = 0.40;
base.delta = 0.25;
base.gamma = 0.20;
base.mu    = 0.05;

Phi_base = base.beta + base.delta*base.gamma/base.mu;   % = 1.40
Ra_base  = base.alpha/base.mu;                          % = 6.0

% --- Simulation settings -------------------------------------------------
%  Fig. 1 initial mix (normalised from akm_moode example [2095;847;214]).
%  >>> Replace with the exact Fig. 1 initial state if your script differs. <<<
y0    = [0.664; 0.268; 0.068];
tspan = [0 10];
opts  = odeset('RelTol',1e-8,'AbsTol',1e-10,'MaxStep',0.05);

% --- Helper: scale Phi by factor f (keeps beta:delta ratio) --------------
scalePhi = @(pp,f) setfield(setfield(pp,'beta',pp.beta*f),'delta',pp.delta*f);

% --- Scenario definitions (identical to high-Ra script) ------------------
scen = struct('name',{},'params',{},'style',{});

scen(1).name   = 'Baseline';
scen(1).params = base;
scen(1).style  = 'k-';

scen(2).name   = 'Workshops (\Phi \times 1.5)';
scen(2).params = scalePhi(base, 1.5);
scen(2).style  = 'r--';

scen(3).name   = 'Mentoring (\gamma \times 2)';
scen(3).params = base;  scen(3).params.gamma = base.gamma*2;
scen(3).style  = 'b-.';

scen(4).name   = 'Perception (\alpha \times 0.685)';
scen(4).params = base;  scen(4).params.alpha = base.alpha*(1-0.315);
scen(4).style  = 'g:';

scen(5).name   = 'Combined';
scen(5).params = scalePhi(base,1.5);
scen(5).params.gamma = base.gamma*2;
scen(5).params.alpha = base.alpha*(1-0.315);
scen(5).style  = 'm-';

scen(6).name   = 'Pessimistic (\alpha\times1.2, \Phi\times0.5)';
scen(6).params = scalePhi(base,0.5);
scen(6).params.alpha = base.alpha*1.2;
scen(6).style  = 'c-';

% --- Pre-integrate all scenarios once ------------------------------------
T = cell(numel(scen),1);  Y = cell(numel(scen),1);
for s = 1:numel(scen)
    [T{s},Y{s}] = ode45(@(t,y) akm_moode(t,y,scen(s).params), tspan, y0, opts);
end

% --- Endpoint summary table (t = 10) -------------------------------------
fprintf('\n=== Policy scenarios [LOW Ra=%.1f]: t = 10 yr (%% of cohort) ===\n', Ra_base);
fprintf('  %-32s %6s %6s %6s\n','Scenario','A','K','M');
for s = 1:numel(scen)
    fprintf('  %-32s %5.1f  %5.1f  %5.1f\n', scen(s).name, ...
            100*Y{s}(end,1), 100*Y{s}(end,2), 100*Y{s}(end,3));
end

% --- Three-panel figure: A(t), K(t), M(t) --------------------------------
comp_lbl = {'Anxious A(t)','Knowledgeable K(t)','Market-ready M(t)'};
hP = figure('Name','Policy Scenarios (low Ra)','Position',[80 80 1650 520]);
for c = 1:3
    subplot(1,3,c); hold on;
    for s = 1:numel(scen)
        plot(T{s}, 100*Y{s}(:,c), scen(s).style, 'LineWidth',2.5, ...
             'DisplayName', scen(s).name);
    end
    xlabel('Time (years)','FontSize',20,'FontName','Times');
    ylabel([comp_lbl{c} '  (% of cohort)'],'FontSize',20,'FontName','Times');
    set(gca,axStyle{:}); box on; xlim([0 10]);
    if c==1, ylim([0 100]); legend('Location','northeast','FontSize',20,'FontName','Times'); end
    ylim([0 100])
end

% --- Save at publication quality -----------------------------------------
baseName='Fig_policy_scenarios_lowRa';
saveas(hP,fullfile(outDir_fig,[baseName '.fig']));
print(hP,fullfile(outDir_png,[baseName '.png']),'-dpng','-r300');
fprintf('Saved: %s\n',baseName);