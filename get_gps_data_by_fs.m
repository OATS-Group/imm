function [out_gps] = get_gps_data_by_fs(year, m_type, fig)
%GET_GPS_DATA get gps data given by year, machine type and a bounding box
%
%   This function uses GPS data and fieldShape data collected and generated by
%   Yaguang to get all the data within each field limited by a year, machine
%   type and field shapes.
%
%   Parameters:
%     Year - the year of the data
%     m_type - machine type (combine, grain kart, truck)
%     fig - flag to output figure or not
%
%  Yang Wang 11/23/2018

  year = num2str(year);
  if str2num(year) == 2016
    year = strcat(year, '_SynchedAccordingToAnimiations');
  end
  path = strcat('/backup-disk/GpsTrackData/', year);
  gps_fname = '/filesLoadedHistory.mat';
  fs_fname = '/enhancedFieldShapes.mat';

  load(strcat(path, gps_fname)); % load in tracks
  load(strcat(path, fs_fname)); % load in field shapes

  if strcmp(m_type, 'combine')
    d_indices = fileIndicesCombines;
    gps = files(d_indices); % get only the combine data
  elseif strcmp(m_type, 'kart')
    d_indices = fileIndicesGrainKarts;
    gps = files(d_indices); % get only the grain kart data
  elseif strcmp(m_type, 'truck')
    d_indices = fileIndicesTrucks;
    gps = files(d_indices); % get only the truck data
  end

  l = 1;
  uniq_gps_data_num = [];
  ids = {};
  out_gps = cell(1, length(enhancedFieldShapes));
  % we want the gps data number that is unique given the field shape
  for m = 1:length(enhancedFieldShapes)
    fprintf('For fs %d, we have the following gps data:\n',  m);
    % load field shape that fits the bbox
    fs = enhancedFieldShapes{m};
    for n = 1:length(gps)
      if sum(inShape(fs, [gps(n).lon gps(n).lat])) > 0
        fprintf('\tData number is: %d\n', n);
        fprintf('\tMachine type is: %s\n', gps(n).id);
        I = inShape(fs, [gps(n).lon gps(n).lat]);
        % we only want GPS data that is in the bbox
        gps(n).time = gps(n).time(I);
        gps(n).gpsTime = gps(n).gpsTime(I);
        gps(n).lat = gps(n).lat(I);
        gps(n).lon = gps(n).lon(I);
        gps(n).altitude = gps(n).altitude(I);
        gps(n).speed = gps(n).speed(I);
        gps(n).bearing = gps(n).bearing(I);
        gps(n).accuracy = gps(n).accuracy(I) ;
        % add the unique GPS data num to a placeholder
        if ~(ismember(n, uniq_gps_data_num)) | isempty(uniq_gps_data_num)
          uniq_gps_data_num(:,l) = n;
          ids{l} = gps(n).id;
          l = l + 1;
        end
      end
    end

    fprintf('\n');

    uniq_ids = unique(ids);

    % Move on if no gps in this fs
    if length(uniq_ids) == 0
      fprintf('\tNo gps data found for field %d, move on to the next fs.\n', m);
      fprintf('\n');
      continue
    end

    fprintf('\tThe unique number of machine type is: %d\n', length(uniq_ids));
    fprintf('\tThe unique ids: ');
    fprintf('%s | ', uniq_ids{:});
    fprintf('\n');

    if fig
      figure;
      hold on
      % plot the unique gps data
      for jj = 1:length(uniq_gps_data_num)
        scatter(gps(uniq_gps_data_num(jj)).lon, ...
          gps(uniq_gps_data_num(jj)).lat, 8);
      end
      legend
      plot_google_map('maptype', 'hybrid');
    end

    % allocate gps array
    tmp_gps = cell(1, length(uniq_ids));
    out_gps{m} = cell(1, length(uniq_ids));

    for mm = 1:length(uniq_ids)
      tmp_gps{mm} = struct('type', [], ...
                          'id', [], ...
                          'time', [], ...
                          'gpsTime', [], ...
                          'lat', [], ...
                          'lon', [], ...
                          'altitude', [], ...
                          'speed', [], ...
                          'bearing', [], ...
                          'accuracy', []);
    end

    % we want to concatenate GPS data files with the same id
    for mm = 1:length(uniq_ids)
      for nn = 1:length(uniq_gps_data_num)
        if strcmp(gps(uniq_gps_data_num(nn)).id, uniq_ids{mm})
          tmp_gps{mm} = concatenateFiles(tmp_gps{mm}, ...
            gps(uniq_gps_data_num(nn)));
        end
      end
      % assign to output
      out_gps{m}{mm} = tmp_gps{mm};
    end

    if fig
      figure;
      hold on
      % plot the concatenated unique gps data
      for jj = 1:length(uniq_ids)
        scatter(out_gps{m}{jj}.lon, out_gps{m}{jj}.lat, 8);
      end
      legend(uniq_ids);
      plot_google_map('maptype', 'hybrid');
    end

%    pause

    fprintf('\n');

    uniq_gps_data_num = [];
    ids = {};
    l = 1;
    clear uniq_ids;
    close all;
  end

end %EOF
