%% this is where I will build my final analysis for the project

% Using a 902 cortical ROI x 35 ROI cerebellum file generated by conn_full_rois.
%
% Below are the settings I used:
% civet_format = 1;
% tr_s = 0.7;
% tr_n = 1200;
% filt_lo_hz = 0.009;
% filt_hi_hz = 0.08;
% filt_order = 100;
% tested_runs = [1, 2, 3, 4];
% update_func = 1;
% update_volu = 1;
% update_grey = 1;
% use_ctx_mask = 1;
% use_filter = 1;

addpath(genpath('/home/jdv/code/cerebellum'))
%inname = 'compcor-1000-dil_nopass_func-volu-grey_vertex_CV_proc.mat';
load('curr-ana-final-1000.mat');
outname = 'curr-ana-final-1000_2017.mat';
parpool

g_volu_ctx = corr(ctx_volu);
g_volu_sub = corr(sub_volu);
g_thck_ctx = corr(ctx_thck);
g_thck_sub = corr(sub_thck);
g_grey_ctx = corr(ctx_grey);
g_grey_sub = corr(sub_grey);
g_func_ctx = calc_g_func(ctx_func, nsub*nrun);
g_func_sub = calc_g_func(sub_func, nsub*nrun);
g_func_sub_2ndord = corr(r_func');
g_volu_sub_2ndord = corr(g_volu');
g_thck_sub_2ndord = corr(g_thck');

% Q1 -- overview of data
figure; % data-overview.fig
subplot(2,3,1); [H, T, perm] = dendrogram_plot(g_func_ctx, [], [], 1, 1);
subplot(2,3,2); dendrogram_plot(g_volu_ctx, [], perm, 1, 1);
subplot(2,3,3); dendrogram_plot(g_thck_ctx, [], perm, 1, 1);
subplot(2,3,4); [H, T, perm] = dendrogram_plot(r_func, labels, [], 0.5, 0);
subplot(2,3,5); dendrogram_plot(g_volu, labels, perm, 0.5, 0);
subplot(2,3,6); dendrogram_plot(g_thck, labels, perm, 0.5, 0);

% correlation of second-order and first order subcortical matrix
%dims = size(g_func_sub);
%a = reshape(g_func_sub, dims(1)*dims(1), 1);
%b = reshape(g_func_sub_2ndord, dims(1)*dims(1), 1);
%matrix_similarity = corr(a,b); % 0.5265
%idx = find(b > 0);
%matrix_similarity_pos = corr(a(idx), b(idx)); % 0.5785

% Q2 Structrure function at ROI level
n_iter = 10000;
[func_volu_rs, func_volu_ps, func_volu_sig] = permutation_test(g_func, g_volu, n_iter, 97.5);
[func_thck_rs, func_thck_ps, func_thck_sig] = permutation_test(g_func, g_thck, n_iter, 97.5);
[volu_thck_rs, volu_thck_ps, volu_thck_sig] = permutation_test(g_volu, g_thck, n_iter, 97.5);

figure; % func-struct-roi.fig
subplot(2,2,1:2)
bar(func_volu_rs, 'FaceColor', [0 0 0], 'EdgeColor', [0 0 0]);
hold all;
bar(func_thck_rs, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', [0.7 0.7 0.7]);
set(gca, 'xtick', [1:35]);
set(gca, 'xticklabel', labels);
xlim([0.5 35.5])

%subplot(2,2,3)
%xbins = -0.7:0.1:0.7;
%[nb,xb]=hist(func_volu_ctx_rs, xbins); bh=bar(xb,nb, 1); set(bh,'facecolor',[0 0 0]);
%hold all
%[nb,xb]=hist(func_thck_ctx_rs, xbins); bh=bar(xb,nb, 1); set(bh,'facecolor',[0.7 0.7 0.7], 'edgecolor', [0.7 0.7 0.7]);
%legend({'volume', 'thickness'})

subplot(2,2,4)
xbins = -0.7:0.1:0.7;
[nb,xb]=hist(func_volu_rs, xbins); bh=bar(xb,nb, 1); set(bh,'facecolor',[0 0 0]);
hold all
[nb,xb]=hist(func_thck_rs, xbins); bh=bar(xb,nb, 1); set(bh,'facecolor',[0.7 0.7 0.7], 'edgecolor', [0.7 0.7 0.7]);
legend({'volume', 'thickness'})

% cortical atlas -- for mappings
fname = fopen(['ctx_roi_civ.L.1D'], 'rt');
fdata = textscan(fname, '%f%f%f%f%f%f%f', 'Whitespace', ' ', 'MultipleDelimsAsOne', 1, 'HeaderLines', 5);
ctx_tmp_maskL = fdata{7};
fclose(fname);
fname = fopen(['ctx_roi_civ.R.1D'], 'rt');
fdata = textscan(fname, '%f%f%f%f%f%f%f', 'Whitespace', ' ', 'MultipleDelimsAsOne', 1, 'HeaderLines', 5);
ctx_tmp_maskR = fdata{7};
fclose(fname);

ctx_mask = [ctx_tmp_maskL; ctx_tmp_maskR];
ctx_rois = unique(ctx_mask(ctx_mask > 0));

% export
%idx_to_nifti('100307/T1w/parcellation_1000-dil.nii.gz', func_volu_ctx_rs, ctx_rois, 'ctx-func-volu.nii.gz');
%idx_to_nifti('100307/T1w/parcellation_1000-dil.nii.gz', func_thck_ctx_rs, ctx_rois, 'ctx-func-thck.nii.gz');
idx_to_nifti('100307/proc/smoothmask.01.nii.gz', func_volu_rs, [], 'cere-func-volu.nii.gz');
idx_to_nifti('100307/proc/smoothmask.01.nii.gz', func_thck_rs, [], 'cere-func-thck.nii.gz');
idx_to_nifti('100307/proc/smoothmask.01.nii.gz', volu_thck_rs, [], 'cere-volu-thck.nii.gz');

% Q3: cross-modal similarity of clustering
sparsities = [0.01:0.01:0.2];
clst_sub = [2:1:10];

inst_func = clusterestimate(g_func_sub_2ndord, sparsities, 0, clst_sub, n_iter);
inst_thck = clusterestimate(g_thck_sub_2ndord, sparsities, 0, clst_sub, n_iter);
inst_volu = clusterestimate(g_volu_sub_2ndord, sparsities, 0, clst_sub, n_iter);


% Q4: network-level structure-function relationship
ctx_merged_volu_sub = compute_network_maturation_corrs(sub_volu, ctx_volu, partitions_func_sub);
ctx_merged_thck_sub = compute_network_maturation_corrs(sub_thck, ctx_thck, partitions_func_sub);

[func_volu_net_rs, func_volu_net_ps] = value_compare(ctx_merged_func_sub', ctx_merged_volu_sub', 0.05, 1);
[func_thck_net_rs, func_thck_net_ps] = value_compare(ctx_merged_func_sub', ctx_merged_thck_sub', 0.05, 1);

[func_volu_net_rs_sparse, func_volu_net_ps_sparse] = value_compare(ctx_merged_func_sub', ctx_merged_volu_sub', [], 0.1);
[func_thck_net_rs_sparse, func_thck_net_ps_sparse] = value_compare(ctx_merged_func_sub', ctx_merged_thck_sub', [], 0.1);

figure; % func-struct-net.fig
bar(func_volu_net_rs, 'FaceColor', [0 0 0], 'EdgeColor', [0 0 0]);
hold all;
bar(func_thck_net_rs, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', [0.7 0.7 0.7]);
set(gca, 'xtick', [1:7]);
set(gca, 'xticklabel', {'VI/VIIB', 'VIIIA/B', 'III/IV', 'V', 'Crus I/II', 'IX', 'X/CM'});
xlim([0.5 7.5])

figure; % func-struct-net-sparse.fig
bar(func_volu_net_rs_sparse, 'FaceColor', [0 0 0], 'EdgeColor', [0 0 0]);
hold all;
bar(func_thck_net_rs_sparse, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', [0.7 0.7 0.7]);
set(gca, 'xtick', [1:7]);
set(gca, 'xticklabel', {'VI/VIIB', 'VIIIA/B', 'III/IV', 'V', 'Crus I/II', 'IX', 'X/CM'});
xlim([0.5 7.5])

% create cross network diagram
x = length(unique(partitions_func_ctx(partitions_func_ctx > 0)));
y = length(unique(partitions_func_sub(partitions_func_sub > 0)));

cross_network = zeros(x+y, x+y);

for c = 1:x;
    idx_c = find(partitions_func_ctx == c);
    for s = 1:y;

        idx_s = find(ctx_merged_func_sub_sparse(s, :) > 0);
        idx = intersect(idx_c, idx_s);

        if length(idx) == 0;
            cross_network(c, x+s) = 0;
            cross_network(x+s, c) = 0;
        else;

            cross_network(c, x+s) = mean(ctx_merged_func_sub_sparse(s, idx));
            cross_network(x+s, c) = mean(ctx_merged_func_sub_sparse(s, idx));
        end
    end
end

% normalize
%cross_network = cross_network ./ max(max(cross_network));
netlabels = {'occ/pari', 'exec-ctrl', 'mtl', 'motor/temporal', 'ant-cing', 'dmn', 'VI/VIIB', 'VIIIA/B', 'III/IV', 'V', 'Crus I/II', 'IX', 'X/CM'};
writetoPAJ_labels(cross_network, 'cross-network-model', 0, netlabels);
dlmwrite('cross-network-model.csv', cross_network, ',');

%save(outname, '-v7.3')
% eva marder -- carb connectivity
% marcus richel
