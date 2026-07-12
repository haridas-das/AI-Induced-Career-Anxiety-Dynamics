%% =========================================================================
%  AKM Career Anxiety Dataset — Complete Data Analysis in MATLAB
%  =========================================================================
%  Reference:
%    Islam, S., et al. (2026). Career Anxiety in the Age of Artificial
%    Intelligence: Survey Data of University Students in Bangladesh.
%    Data in Brief. DOI: 10.1016/j.dib.2026.112924
%
%  HOW TO USE THIS SCRIPT:
%    1. Place this .m file in any folder on your computer.
%    2. Place  dataset_variable_encoded.xlsx  in the SAME folder.
%    3. Run the script. All figures are saved automatically to:
%         <same folder>/result figures/fig/   (.fig files)
%         <same folder>/result figures/png/   (300 dpi PNG files)
%
%  VARIABLE ENCODINGS (from survey questionnaire):
%    career_anxiety       : 0=No Anxiety  1=Low  2=Medium  3=High
%    ai_knowledge         : 0=None  1=Low  2=Medium  3=High
%    gender               : 0=Male  1=Female
%    academic_year        : '1st Year' … '4th Year'  (text)
%    ai_future_perspective: 0=Helpful … 4=Complete takeover
%    ai_replace_jobs      : 0=No  1=Partially  2=Fully
%    ai_takeover_time     : 0=Never  1=50+yr  2=21-50yr
%                           3=11-20yr  4=6-10yr  5=1-5yr
%    age                  : integer (18–27)
%
%  ANALYSES PERFORMED:
%    1.  Load & clean data
%    2.  Descriptive statistics table
%    3.  Career anxiety distribution
%    4.  AI knowledge distribution
%    5.  Gender & academic year breakdown
%    6.  AI future perspective distribution
%    7.  Anxiety × AI knowledge cross-tabulation + heatmap
%    8.  Mean anxiety by AI knowledge (Kruskal-Wallis)
%    9.  Anxiety × AI future perspective
%    10. Anxiety × AI replacement & takeover timeline
%    11. Anxiety by gender (Mann-Whitney U)
%    12. Anxiety by academic year (Kruskal-Wallis)
%    13. Anxiety by age (Spearman)
%    14. Spearman correlation matrix
%    15. AKM compartment proportions by academic year (time proxy)
%    16. Effect-size summary figure
%    17. Print all statistical results to console
% =========================================================================

clear; clc; close all;

%% ── Output directories ───────────────────────────────────────────────────
outDir_fig = fullfile(pwd, 'result figures', 'fig');
outDir_png = fullfile(pwd, 'result figures', 'png');
if ~exist(outDir_fig,'dir'); mkdir(outDir_fig); end
if ~exist(outDir_png,'dir'); mkdir(outDir_png); end

%% ── Shared style settings ────────────────────────────────────────────────
axS   = {'FontSize',26,'LineWidth',2,'FontName','Times'};
axSm  = {'FontSize',20,'LineWidth',1.5,'FontName','Times'};
PA = [0.886 0.294 0.290];   % red    — Anxious
PB = [0.180 0.459 0.714];   % blue   — Knowledgeable
PC = [0.114 0.620 0.459];   % green  — Market-ready
PD = [0.957 0.631 0.141];   % amber
PE = [0.557 0.361 0.671];   % purple

fprintf('\n');
disp('╔══════════════════════════════════════════════════════════════╗');
disp('║   AKM Career Anxiety — MATLAB Data Analysis                  ║');
disp('║   Islam et al. (2026), N = 3,156 Bangladeshi students        ║');
disp('╚══════════════════════════════════════════════════════════════╝');
fprintf('\n');

%% =========================================================================
%  STEP 1 — Load data
%% =========================================================================
fprintf('Loading dataset_variable_encoded.xlsx ...\n');
fname = fullfile(pwd, 'dataset_variable_encoded.xlsx');
if ~isfile(fname)
    error(['File not found: ' fname ...
           '\nPlace dataset_variable_encoded.xlsx in the same folder as this script.']);
end

opts_read = detectImportOptions(fname);
T = readtable(fname, opts_read);

fprintf('  Loaded: %d rows × %d columns\n', height(T), width(T));
fprintf('  Columns: %s\n\n', strjoin(T.Properties.VariableNames, ', '));

%% ── Convert academic_year to numeric ─────────────────────────────────────
yr_map = containers.Map({'1st Year','2nd Year','3rd Year','4th Year'},{1,2,3,4});
T.year_num = cellfun(@(y) yr_map(y), T.academic_year);

%% ── Clean ai_takeover_time (coerce non-numeric to NaN) ──────────────────
if iscell(T.ai_takeover_time)
    T.ai_takeover_num = str2double(T.ai_takeover_time);
elseif isnumeric(T.ai_takeover_time)
    T.ai_takeover_num = T.ai_takeover_time;
else
    T.ai_takeover_num = double(T.ai_takeover_time);
end
T.ai_takeover_num(T.ai_takeover_num < 0 | T.ai_takeover_num > 5) = NaN;

N = height(T);

%% =========================================================================
%  STEP 2 — Descriptive statistics
%% =========================================================================
fprintf('━━━  DESCRIPTIVE STATISTICS  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('  N = %d students across 5 universities, Bangladesh 2025\n\n', N);

num_vars = {'age','career_anxiety','ai_knowledge',...
            'ai_future_perspective','ai_replace_jobs'};
num_lbls = {'Age','Career Anxiety (0-3)','AI Knowledge (0-3)',...
            'AI Future Persp. (0-4)','AI Replace Jobs (0-2)'};

fprintf('  %-28s %7s %7s %5s %8s %5s\n',...
        'Variable','Mean','SD','Min','Median','Max');
fprintf('  %s\n', repmat('-',1,65));
for i = 1:numel(num_vars)
    v = T.(num_vars{i});
    v = v(~isnan(v));
    fprintf('  %-28s %7.3f %7.3f %5.0f %8.1f %5.0f\n',...
            num_lbls{i}, mean(v), std(v), min(v), median(v), max(v));
end
fprintf('\n');

%% =========================================================================
%  STEP 3 — Career anxiety distribution
%% =========================================================================
fprintf('━━━  CAREER ANXIETY DISTRIBUTION  ━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
ca_lbl = {'No Anxiety','Low','Medium','High'};
ca_cnt = histcounts(T.career_anxiety, -0.5:1:3.5);
for i = 1:4
    fprintf('  %-12s : %4d  (%.2f%%)\n', ca_lbl{i}, ca_cnt(i), 100*ca_cnt(i)/N);
end
fprintf('  %-12s : %4d  (%.2f%%)\n','High+Med',...
        ca_cnt(3)+ca_cnt(4), 100*(ca_cnt(3)+ca_cnt(4))/N);
fprintf('\n');

%% ── FIGURE 1: Career anxiety distribution bar ───────────────────────────
h1 = figure('Name','Fig1: Career Anxiety Distribution','Position',[60 60 900 600]);
clrs1 = [PC; PD; PB; PA];
b1 = bar(0:3, ca_cnt, 'FaceColor','flat','EdgeColor','white','LineWidth',1.5);
for i=1:4; b1.CData(i,:) = clrs1(i,:); end
hold on;
for i=1:4
    text(i-1, ca_cnt(i)+25, sprintf('%d\n(%.1f%%)',ca_cnt(i),100*ca_cnt(i)/N),...
         'HorizontalAlignment','center','FontSize',18,'FontWeight','bold','FontName','Times');
end

set(gca, axS{:});
xticks(0:3); xticklabels(ca_lbl);
xlabel('Career Anxiety Level','FontSize',26,'FontName','Times');
ylabel('Number of Students',  'FontSize',26,'FontName','Times');
title('Career Anxiety Distribution  (N = 3,156)','FontSize',24,'FontName','Times');
ylim([0 2100]); 
box on; 
saveas(h1,fullfile(outDir_fig,'Fig1_career_anxiety_distribution.fig'));
print(h1,fullfile(outDir_png,'Fig1_career_anxiety_distribution.png'),'-dpng','-r300');
fprintf('  Saved: Fig1_career_anxiety_distribution\n');

%% =========================================================================
%  STEP 4 — AI knowledge distribution
%% =========================================================================
fprintf('\n━━━  AI KNOWLEDGE DISTRIBUTION  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
aik_lbl = {'None','Low','Medium','High'};
aik_cnt = histcounts(T.ai_knowledge, -0.5:1:3.5);
for i=1:4
    fprintf('  %-8s : %4d  (%.2f%%)\n', aik_lbl{i}, aik_cnt(i), 100*aik_cnt(i)/N);
end

h2 = figure('Name','Fig2: AI Knowledge Distribution','Position',[80 80 900 600]);
clrs2 = [PE; PD; PB; PC];
b2 = bar(0:3, aik_cnt,'FaceColor','flat','EdgeColor','white','LineWidth',1.5);
for i=1:4; b2.CData(i,:)=clrs2(i,:); end
hold on;
for i=1:4
    text(i-1, aik_cnt(i)+25, sprintf('%d\n(%.1f%%)',aik_cnt(i),100*aik_cnt(i)/N),...
         'HorizontalAlignment','center','FontSize',18,'FontWeight','bold','FontName','Times');
end
set(gca,axS{:});
xticks(0:3); xticklabels(aik_lbl);
xlabel('AI Knowledge Level','FontSize',26,'FontName','Times');
ylabel('Number of Students', 'FontSize',26,'FontName','Times');
title('AI Knowledge Level Distribution  (N = 3,156)','FontSize',24,'FontName','Times');
ylim([0 2800]); 
box on;
saveas(h2,fullfile(outDir_fig,'Fig2_ai_knowledge_distribution.fig'));
print(h2,fullfile(outDir_png,'Fig2_ai_knowledge_distribution.png'),'-dpng','-r300');
fprintf('  Saved: Fig2_ai_knowledge_distribution\n');

%% =========================================================================
%  STEP 5 — Gender and academic year
%% =========================================================================
fprintf('\n━━━  GENDER AND ACADEMIC YEAR  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
n_male   = sum(T.gender==0); n_female = sum(T.gender==1);
fprintf('  Male  : %d (%.1f%%)\n', n_male,   100*n_male/N);
fprintf('  Female: %d (%.1f%%)\n', n_female, 100*n_female/N);
yr_cnt = histcounts(T.year_num, 0.5:1:4.5);
yr_lbl_s = {'1st','2nd','3rd','4th'};
for i=1:4
    fprintf('  Year %d: %d (%.1f%%)\n', i, yr_cnt(i), 100*yr_cnt(i)/N);
end

h3 = figure('Name','Fig3: Gender & Year','Position',[100 100 1200 550]);
subplot(1,2,1);
pie([n_male n_female], {'Male 61.2%','Female 38.8%'});
colormap([PB;PA]);
title('Gender Distribution','FontSize',22,'FontName','Times','FontWeight','bold');
set(gca,'FontSize',18,'FontName','Times');

subplot(1,2,2);
b3=bar(1:4, yr_cnt,'FaceColor','flat','EdgeColor','white','LineWidth',1.5);
cyr=[PB;PC;PD;PA];
for i=1:4; b3.CData(i,:)=cyr(i,:); end
hold on;
for i=1:4
    text(i,yr_cnt(i)+15,sprintf('%d',yr_cnt(i)),'HorizontalAlignment','center',...
         'FontSize',18,'FontWeight','bold','FontName','Times');
end
set(gca,axS{:}); xticks(1:4); xticklabels(yr_lbl_s);
xlabel('Academic Year','FontSize',24,'FontName','Times');
ylabel('Count','FontSize',24,'FontName','Times');
title('Students by Academic Year','FontSize',22,'FontName','Times','FontWeight','bold');
ylim([0 1300]); 
box on;
saveas(h3,fullfile(outDir_fig,'Fig3_gender_year.fig'));
print(h3,fullfile(outDir_png,'Fig3_gender_year.png'),'-dpng','-r300');
fprintf('  Saved: Fig3_gender_year\n');

%% =========================================================================
%  STEP 6 — AI future perspective distribution
%% =========================================================================
fprintf('\n━━━  AI FUTURE PERSPECTIVE  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
afp_lbl = {'Helpful tool','Mostly assist','Some replace','Sig. replace','Takeover'};
afp_cnt = histcounts(T.ai_future_perspective, -0.5:1:4.5);
for i=1:5
    fprintf('  %-15s : %4d  (%.2f%%)\n', afp_lbl{i}, afp_cnt(i), 100*afp_cnt(i)/N);
end

h4 = figure('Name','Fig4: AI Future Perspective','Position',[120 120 1100 600]);
clrs4 = [PC;PB;PD;PA;PE];
b4=barh(0:4, afp_cnt,'FaceColor','flat','EdgeColor','white','LineWidth',1.5);
for i=1:5; b4.CData(i,:)=clrs4(i,:); end
hold on;
for i=1:5
    text(afp_cnt(i)+20, i-1, sprintf('%d (%.1f%%)',afp_cnt(i),100*afp_cnt(i)/N),...
         'VerticalAlignment','middle','FontSize',17,'FontWeight','bold','FontName','Times');
end
set(gca,axS{:}); yticks(0:4); yticklabels(afp_lbl);
xlabel('Number of Students','FontSize',24,'FontName','Times');
title('AI Future Perspective  (N = 3,156)','FontSize',24,'FontName','Times');
xlim([0 1800]); 
box on;
saveas(h4,fullfile(outDir_fig,'Fig4_ai_future_perspective.fig'));
print(h4,fullfile(outDir_png,'Fig4_ai_future_perspective.png'),'-dpng','-r300');
fprintf('  Saved: Fig4_ai_future_perspective\n');

%% =========================================================================
%  STEP 7 — Anxiety × AI knowledge heatmap
%% =========================================================================
fprintf('\n━━━  ANXIETY × AI KNOWLEDGE (cross-tabulation)  ━━━━━━━━━━━━\n');
% Cross-tab: rows=ai_knowledge (0-3), cols=career_anxiety (0-3)
ct7 = zeros(4,4);
for k=0:3
    for c=0:3
        ct7(k+1,c+1) = sum(T.ai_knowledge==k & T.career_anxiety==c);
    end
end
ct7_pct = 100 * ct7 ./ sum(ct7,2);   % row percentages

fprintf('  Row %% (High+Med anxiety by AI knowledge level):\n');
for k=0:3
    hm_pct = ct7_pct(k+1,3) + ct7_pct(k+1,4);
    fprintf('    %s AI know.: High+Med anxiety = %.1f%%\n', aik_lbl{k+1}, hm_pct);
end

% Kruskal-Wallis: anxiety ~ AI knowledge
groups7 = {T.career_anxiety(T.ai_knowledge==0), T.career_anxiety(T.ai_knowledge==1),...
           T.career_anxiety(T.ai_knowledge==2), T.career_anxiety(T.ai_knowledge==3)};
% [p7, ~, stats7] = kruskalwallis(T.career_anxiety, T.ai_knowledge, 'off');
% [p7,~,stats7] = kruskalwallis(T.career_anxiety, T.ai_knowledge,'off');
[p7,~,stats7] = kruskalwallis(T.career_anxiety,T.ai_knowledge,'off');
k = numel(unique(T.ai_knowledge(~isnan(T.ai_knowledge))));
H7 = chi2inv(1-p7, k-1);
% k = numel(unique(T.ai_knowledge(~isnan(T.ai_knowledge))));
% H7 = chi2inv(1-p7, k-1);
% fprintf('\n  Kruskal-Wallis: H=%.3f, p=%.6f  (%s)\n', stats7.chi2stat, p7, sig_label(p7));
fprintf('Kruskal-Wallis: H=%.3f, p=%.6f (%s)\n', ...
        H7, p7, sig_label(p7));

h5 = figure('Name','Fig5: Anxiety × AI Knowledge Heatmap','Position',[140 140 900 650]);
imagesc(ct7_pct);
colorbar; colormap(flipud(hot));
set(gca,axSm{:});
xticks(1:4); xticklabels({'No Anx','Low','Medium','High'});
yticks(1:4); yticklabels({'None','Low','Medium','High'});
xlabel('Career Anxiety','FontSize',22,'FontName','Times');
ylabel('AI Knowledge',  'FontSize',22,'FontName','Times');
% title({'Anxiety Distribution by AI Knowledge (%)',...
%        sprintf('Kruskal-Wallis H=%.2f, p=%.4f  (%s)',stats7.chi2stat,p7,sig_label(p7))},...
%       'FontSize',20,'FontName','Times');
sprintf('Kruskal-Wallis p=%.4f (%s)',...
        p7,sig_label(p7))
% Annotate cells
box on;
for r=1:4
    for c=1:4
        text(c,r,sprintf('%.1f%%',ct7_pct(r,c)),...
             'HorizontalAlignment','center','FontSize',15,...
             'FontWeight','bold','Color','k','FontName','Times');
    end
end
saveas(h5,fullfile(outDir_fig,'Fig5_anxiety_knowledge_heatmap.fig'));
print(h5,fullfile(outDir_png,'Fig5_anxiety_knowledge_heatmap.png'),'-dpng','-r300');
fprintf('  Saved: Fig5_anxiety_knowledge_heatmap\n');

%% =========================================================================
%  STEP 8 — Mean anxiety by AI knowledge
%% =========================================================================
h6 = figure('Name','Fig6: Mean Anxiety by AI Knowledge','Position',[160 160 900 650]);
means8 = zeros(1,4); sems8 = zeros(1,4);
for k=0:3
    v=T.career_anxiety(T.ai_knowledge==k);
    means8(k+1)=mean(v); sems8(k+1)=std(v)/sqrt(numel(v));
end
b8=bar(0:3,means8,'FaceColor','flat','EdgeColor','white','LineWidth',1.5,'BarWidth',0.6);
clrs8 = [PE; PD; PB; PC];
for i=1:4; b8.CData(i,:) = clrs8(i,:); end
box on;
hold on;
errorbar(0:3,means8,1.96*sems8,'k.','LineWidth',2,'CapSize',10);
for i=1:4
    text(i-1,means8(i)+0.05,sprintf('%.3f',means8(i)),...
         'HorizontalAlignment','center','FontSize',18,...
         'FontWeight','bold','FontName','Times');
end
set(gca,axS{:}); xticks(0:3); xticklabels(aik_lbl);
xlabel('AI Knowledge Level','FontSize',26,'FontName','Times');
ylabel('Mean Career Anxiety (0–3)','FontSize',26,'FontName','Times');
% title({'Mean Anxiety by AI Knowledge Level (±1.96 SE)',...
%        sprintf('Kruskal-Wallis H=%.2f, p=%.4f  (%s)',stats7.chi2stat,p7,sig_label(p7))},...
%       'FontSize',20,'FontName','Times');
ylim([0 2.5]); box on;
saveas(h6,fullfile(outDir_fig,'Fig6_mean_anxiety_by_AI_knowledge.fig'));
print(h6,fullfile(outDir_png,'Fig6_mean_anxiety_by_AI_knowledge.png'),'-dpng','-r300');
fprintf('  Saved: Fig6_mean_anxiety_by_AI_knowledge\n');

%% =========================================================================
%  STEP 9 — Anxiety × AI future perspective
%% =========================================================================
fprintf('\n━━━  ANXIETY × AI FUTURE PERSPECTIVE  ━━━━━━━━━━━━━━━━━━━━━━\n');
means9 = zeros(1,5); sems9 = zeros(1,5);
for k=0:4
    v=T.career_anxiety(T.ai_future_perspective==k);
    means9(k+1)=mean(v); sems9(k+1)=std(v)/sqrt(numel(v));
end
groups9 = arrayfun(@(k) T.career_anxiety(T.ai_future_perspective==k), 0:4,'UniformOutput',false);
[p9,~,st9]=kruskalwallis(T.career_anxiety,T.ai_future_perspective,'off');
% fprintf('  Kruskal-Wallis: H=%.3f, p=%.6f  (%s)\n', st9.chi2stat, p9, sig_label(p9));

h7=figure('Name','Fig7: Anxiety × AI Future Perspective','Position',[180 180 1100 650]);
clrs9=[PC;PB;PD;PA;PE];
b9=bar(0:4,means9,'FaceColor','flat','EdgeColor','white','LineWidth',1.5,'BarWidth',0.65);
for i=1:5; b9.CData(i,:)=clrs9(i,:); end
hold on;
errorbar(0:4,means9,1.96*sems9,'k.','LineWidth',2,'CapSize',8);
for i=1:5
    text(i-1,means9(i)+0.05,sprintf('%.3f',means9(i)),...
         'HorizontalAlignment','center','FontSize',16,'FontWeight','bold','FontName','Times');
end
set(gca,axS{:}); xticks(0:4);
xticklabels({'Helpful','Mostly assist','Some replace','Sig. replace','Takeover'});
xtickangle(20);
xlabel('AI Future Perspective','FontSize',24,'FontName','Times');
ylabel('Mean Career Anxiety (0–3)','FontSize',24,'FontName','Times');
% title({'Mean Anxiety by AI Future Perspective (±1.96 SE)',...
%        sprintf('K-W H=%.2f, p=%.4f  (%s)',st9.chi2stat,p9,sig_label(p9))},...
%       'FontSize',20,'FontName','Times');
ylim([0 2.5]); box on;
saveas(h7,fullfile(outDir_fig,'Fig7_anxiety_by_AI_future.fig'));
print(h7,fullfile(outDir_png,'Fig7_anxiety_by_AI_future.png'),'-dpng','-r300');
fprintf('  Saved: Fig7_anxiety_by_AI_future\n');

%% =========================================================================
%  STEP 10 — Anxiety × AI replace jobs and takeover timeline
%% =========================================================================
fprintf('\n━━━  ANXIETY × AI REPLACEMENT VIEWS  ━━━━━━━━━━━━━━━━━━━━━━━\n');
means10=[]; sems10=[];
for k=0:2
    v=T.career_anxiety(T.ai_replace_jobs==k);
    means10(end+1)=mean(v); sems10(end+1)=std(v)/sqrt(numel(v));
end
[p10,~,st10]=kruskalwallis(T.career_anxiety,T.ai_replace_jobs,'off');
% fprintf('  Kruskal-Wallis (replace jobs): H=%.3f, p=%.6f  (%s)\n',...
%         st10.chi2stat, p10, sig_label(p10));

% Spearman: anxiety ~ takeover time
tko_valid = ~isnan(T.ai_takeover_num);
[rho_tko, p_tko] = corr(T.career_anxiety(tko_valid),...
                         T.ai_takeover_num(tko_valid),'Type','Spearman');
fprintf('  Spearman (takeover timeline): ρ=%.4f, p=%.6f  (%s)\n',...
        rho_tko, p_tko, sig_label(p_tko));

h8=figure('Name','Fig8: Anxiety by Replacement Views','Position',[200 200 1300 600]);
subplot(1,2,1);
b10=bar(0:2,means10,'FaceColor','flat','EdgeColor','white','LineWidth',1.5,'BarWidth',0.6);
b10.CData(1,:)=PC; b10.CData(2,:)=PD; b10.CData(3,:)=PA;
hold on;
errorbar(0:2,means10,1.96*sems10,'k.','LineWidth',2,'CapSize',10);
for i=1:3
    text(i-1,means10(i)+0.05,sprintf('%.3f',means10(i)),...
         'HorizontalAlignment','center','FontSize',18,'FontWeight','bold','FontName','Times');
end
set(gca,axS{:}); xticks(0:2); xticklabels({'No','Partially','Fully'});
xlabel('Can AI Replace Jobs?','FontSize',24,'FontName','Times');
ylabel('Mean Career Anxiety (0–3)','FontSize',24,'FontName','Times');
% title({'Mean Anxiety by AI Replacement View',...
%        sprintf('K-W H=%.2f, p=%.4f  (%s)',st10.chi2stat,p10,sig_label(p10))},...
%       'FontSize',20,'FontName','Times');
ylim([0 2.3]); box on;

subplot(1,2,2);
tko_order=[0,1,2,3,4,5];
tko_lbl_s={'Never','50+ yr','21-50 yr','11-20 yr','6-10 yr','1-5 yr'};
means_tko=zeros(1,6); valid_tko=false(1,6);
for i=1:6
    k=tko_order(i);
    v=T.career_anxiety(T.ai_takeover_num==k);
    if ~isempty(v)
        means_tko(i)=mean(v); valid_tko(i)=true;
    end
end
cmap_tko=parula(6);
b_tko=bar(1:6,means_tko,'FaceColor','flat','EdgeColor','white','LineWidth',1.5,'BarWidth',0.7);
for i=1:6; b_tko.CData(i,:)=cmap_tko(i,:); end
hold on;
for i=1:6
    if valid_tko(i)
        text(i,means_tko(i)+0.04,sprintf('%.3f',means_tko(i)),...
             'HorizontalAlignment','center','FontSize',15,'FontWeight','bold','FontName','Times');
    end
end
set(gca,axS{:}); xticks(1:6); xticklabels(tko_lbl_s); xtickangle(25);
xlabel('Expected AI Takeover Timeline','FontSize',22,'FontName','Times');
ylabel('Mean Career Anxiety (0–3)','FontSize',22,'FontName','Times');
title({sprintf('Anxiety by AI Takeover Timeline'),...
       sprintf('Spearman ρ=%.3f, p=%.4f  (%s)',rho_tko,p_tko,sig_label(p_tko))},...
      'FontSize',20,'FontName','Times');
ylim([0 2.3]); box on;
saveas(h8,fullfile(outDir_fig,'Fig8_anxiety_replacement_timeline.fig'));
print(h8,fullfile(outDir_png,'Fig8_anxiety_replacement_timeline.png'),'-dpng','-r300');
fprintf('  Saved: Fig8_anxiety_replacement_timeline\n');

%% =========================================================================
%  STEP 11 — Anxiety by gender (Mann-Whitney U)
%% =========================================================================
fprintf('\n━━━  ANXIETY × GENDER (Mann-Whitney U)  ━━━━━━━━━━━━━━━━━━━━\n');
male_anx   = T.career_anxiety(T.gender==0);
female_anx = T.career_anxiety(T.gender==1);
[p11, ~, stats11] = ranksum(male_anx, female_anx);
fprintf('  Male   mean=%.4f  SD=%.4f  n=%d\n', mean(male_anx),  std(male_anx),  numel(male_anx));
fprintf('  Female mean=%.4f  SD=%.4f  n=%d\n', mean(female_anx),std(female_anx),numel(female_anx));
fprintf('  Mann-Whitney: z=%.3f, p=%.6f  (%s)\n',...
        stats11.zval, p11, sig_label(p11));

h9=figure('Name','Fig9: Anxiety by Gender','Position',[220 220 1000 650]);
gen_data={male_anx, female_anx};
gen_lbl_s={'Male (n=1932)','Female (n=1224)'};
clrs_g={PB,PA};
for g=1:2
    subplot(1,2,g);
    v=gen_data{g};
    ca_pct=histcounts(v,-0.5:1:3.5)/numel(v)*100;
    b_g=bar(0:3,ca_pct,'FaceColor','flat','EdgeColor','white','LineWidth',1.5);
    for i=1:4; b_g.CData(i,:)=clrs_g{g}.*[1 1 1].*max(0.3,0.6+0.1*(i-1)); end
    b_g.CData = repmat(clrs_g{g},4,1).*repmat(linspace(0.6,1.0,4)',1,3);
    for i=1:4
        text(i-1,ca_pct(i)+0.8,sprintf('%.1f%%',ca_pct(i)),...
             'HorizontalAlignment','center','FontSize',16,...
             'FontWeight','bold','FontName','Times');
    end
    set(gca,axSm{:}); xticks(0:3); xticklabels({'No Anx','Low','Med','High'});
    xlabel('Career Anxiety Level','FontSize',20,'FontName','Times');
    ylabel('Percentage (%)','FontSize',20,'FontName','Times');
    title(gen_lbl_s{g},'FontSize',20,'FontName','Times','FontWeight','bold');
    ylim([0 65]); box on;
end
sgtitle({sprintf('Career Anxiety by Gender'),...
         sprintf('Mann-Whitney U: p=%.4f  (%s)',p11,sig_label(p11))},...
        'FontSize',22,'FontName','Times','FontWeight','bold');
saveas(h9,fullfile(outDir_fig,'Fig9_anxiety_by_gender.fig'));
print(h9,fullfile(outDir_png,'Fig9_anxiety_by_gender.png'),'-dpng','-r300');
fprintf('  Saved: Fig9_anxiety_by_gender\n');

%% =========================================================================
%  STEP 12 — Anxiety by academic year (Kruskal-Wallis)
%% =========================================================================
fprintf('\n━━━  ANXIETY × ACADEMIC YEAR  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
means12=zeros(1,4); sems12=zeros(1,4);
for y=1:4
    v=T.career_anxiety(T.year_num==y);
    means12(y)=mean(v); sems12(y)=std(v)/sqrt(numel(v));
    fprintf('  Year %d: mean=%.4f  SD=%.4f  n=%d\n', y, mean(v), std(v), numel(v));
end
% [p12,~,st12]=kruskalwallis(T.career_anxiety,T.year_num,'off');
% fprintf('  Kruskal-Wallis: H=%.3f, p=%.6f  (%s)\n', st12.chi2stat, p12, sig_label(p12));

h10=figure('Name','Fig10: Anxiety by Academic Year','Position',[240 240 950 650]);
plot(1:4,means12,'o-','Color',PC,'LineWidth',3,'MarkerSize',14,...
     'MarkerFaceColor','white','MarkerEdgeColor',PC);
hold on;
fill([1:4, 4:-1:1],...
     [means12+1.96*sems12, fliplr(means12-1.96*sems12)],...
     PC,'FaceAlpha',0.15,'EdgeColor','none');
for y=1:4
    text(y+0.05,means12(y)+0.015,sprintf('%.4f',means12(y)),...
         'FontSize',18,'FontWeight','bold','FontName','Times','Color',PC);
end
set(gca,axS{:}); xticks(1:4); xticklabels({'1st','2nd','3rd','4th'});
xlabel('Academic Year','FontSize',26,'FontName','Times');
ylabel('Mean Career Anxiety (0–3)','FontSize',26,'FontName','Times');
% title({'Mean Anxiety by Academic Year  (±1.96 SE, shaded)',...
%        sprintf('Kruskal-Wallis H=%.2f, p=%.4f  (%s)',st12.chi2stat,p12,sig_label(p12))},...
%       'FontSize',20,'FontName','Times');
ylim([1.4 2.1]); xlim([0.7 4.3]); box on;
saveas(h10,fullfile(outDir_fig,'Fig10_anxiety_by_year.fig'));
print(h10,fullfile(outDir_png,'Fig10_anxiety_by_year.png'),'-dpng','-r300');
fprintf('  Saved: Fig10_anxiety_by_year\n');

%% =========================================================================
%  STEP 13 — Anxiety by age (Spearman)
%% =========================================================================
fprintf('\n━━━  ANXIETY × AGE  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
[rho13,p13]=corr(T.age,T.career_anxiety,'Type','Spearman');
fprintf('  Spearman ρ=%.4f, p=%.6f  (%s)\n', rho13, p13, sig_label(p13));

h11=figure('Name','Fig11: Anxiety by Age','Position',[260 260 950 650]);
ages=unique(T.age); ages=ages(ages>=18 & ages<=26);
m13=zeros(size(ages)); s13=zeros(size(ages)); n13=zeros(size(ages));
for i=1:numel(ages)
    v=T.career_anxiety(T.age==ages(i));
    m13(i)=mean(v); s13(i)=std(v)/sqrt(numel(v)); n13(i)=numel(v);
end
valid_age = n13>=10;
fill([ages(valid_age); flipud(ages(valid_age))],...
     [m13(valid_age)+1.96*s13(valid_age); flipud(m13(valid_age)-1.96*s13(valid_age))],...
     PB,'FaceAlpha',0.15,'EdgeColor','none'); hold on;
plot(ages(valid_age),m13(valid_age),'o-','Color',PB,'LineWidth',3,...
     'MarkerSize',12,'MarkerFaceColor','white','MarkerEdgeColor',PB);
set(gca,axS{:}); xlabel('Age','FontSize',26,'FontName','Times');
ylabel('Mean Career Anxiety (0–3)','FontSize',26,'FontName','Times');
title({'Mean Anxiety by Age  (±1.96 SE, ages with n≥10)',...
       sprintf('Spearman ρ=%.4f, p=%.4f  (%s)',rho13,p13,sig_label(p13))},...
      'FontSize',20,'FontName','Times');
ylim([1.3 2.1]); box on;
saveas(h11,fullfile(outDir_fig,'Fig11_anxiety_by_age.fig'));
print(h11,fullfile(outDir_png,'Fig11_anxiety_by_age.png'),'-dpng','-r300');
fprintf('  Saved: Fig11_anxiety_by_age\n');

%% =========================================================================
%  STEP 14 — Spearman correlation matrix
%% =========================================================================
fprintf('\n━━━  SPEARMAN CORRELATION MATRIX  ━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
corr_vars  = {'age','ai_knowledge','ai_future_perspective',...
              'ai_replace_jobs','ai_takeover_num','career_anxiety'};
corr_lbls  = {'Age','AI Know.','AI Future','Replace','Takeover','Anxiety'};
nv = numel(corr_vars);

% Build matrix
C = zeros(nv); P = ones(nv);
for i=1:nv
    for j=1:nv
        vi=T.(corr_vars{i}); vj=T.(corr_vars{j});
        ok=~isnan(vi)&~isnan(vj);
        [C(i,j),P(i,j)]=corr(vi(ok),vj(ok),'Type','Spearman');
    end
end

% Print lower triangle
fprintf('  %-12s', ''); fprintf('  %-10s', corr_lbls{:}); fprintf('\n');
for i=1:nv
    fprintf('  %-12s', corr_lbls{i});
    for j=1:nv
        if j<=i
            s=sig_label(P(i,j));
            fprintf('  %+.3f%s  ', C(i,j), s);
        else
            fprintf('  %10s', '');
        end
    end
    fprintf('\n');
end

h12=figure('Name','Fig12: Correlation Matrix','Position',[280 280 1000 850]);
imagesc(C); axis square;
clim([-1 1]); colormap(redblue_map(256));
cb=colorbar; cb.FontSize=18; cb.FontName='Times';
cb.Label.String="Spearman's ρ"; cb.Label.FontSize=20;
set(gca,axSm{:});
xticks(1:nv); xticklabels(corr_lbls); xtickangle(25);
yticks(1:nv); yticklabels(corr_lbls);
title("Spearman Correlation Matrix",'FontSize',22,'FontName','Times','FontWeight','bold');
% Annotate
for i=1:nv
    for j=1:nv
        s=sig_label(P(i,j));
        tc='k'; if abs(C(i,j))>0.4; tc='w'; end
        text(j,i,sprintf('%.2f%s',C(i,j),s),'HorizontalAlignment','center',...
             'FontSize',14,'FontWeight','bold','Color',tc,'FontName','Times');
    end
end
saveas(h12,fullfile(outDir_fig,'Fig12_correlation_matrix.fig'));
print(h12,fullfile(outDir_png,'Fig12_correlation_matrix.png'),'-dpng','-r300');
fprintf('  Saved: Fig12_correlation_matrix\n');

%% =========================================================================
%  STEP 15 — AKM compartment proportions by academic year
%% =========================================================================
fprintf('\n━━━  AKM COMPARTMENTS BY ACADEMIC YEAR (time proxy)  ━━━━━━━\n');
fprintf('  Mapping:\n');
fprintf('    A = career_anxiety >= 2  (Medium or High)\n');
fprintf('    M = ai_knowledge   == 3  (High)\n');
fprintf('    K = 1 - A - M            (residual)\n\n');

t_obs=[0,1,2,3]; yr_ns=zeros(1,4);
A_obs=zeros(1,4); K_obs=zeros(1,4); M_obs=zeros(1,4);
fprintf('  %-6s %5s  %17s  %17s  %17s\n',...
        'Year','n','A (Anxious)','K (AI-know.)','M (Mkt-ready)');
for y=1:4
    sub=T(T.year_num==y,:); n=height(sub);
    A=(sum(sub.career_anxiety>=2)); M=sum(sub.ai_knowledge==3); K=n-A-M;
    A_obs(y)=A/n; K_obs(y)=K/n; M_obs(y)=M/n; yr_ns(y)=n;
    fprintf('  Yr%d (t=%d) %5d   %4d (%.2f%%)   %4d (%.2f%%)   %4d (%.2f%%)\n',...
            y,y-1,n,A,100*A/n,K,100*K/n,M,100*M/n);
end

se_A=sqrt(A_obs.*(1-A_obs)./yr_ns);
se_K=sqrt(K_obs.*(1-K_obs)./yr_ns);
se_M=sqrt(M_obs.*(1-M_obs)./yr_ns);

h13=figure('Name','Fig13: AKM Compartments','Position',[300 300 1100 700]);
hold on;
fill([t_obs fliplr(t_obs)],...
     [A_obs+1.96*se_A fliplr(A_obs-1.96*se_A)],PA,'FaceAlpha',0.15,'EdgeColor','none');
fill([t_obs fliplr(t_obs)],...
     [K_obs+1.96*se_K fliplr(K_obs-1.96*se_K)],PB,'FaceAlpha',0.15,'EdgeColor','none');
fill([t_obs fliplr(t_obs)],...
     [M_obs+1.96*se_M fliplr(M_obs-1.96*se_M)],PC,'FaceAlpha',0.15,'EdgeColor','none');
plot(t_obs,A_obs,'o-','Color',PA,'LineWidth',3,'MarkerSize',14,...
     'MarkerFaceColor','white','MarkerEdgeColor',PA,'DisplayName','A — Anxious');
plot(t_obs,K_obs,'s-','Color',PB,'LineWidth',3,'MarkerSize',14,...
     'MarkerFaceColor','white','MarkerEdgeColor',PB,'DisplayName','K — AI-knowledgeable');
plot(t_obs,M_obs,'^-','Color',PC,'LineWidth',3,'MarkerSize',14,...
     'MarkerFaceColor','white','MarkerEdgeColor',PC,'DisplayName','M — Market-ready');
for i=1:4
    text(t_obs(i)+0.06,A_obs(i)+0.015,sprintf('%.4f',A_obs(i)),...
         'FontSize',16,'Color',PA,'FontWeight','bold','FontName','Times');
    text(t_obs(i)+0.06,K_obs(i)+0.015,sprintf('%.4f',K_obs(i)),...
         'FontSize',16,'Color',PB,'FontWeight','bold','FontName','Times');
    text(t_obs(i)+0.06,M_obs(i)-0.035,sprintf('%.4f',M_obs(i)),...
         'FontSize',16,'Color',PC,'FontWeight','bold','FontName','Times');
end
set(gca,axS{:}); xticks(0:3);
xticklabels({'1st (t=0)','2nd (t=1)','3rd (t=2)','4th (t=3)'});
xlabel('Academic Year (time proxy)','FontSize',26,'FontName','Times');
ylabel('Proportion of cohort','FontSize',26,'FontName','Times');
title({'AKM Compartment Proportions by Academic Year',...
       'Shaded region: binomial 95% CI'},'FontSize',22,'FontName','Times');
legend('Location','east','FontSize',22,'FontName','Times');
ylim([0 0.85]); xlim([-0.2 3.5]); box on;
saveas(h13,fullfile(outDir_fig,'Fig13_AKM_compartments_by_year.fig'));
print(h13,fullfile(outDir_png,'Fig13_AKM_compartments_by_year.png'),'-dpng','-r300');
fprintf('  Saved: Fig13_AKM_compartments_by_year\n');

%% =========================================================================
%  STEP 16 — Effect size summary
%% =========================================================================
fprintf('\n━━━  EFFECT SIZE SUMMARY  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
rho_vars={'age','ai_knowledge','ai_future_perspective',...
          'ai_replace_jobs','ai_takeover_num','year_num'};
rho_lbls_s={'Age','AI Knowledge','AI Future Persp.',...
            'AI Replace Jobs','AI Takeover Time','Academic Year'};
rhos=zeros(1,6); pvals=zeros(1,6);
for i=1:6
    vi=T.(rho_vars{i}); ok=~isnan(vi);
    [rhos(i),pvals(i)]=corr(vi(ok),T.career_anxiety(ok),'Type','Spearman');
    fprintf('  %-22s: ρ=%+.4f  p=%.6f  %s\n',...
            rho_lbls_s{i},rhos(i),pvals(i),sig_label(pvals(i)));
end

h14=figure('Name','Fig14: Effect Size Summary','Position',[320 320 1050 650]);
[rhos_s,idx]=sort(rhos);
lbls_s=rho_lbls_s(idx); pv_s=pvals(idx);
clrs14=arrayfun(@(r,p) ...
    [abs(r)>0.1 & p<0.05, 0.459*(abs(r)<=0.1|p>=0.05), ...
     0.714*(abs(r)<=0.1|p>=0.05)], rhos_s, pv_s,'UniformOutput',false);
bh=barh(1:6,rhos_s,'FaceColor','flat','EdgeColor','white','LineWidth',1.5,'BarWidth',0.65);
for i=1:6
    if abs(rhos_s(i))>0.1 && pv_s(i)<0.05
        bh.CData(i,:)=PA;
    else
        bh.CData(i,:)=0.7*[1 1 1];
    end
end
hold on;
xline(0,'k-','LineWidth',1.5);
xline(0.1,'r--','LineWidth',1.2,'Alpha',0.5,'DisplayName','|ρ|=0.1');
xline(-0.1,'r--','LineWidth',1.2,'Alpha',0.5,'HandleVisibility','off');
for i=1:6
    s=sig_label(pv_s(i)); off=0.003; ha='left';
    if rhos_s(i)<0; off=-0.003; ha='right'; end
    text(rhos_s(i)+off, i, sprintf('ρ=%+.3f%s',rhos_s(i),s),...
         'VerticalAlignment','middle','FontSize',17,...
         'FontWeight','bold','FontName','Times');
end
set(gca,axS{:}); yticks(1:6); yticklabels(lbls_s);
xlabel("Spearman's ρ with Career Anxiety",'FontSize',24,'FontName','Times');
title({'Predictor Effect Sizes (Spearman ρ)',...
       'Red = significant & |ρ|>0.1;  Grey = small or ns'},...
      'FontSize',20,'FontName','Times');
xlim([-0.12 0.22]); box on;
legend({'|ρ|=0.1 threshold'},'Location','southeast','FontSize',16,'FontName','Times');
saveas(h14,fullfile(outDir_fig,'Fig14_effect_size_summary.fig'));
print(h14,fullfile(outDir_png,'Fig14_effect_size_summary.png'),'-dpng','-r300');
fprintf('  Saved: Fig14_effect_size_summary\n');

%% =========================================================================
%  STEP 17 — Final console summary
%% =========================================================================
fprintf('\n');
disp('╔══════════════════════════════════════════════════════════════╗');
disp('║   ANALYSIS COMPLETE — Summary                                ║');
disp('╠══════════════════════════════════════════════════════════════╣');
fprintf('║  N = %-6d  |  5 universities  |  Bangladesh 2025         ║\n',N);
fprintf('║  Career Anxiety High+Med = %-6d (%.1f%%)                  ║\n',...
        ca_cnt(3)+ca_cnt(4), 100*(ca_cnt(3)+ca_cnt(4))/N);
fprintf('║  AI Knowledge High = %-4d (%.1f%%)                         ║\n',...
        aik_cnt(4), 100*aik_cnt(4)/N);
disp('╠══════════════════════════════════════════════════════════════╣');
disp('║  Significant predictors of anxiety (Spearman, p<0.001):     ║');
disp('║    • AI Replace Jobs view     ρ = +0.112 ***                 ║');
disp('║    • AI Future Perspective    ρ = +0.111 ***                 ║');
disp('║    • AI Takeover Timeline     ρ = +0.103 ***                 ║');
disp('║  Non-significant: Gender, AI Knowledge, Age, Year (p>0.05)  ║');
disp('╠══════════════════════════════════════════════════════════════╣');
fprintf('║  Figures saved: %s\n', outDir_png);
disp('║    Fig01  Career anxiety distribution                        ║');
disp('║    Fig02  AI knowledge distribution                          ║');
disp('║    Fig03  Gender & academic year                             ║');
disp('║    Fig04  AI future perspective                              ║');
disp('║    Fig05  Anxiety × AI knowledge heatmap                     ║');
disp('║    Fig06  Mean anxiety by AI knowledge                       ║');
disp('║    Fig07  Anxiety by AI future perspective                   ║');
disp('║    Fig08  Anxiety by replacement / takeover views            ║');
disp('║    Fig09  Anxiety by gender                                  ║');
disp('║    Fig10  Anxiety by academic year                           ║');
disp('║    Fig11  Anxiety by age                                     ║');
disp('║    Fig12  Spearman correlation matrix                        ║');
disp('║    Fig13  AKM compartments by academic year                  ║');
disp('║    Fig14  Effect size summary                                ║');
disp('╚══════════════════════════════════════════════════════════════╝');

%% =========================================================================
%  LOCAL FUNCTIONS
%% =========================================================================
function lbl = sig_label(p)
%  Returns significance stars for a p-value.
    if p < 0.001;      lbl = '***';
    elseif p < 0.01;   lbl = '**';
    elseif p < 0.05;   lbl = '*';
    else;              lbl = 'ns';
    end
end

function cmap = redblue_map(n)
%  Red-white-blue diverging colormap (n levels).
    r=[linspace(0.7,1,n/2), linspace(1,0.18,n/2)]';
    g=[linspace(0.7,1,n/2), linspace(1,0.459,n/2)]';
    b=[linspace(1,1,n/2),   linspace(1,0.714,n/2)]';
    cmap=[r g b];
end