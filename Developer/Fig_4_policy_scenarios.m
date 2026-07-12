%% =========================================================================
%  SECTION — Policy Scenarios (identifiable levers: Phi, gamma, alpha)
%  =========================================================================
%  Model: akm_moode. Baseline = CALIBRATED parameters (Table tab:parameters).
%  Interventions act ONLY on identifiable quantities:
%     Phi (total A->K transfer)  — scaled by scaling beta AND delta by the
%                                  same factor f, so Phi -> f*Phi exactly
%                                  while the (arbitrary) Phi/2 split is kept.
%     gamma (K->M rate)          — identifiable, scaled directly.
%     alpha (anxiety growth)     — weakly identified; alpha scenarios are
%                                  QUALITATIVE (see calibration section).
%  Start state: calibrated year-1 proportions, matching the baseline A(t).
% =========================================================================

% --- Output directories (match calibration script) -----------------------
outDir_fig = fullfile(pwd, 'result figures', 'fig');
outDir_png = fullfile(pwd, 'result figures', 'png');
if ~exist(outDir_fig,'dir'); mkdir(outDir_fig); end
if ~exist(outDir_png,'dir'); mkdir(outDir_png); end
axStyle = {'FontSize',20,'LineWidth',2,'FontName','Times'};

% --- Calibrated baseline parameters (from Table tab:parameters) ----------
base.alpha = 5.46789;
base.c     = 0.72170;
base.beta  = 0.29446;     % = Phi/2 convention
base.delta = 0.29446;     % = Phi/2 convention
base.gamma = 0.08857;
base.mu    = 0.25000;

Phi_base = base.beta + base.delta*base.gamma/base.mu;   % = 0.58892

% --- Simulation settings -------------------------------------------------
y0    = [0.6420; 0.2955; 0.0625];   % calibrated year-1 state [A;K;M]
tspan = [0 10];
opts  = odeset('RelTol',1e-8,'AbsTol',1e-10,'MaxStep',0.05);

% --- Helper: scale Phi by factor f (keeps beta=delta=Phi/2 split) --------
scalePhi = @(pp,f) setfield(setfield(pp,'beta',pp.beta*f),'delta',pp.delta*f);

% --- Scenario definitions ------------------------------------------------
scen = struct('name',{},'params',{},'style',{});

% 1. Baseline
scen(1).name   = 'Baseline';
scen(1).params = base;
scen(1).style  = 'k-';

% 2. AI-literacy workshops: increase total transfer Phi x1.5
scen(2).name   = 'Workshops (\Phi \times 1.5)';
scen(2).params = scalePhi(base, 1.5);
scen(2).style  = 'r--';

% 3. Alumni mentoring / career guidance: raise gamma x2
scen(3).name   = 'Mentoring (\gamma \times 2)';
scen(3).params = base;  scen(3).params.gamma = base.gamma*2;
scen(3).style  = 'b-.';

% 4. Perception-shift campaign: reduce alpha by 31.5% (QUALITATIVE)
scen(4).name   = 'Perception (\alpha \times 0.685)';
scen(4).params = base;  scen(4).params.alpha = base.alpha*(1-0.315);
scen(4).style  = 'g:';

% 5. Combined: Phi x1.5, gamma x2, alpha x0.685
scen(5).name   = 'Combined';
scen(5).params = scalePhi(base,1.5);
scen(5).params.gamma = base.gamma*2;
scen(5).params.alpha = base.alpha*(1-0.315);
scen(5).style  = 'm-';

% 6. Pessimistic: alpha x1.2, Phi x0.5
scen(6).name   = 'Pessimistic (\alpha\times1.2, \Phi\times0.5)';
scen(6).params = scalePhi(base,0.5);
scen(6).params.alpha = base.alpha*1.2;
scen(6).style  = 'c-';

% --- Pre-integrate all scenarios once, store trajectories ----------------
T = cell(numel(scen),1);  Y = cell(numel(scen),1);
for s = 1:numel(scen)
    [T{s},Y{s}] = ode45(@(t,y) akm_moode(t,y,scen(s).params), tspan, y0, opts);
end

% --- Endpoint summary table (all three compartments at t = 10) -----------
fprintf('\n=== Policy scenarios: compartments at t = 10 yr (%% of cohort) ===\n');
fprintf('  %-32s %6s %6s %6s\n','Scenario','A','K','M');
for s = 1:numel(scen)
    fprintf('  %-32s %5.1f  %5.1f  %5.1f\n', scen(s).name, ...
            100*Y{s}(end,1), 100*Y{s}(end,2), 100*Y{s}(end,3));
end

% --- Three-panel figure: A(t), K(t), M(t) --------------------------------
comp_lbl = {'Anxious A(t)','Knowledgeable K(t)','Market-ready M(t)'};
hP = figure('Name','Policy Scenarios','Position',[80 80 1650 520]);
for c = 1:3
    subplot(1,3,c); hold on;
    for s = 1:numel(scen)
        plot(T{s}, 100*Y{s}(:,c), scen(s).style, 'LineWidth',2.5, ...
             'DisplayName', scen(s).name);
    end
    xlabel('Time (years)','FontSize',20,'FontName','Times');
    ylabel([comp_lbl{c} '  (% of cohort)'],'FontSize',20,'FontName','Times');
    set(gca,axStyle{:}); box on; xlim([0 10]);
    if c==1, ylim([0 100]); end
    if c==3, legend('Location','northwest','FontSize',13,'FontName','Times'); end
end

% --- Save at publication quality (match calibration script) --------------
baseName='Fig_policy_scenarios';
saveas(hP,fullfile(outDir_fig,[baseName '.fig']));
print(hP,fullfile(outDir_png,[baseName '.png']),'-dpng','-r300');
fprintf('Saved: %s\n',baseName);