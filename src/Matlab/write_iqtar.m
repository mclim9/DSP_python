def write_iqtar(iq, filename, samplerate):
   ###SAVE_IQ_TAR_FILE Saves I/Q data to an iq-tar file.
   ###  SAVE_IQ_TAR_FILE(IQ,FILENAME,SAMPLERATE) saves the I/Q data
   ###  in IQ of the given SAMPLERATE to the file FILENAME.
   ###
   ###  IQ:         Complex or real-valued data in the unit Volts.
   ###              IQ can be a vector or a matrix.
   ###              If IQ is a matrix the columns represent the channels
   ###              of a multi-channel signal (e.g. MIMO).
   ###  FILENAME:   Filename, e.g. "my.iq.tar".
   ###              If no extension is specified, the extension '.iq.tar' will be appended.
   ###  SAMPLERATE: Sample rate of the captured data in Hz.
   ###
   ###  Example:
   ###    N = 2000;
   ###    samplerate = 1e6
   ###    iq = cos(2*pi*1/40*(0:N-1)) + randn(1,N);
   ###    filename = 'example.iq.tar'
   ###    save_iq_tar_file(iq,filename,samplerate)
   ###    [iq,samplerate] = load_iq_tar_file(filename);
   ###    plot(abs(iq));
   ###
   ### See also LOAD_IQ_TAR_FILE.

   ### ============================================================================
   ### Copyright 2014-09-04 Rohde & Schwarz GmbH & Co. KG
   ###
   ### Licensed under the Apache License, Version 2.0 (the "License");
   ### you may not use this file except in compliance with the License.
   ### You may obtain a copy of the License at
   ###
   ###   http://www.apache.org/licenses/LICENSE-2.0
   ###
   ### Unless required by applicable law or agreed to in writing, software
   ### distributed under the License is distributed on an "AS IS" BASIS,
   ### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   ### See the License for the specific language governing permissions and
   ### limitations under the License.
   ### ============================================================================
   if isvector(iq):     ### Check if iq is a vector or a matrix (multi-channel signal)
       iq = iq(:);      ### force column vector
   end                  ### => the row index is the time index, the column index is the channel

   ### Assemble filename for target file
   [~, filename_base, zExt] = myFileparts(filename);

   filename_iqtar = filename;
   if isempty(zExt):
       filename_iqtar = [filename_iqtar,'.iq.tar'];
   end
   temp_dir = tempdir;              ### Temp files saved in systems temp directory

   ### Assemble filenames
   filename_iqw_base  = fullfile(temp_dir, filename_base);
   filename_xml  = fullfile(temp_dir, [filename_base, '.xml']);
   filename_xslt_pure = 'open_IqTar_xml_file_in_web_browser.xslt';
   filename_xslt = fullfile(temp_dir,filename_xslt_pure);


   ###===================================================================================
   ### Save I/Q data to binary file in float32
   ###===================================================================================
   ### Save one binary file that contains all channels interleaved
   ### Number of channels = number of columns
   ### Number of samples (same for all channels) = number of rows
   nof_channels = size(iq,2);
   nof_samples  = size(iq,1);

   [is_real_flag,FilenameWExt] = save_data_file(filename_iqw_base,iq);       ### Save binary file


   ###===================================================================================
   ### Write xml file
   ###===================================================================================
   Format = 'complex';                 ### Determine <Format>
   if is_real_flag
       Format = 'real';
   end

   ### Assemble text for <Comment>
   ChannelTxt = '';
   if nof_channels > 1
       ChannelTxt = sprintf(' in ###u channels',nof_channels);
   end
   Comment = sprintf('###u ###s samples###s captured by ###s.m (MATLAB ###s) on ###s',nof_samples,Format,ChannelTxt,mfilename,version,datestr(now, 'yyyy-mm-ddTHH:MM:SS'));

   fid = fopen(filename_xml, 'w', 'native', 'UTF-8');          ### save as xml file
   if fid ~= -1
       ### File could be opened
       fprintf(fid,'<?xml version="1.0" encoding="UTF-8"?>\n');
       fprintf(fid,'<!-- Please open this xml file in the web browser. If the stylesheet ''open_IqTar_xml_file_in_web_browser.xslt'' is in the same directory the web browser can nicely display the xml file. -->\n');
       fprintf(fid,'<?xml-stylesheet type="text/xsl" href="###s"?>\n',filename_xslt_pure);
       ### Please increase fileFormatVersion whenever the format is changed!
       fprintf(fid,'<RS_IQ_TAR_FileFormat fileFormatVersion="2" xsi:noNamespaceSchemaLocation="http://www.rohde-schwarz.com/file/RsIqTar.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n');
       fprintf(fid,'  <Name>###s.m (MATLAB ###s)</Name>\n',mfilename,version);
       fprintf(fid,'  <Comment>###s</Comment>\n',Comment);
       fprintf(fid,'  <DateTime>###s</DateTime>\n',datestr(now, 'yyyy-mm-ddTHH:MM:SS')); ### xs:dateTime format
       fprintf(fid,'  <Samples>###u</Samples>\n',nof_samples);
       fprintf(fid,'  <Clock unit="Hz">###f</Clock>\n',samplerate);
       fprintf(fid,'  <Format>###s</Format>\n',Format);
       fprintf(fid,'  <DataType>float32</DataType>\n'); ### fix here to match "save_iqw_file"
       
       fprintf(fid,'  <ScalingFactor unit="V">1</ScalingFactor>\n');
       
       if nof_channels > 1
           fprintf(fid,'  <NumberOfChannels>###u</NumberOfChannels>\n',nof_channels);
       end
       

       [~, xml_filename_base, xml_zExt] = myFileparts(FilenameWExt);             ### Remove temporary path
       fprintf(fid,'  <DataFilename>###s</DataFilename>\n',[xml_filename_base,xml_zExt]);
       write_preview_data_to_xml(fid,iq);                                                    ### Write preview data
       
       fprintf(fid,'</RS_IQ_TAR_FileFormat>\n');
       fclose(fid);
   else
       warning('RS:CouldNotWriteFile','Could not open "###s" for writing.',filename_xml);
   end

   ###===================================================================================
   ### Creat temporary xslt (styleheet) file
   ###===================================================================================
   save_xslt_file(filename_xslt);

   ###===================================================================================
   ### Pack to tar file
   ###===================================================================================

   ### Pack files (no compression if extension~=.tgz / .gz)
   ### File order in tar: xml, data , xslt.
   temp_files_to_tar = {};
   temp_files_to_tar{end+1} = filename_xml;
   temp_files_to_tar{end+1} = FilenameWExt;
   temp_files_to_tar{end+1} = filename_xslt;
   tar(filename_iqtar,temp_files_to_tar);

   ### delete temporary files
   delete(filename_xml);
   delete(FilenameWExt);
   delete(filename_xslt);
### END OF FUNCTION


def save_data_file(filename,iq):
   ### Saves the iq data to the given filename.
   ### as dataformat always float32 is used.
   ### This function detects whether the data is complex or not.
   ### returns "true" if the iq data is real-valued
   ### iq: Vector or matrix of I/Q data
   ###     Number of channels = number of columns
   ###     Number of samples (same for all channels) = number of rows

   nof_channels = size(iq,2);
   ###nof_samples  = size(iq,1);

   is_real_flag = isreal(iq);

   FilenameWExt = filename;

   if is_real_flag               ### Add extension to filename
       FilenameWExt = [FilenameWExt,'.real'];
   else
       FilenameWExt = [FilenameWExt,'.complex'];
   end

   FilenameWExt = sprintf('###s.###.0fch',FilenameWExt,nof_channels);     ### Add number of channel information to filename
   FilenameWExt = [FilenameWExt,'.float32'];     # Always use float32 here 

   ### Do interleaving:
   ###   I/Q_[channel][index/time]
   ###   Example for 2 channels
   ###   File content = I[0][0],Q[0][0],I[1][0],Q[1][0],
   ###                  I[0][1],Q[0][1],I[1][1],Q[1][1],
   ###                  I[0][2],Q[0][2],I[1][2],Q[1][2],
   ###                  ...
   iq = iq.';
   iq = iq(:);


   if is_real_flag
       ### real-valued data
       
       ### save as iqw file, iii
       fid = fopen(FilenameWExt,'w');
       if fid ~= -1
           ### File could be opened
           fwrite(fid,single(iq),'float32');
           fclose(fid);
       else
           warning('RS:CouldNotWriteFile','Could not open "###s" for writing.',filename);
       end
       
   else
       ### complex data
       
       ### save as iqw file, iqiqiq
       fid = fopen(FilenameWExt,'w');
       if fid ~= -1
           ### File could be opened
           
           ### Write I/Q interleaved
           
           ###for k=1:length(iq)
           ###    fwrite(fid,single(real(iq(k))),'float32');
           ###    fwrite(fid,single(imag(iq(k))),'float32');
           ###end
           
           ### Speed optimized implementation
           iq = iq(:).';
           iq = [real(iq); imag(iq)];
           iq = iq(:);
           fwrite(fid, iq, 'float32');
           
           fclose(fid);
       else
           warning('RS:CouldNotWriteFile','Could not open "###s" for writing.',filename);
       end
       
   end
   return [is_real_flag,FilenameWExt]
### END OF FUNCTION



def write_preview_data_to_xml(fid,iq):
   ### Writes preview data for all channels to the xml file

   nof_channels = size(iq,2);
   ###nof_samples  = size(iq,1);

   fprintf(fid,'  <PreviewData>\n');

   fprintf(fid,'    <ArrayOfChannel length="###u">\n',nof_channels);
   for k=1:nof_channels
       fprintf(fid,'      <Channel>\n');
       if nof_channels>1
           fprintf(fid,'      <Name>Channel ###u</Name>\n',k); ### optional
           fprintf(fid,'      <Comment>Channel ###u of ###u</Comment>\n',k,nof_channels); ### optional
       end
       write_preview_data_of_one_channel_to_xml(fid,iq(:,k));
       fprintf(fid,'      </Channel>\n');
   end
   fprintf(fid,'    </ArrayOfChannel>\n');

   fprintf(fid,'  </PreviewData>\n');
### END OF FUNCTION


def write_preview_data_of_one_channel_to_xml(fid,iq):

   ### Calculate PvT preview traces
   max_nof_pvt_preview_samples = 256; ### Maximum number of PvT preview sample (256 arbitrarily chosen)
   [PvtMinTrace,PvtMaxTrace] = calc_pvt_previewdata(iq,max_nof_pvt_preview_samples);

   ### Calculate Spectrum preview traces
   fft_length_spectrum_preview = 256; ### FFT length (2^n) for spectrum preview (256 arbitrarily chosen)
   [SpectrumMinTrace,SpectrumMaxTrace] = calc_spectrum_previewdata(iq,fft_length_spectrum_preview);

   ### Calculate I/Q preview
   NofPositiveBins = 32; ### Number of bins on the positive axis (32 arbitrarily chosen)
   [iq_histo_as_vector,width,height] = calc_iq_previewdata(iq,NofPositiveBins);


   fprintf(fid,'        <PowerVsTime>\n');
   fprintf(fid,'          <Min>\n');
   fprintf(fid,'            <ArrayOfFloat length="###i">\n',length(PvtMinTrace));
   for k=1:length(PvtMinTrace)
       fprintf(fid,'              <float>###i</float>\n',floor(PvtMinTrace(k))); ### integer numbers are sufficient (no need to blow up the xml)
   end
   fprintf(fid,'            </ArrayOfFloat>\n');
   fprintf(fid,'          </Min>\n');
   fprintf(fid,'          <Max>\n');
   fprintf(fid,'            <ArrayOfFloat length="###i">\n',length(PvtMaxTrace));
   for k=1:length(PvtMaxTrace)
       fprintf(fid,'              <float>###i</float>\n',ceil(PvtMaxTrace(k))); ### integer numbers are sufficient (no need to blow up the xml)
   end
   fprintf(fid,'            </ArrayOfFloat>\n');
   fprintf(fid,'          </Max>\n');
   fprintf(fid,'        </PowerVsTime>\n');
   fprintf(fid,'        <Spectrum>\n');
   fprintf(fid,'          <Min>\n');
   fprintf(fid,'            <ArrayOfFloat length="###i">\n',length(SpectrumMinTrace));
   for k=1:length(SpectrumMinTrace)
       fprintf(fid,'              <float>###i</float>\n',floor(SpectrumMinTrace(k))); ### integer numbers are sufficient (no need to blow up the xml)
   end
   fprintf(fid,'            </ArrayOfFloat>\n');
   fprintf(fid,'          </Min>\n');
   fprintf(fid,'          <Max>\n');
   fprintf(fid,'            <ArrayOfFloat length="###i">\n',length(SpectrumMaxTrace));
   for k=1:length(SpectrumMaxTrace)
       fprintf(fid,'              <float>###i</float>\n',ceil(SpectrumMaxTrace(k))); ### integer numbers are sufficient (no need to blow up the xml)
   end
   fprintf(fid,'            </ArrayOfFloat>\n');
   fprintf(fid,'          </Max>\n');
   fprintf(fid,'        </Spectrum>\n');
   fprintf(fid,'        <IQ>\n');
   fprintf(fid,'          <Histogram width="###i" height="###i">',width,height);
   for k=1:length(iq_histo_as_vector)
       fprintf(fid,'###1i',iq_histo_as_vector(k));
   end
   fprintf(fid,'</Histogram>\n');
   fprintf(fid,'        </IQ>\n');
### END OF FUNCTION


def calc_pvt_previewdata(iq,max_nof_preview_samples):
   ### Calculates the min and max traces for the power vs time preview diagram

   if length(iq) > max_nof_preview_samples
    ### Do data reduction
    
    ### Keep it simple and ignore last samples
    decimation_factor = floor(length(iq)/max_nof_preview_samples);
    nof_ignored_samples_at_the_end = length(iq)-decimation_factor*max_nof_preview_samples;
    dBm = 20*log10(abs(iq(1:decimation_factor*max_nof_preview_samples)));
    dBm = reshape(dBm,decimation_factor,max_nof_preview_samples);
    myMax = max(dBm);
    myMin = min(dBm);
    
    ### Handle ignored sample at the end
    if  nof_ignored_samples_at_the_end > 0
        dBm = 20*log10(abs(iq(end-nof_ignored_samples_at_the_end+1:end)));
        lastMax = max(dBm);
        lastMin = min(dBm);
        myMax(end) = max(myMax(end),lastMax);
           myMin(end) = min(myMin(end),lastMin);
       end
       
       ### ready to save the preview samples
   else
       ### Use all samples
       dBm = 20*log10(abs(iq));
       myMax = dBm;
       myMin = dBm;
       ### ready to save the preview samples
   end
   return [myMin,myMax]
### END OF FUNCTION


def calc_spectrum_previewdata(iq,LFFT):
   ### Init
   myMin = Inf(LFFT,1);
   myMax = zeros(LFFT,1);
   ###myAvg = zeros(LFFT,1);

   ### overlap ]0,1[
   overlap = 0.5;
   stepInSamples = floor(LFFT*(1-overlap));

   ### Window
   fenster = blackman(LFFT);
   fenster = 1/sqrt(LFFT*mean(fenster.^2))*fenster;

   ### The other samples are ignored
   nof_blocks = floor((length(iq)-LFFT)/stepInSamples);
   for k = 0:nof_blocks-1
       idx = 1:LFFT;
       idx = idx + k*stepInSamples;
       mag2 = abs(fft(iq(idx).*fenster)).^2;
       myMin = min(myMin,mag2);
       myMax = max(myMax,mag2);
       ###myAvg = myAvg + 1/nof_blocks*mag2;
   end

   ### to dBm
   myMin = 10*log10(myMin);
   myMax = 10*log10(myMax);
   ###myAvg = 10*log10(myAvg);

   ### fftshift
   myMin = fftshift(myMin);
   myMax = fftshift(myMax);
   ###myAvg = fftshift(myAvg);
   return [myMin,myMax]
### END OF FUNCTION


def calc_iq_previewdata(iq,NofPositiveBins):
   ### Init return values
   width = 0;
   height = 0;
   iq_histo_as_vector = [];
   ### Only continue if samples present
   if ~isempty(iq)
       ### Maximum absolute value of real and imaginary part
       max_abs_I_or_Q = max(max(abs(real(iq(:)))), max(abs(imag(iq(:)))));
       
       ### Only continue if the signal is not zero
       if max_abs_I_or_Q > 0
           ### Only continue if enough bins present
           if NofPositiveBins >= 2
               width  = 2*NofPositiveBins;
               height = width;
               ### I/Q plane should be a little larger than the maximum value
               my_max = max_abs_I_or_Q*NofPositiveBins/(NofPositiveBins-1.5);
               vBins = linspace(-my_max,+my_max,width);
               ### Find bin index of real and imaginary values
               idx_col_I = interp1(vBins,1:length(vBins),real(iq(:)),'nearest');
               idx_row_Q = interp1(-vBins,1:length(vBins),imag(iq(:)),'nearest');
               z = accumarray([idx_row_Q,idx_col_I], 1, [height,width]);
               ### Quantization
               max_count = max(9, max(z(:))); ### 9*(x-1)/max_count+1>=0 for max_count>=9
               z = floor(9*(z-1)/max_count+1);
               ### Prepare vector that reads the matrix row-wise
               z = z';
               iq_histo_as_vector = z(:);
           end
       end
   end
   return [iq_histo_as_vector,width,height]
### END OF FUNCTION


def myFileparts(filename):
   Ext =[];
   [Pathstr, Name, zExt] = fileparts(filename);
   while ~isempty(zExt)
       Ext = [zExt,Ext]; 
       [~, Name, zExt] = fileparts(Name);
   end
   return [Pathstr, Name, Ext] 
### END OF FUNCTION


def save_xslt_file(filename):
   fid=fopen(filename,'w');
   fprintf(fid,'<?xml version="1.0" encoding="UTF-8"?>\r\n');
   fprintf(fid,'<!--\r\n');
   fprintf(fid,'============================================================================\r\n');
   fprintf(fid,'Copyright 2011-05-24 Rohde & Schwarz GmbH & Co. KG\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'Licensed under the Apache License, Version 2.0 (the "License");\r\n');
   fprintf(fid,'you may not use this file except in compliance with the License.\r\n');
   fprintf(fid,'You may obtain a copy of the License at\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  http://www.apache.org/licenses/LICENSE-2.0\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'Unless required by applicable law or agreed to in writing, software\r\n');
   fprintf(fid,'distributed under the License is distributed on an "AS IS" BASIS,\r\n');
   fprintf(fid,'WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\r\n');
   fprintf(fid,'See the License for the specific language governing permissions and\r\n');
   fprintf(fid,'limitations under the License.\r\n');
   fprintf(fid,'============================================================================\r\n');
   fprintf(fid,'Includes jquery-1.4.2.min.js\r\n');
   fprintf(fid,'  jQuery JavaScript Library v1.4.2\r\n');
   fprintf(fid,'  http://jquery.com/\r\n');
   fprintf(fid,'  Copyright 2010, John Resig\r\n');
   fprintf(fid,'  Released under the MIT and GPL Version 2 licenses.\r\n');
   fprintf(fid,'============================================================================\r\n');
   fprintf(fid,'Includes excanvas.compiled.js\r\n');
   fprintf(fid,'  explorercanvas HTML5 Canvas for Internet Explorer (r3)\r\n');
   fprintf(fid,'  http://code.google.com/p/explorercanvas/\r\n');
   fprintf(fid,'  Copyright 2006 Google Inc.\r\n');
   fprintf(fid,'  Released under the Apache License, Version 2.0.\r\n');
   fprintf(fid,'============================================================================\r\n');
   fprintf(fid,'                                 Apache License\r\n');
   fprintf(fid,'                           Version 2.0, January 2004\r\n');
   fprintf(fid,'                        http://www.apache.org/licenses/\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'   1. Definitions.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      "License" shall mean the terms and conditions for use, reproduction,\r\n');
   fprintf(fid,'      and distribution as defined by Sections 1 through 9 of this document.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      "Licensor" shall mean the copyright owner or entity authorized by\r\n');
   fprintf(fid,'      the copyright owner that is granting the License.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      "Legal Entity" shall mean the union of the acting entity and all\r\n');
   fprintf(fid,'      other entities that control, are controlled by, or are under common\r\n');
   fprintf(fid,'      control with that entity. For the purposes of this definition,\r\n');
   fprintf(fid,'      "control" means (i) the power, direct or indirect, to cause the\r\n');
   fprintf(fid,'      direction or management of such entity, whether by contract or\r\n');
   fprintf(fid,'      otherwise, or (ii) ownership of fifty percent (50######) or more of the\r\n');
   fprintf(fid,'      outstanding shares, or (iii) beneficial ownership of such entity.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      "You" (or "Your") shall mean an individual or Legal Entity\r\n');
   fprintf(fid,'      exercising permissions granted by this License.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      "Source" form shall mean the preferred form for making modifications,\r\n');
   fprintf(fid,'      including but not limited to software source code, documentation\r\n');
   fprintf(fid,'      source, and configuration files.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      "Object" form shall mean any form resulting from mechanical\r\n');
   fprintf(fid,'      transformation or translation of a Source form, including but\r\n');
   fprintf(fid,'      not limited to compiled object code, generated documentation,\r\n');
   fprintf(fid,'      and conversions to other media types.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      "Work" shall mean the work of authorship, whether in Source or\r\n');
   fprintf(fid,'      Object form, made available under the License, as indicated by a\r\n');
   fprintf(fid,'      copyright notice that is included in or attached to the work\r\n');
   fprintf(fid,'      (an example is provided in the Appendix below).\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      "Derivative Works" shall mean any work, whether in Source or Object\r\n');
   fprintf(fid,'      form, that is based on (or derived from) the Work and for which the\r\n');
   fprintf(fid,'      editorial revisions, annotations, elaborations, or other modifications\r\n');
   fprintf(fid,'      represent, as a whole, an original work of authorship. For the purposes\r\n');
   fprintf(fid,'      of this License, Derivative Works shall not include works that remain\r\n');
   fprintf(fid,'      separable from, or merely link (or bind by name) to the interfaces of,\r\n');
   fprintf(fid,'      the Work and Derivative Works thereof.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      "Contribution" shall mean any work of authorship, including\r\n');
   fprintf(fid,'      the original version of the Work and any modifications or additions\r\n');
   fprintf(fid,'      to that Work or Derivative Works thereof, that is intentionally\r\n');
   fprintf(fid,'      submitted to Licensor for inclusion in the Work by the copyright owner\r\n');
   fprintf(fid,'      or by an individual or Legal Entity authorized to submit on behalf of\r\n');
   fprintf(fid,'      the copyright owner. For the purposes of this definition, "submitted"\r\n');
   fprintf(fid,'      means any form of electronic, verbal, or written communication sent\r\n');
   fprintf(fid,'      to the Licensor or its representatives, including but not limited to\r\n');
   fprintf(fid,'      communication on electronic mailing lists, source code control systems,\r\n');
   fprintf(fid,'      and issue tracking systems that are managed by, or on behalf of, the\r\n');
   fprintf(fid,'      Licensor for the purpose of discussing and improving the Work, but\r\n');
   fprintf(fid,'      excluding communication that is conspicuously marked or otherwise\r\n');
   fprintf(fid,'      designated in writing by the copyright owner as "Not a Contribution."\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      "Contributor" shall mean Licensor and any individual or Legal Entity\r\n');
   fprintf(fid,'      on behalf of whom a Contribution has been received by Licensor and\r\n');
   fprintf(fid,'      subsequently incorporated within the Work.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'   2. Grant of Copyright License. Subject to the terms and conditions of\r\n');
   fprintf(fid,'      this License, each Contributor hereby grants to You a perpetual,\r\n');
   fprintf(fid,'      worldwide, non-exclusive, no-charge, royalty-free, irrevocable\r\n');
   fprintf(fid,'      copyright license to reproduce, prepare Derivative Works of,\r\n');
   fprintf(fid,'      publicly display, publicly perform, sublicense, and distribute the\r\n');
   fprintf(fid,'      Work and such Derivative Works in Source or Object form.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'   3. Grant of Patent License. Subject to the terms and conditions of\r\n');
   fprintf(fid,'      this License, each Contributor hereby grants to You a perpetual,\r\n');
   fprintf(fid,'      worldwide, non-exclusive, no-charge, royalty-free, irrevocable\r\n');
   fprintf(fid,'      (except as stated in this section) patent license to make, have made,\r\n');
   fprintf(fid,'      use, offer to sell, sell, import, and otherwise transfer the Work,\r\n');
   fprintf(fid,'      where such license applies only to those patent claims licensable\r\n');
   fprintf(fid,'      by such Contributor that are necessarily infringed by their\r\n');
   fprintf(fid,'      Contribution(s) alone or by combination of their Contribution(s)\r\n');
   fprintf(fid,'      with the Work to which such Contribution(s) was submitted. If You\r\n');
   fprintf(fid,'      institute patent litigation against any entity (including a\r\n');
   fprintf(fid,'      cross-claim or counterclaim in a lawsuit) alleging that the Work\r\n');
   fprintf(fid,'      or a Contribution incorporated within the Work constitutes direct\r\n');
   fprintf(fid,'      or contributory patent infringement, then any patent licenses\r\n');
   fprintf(fid,'      granted to You under this License for that Work shall terminate\r\n');
   fprintf(fid,'      as of the date such litigation is filed.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'   4. Redistribution. You may reproduce and distribute copies of the\r\n');
   fprintf(fid,'      Work or Derivative Works thereof in any medium, with or without\r\n');
   fprintf(fid,'      modifications, and in Source or Object form, provided that You\r\n');
   fprintf(fid,'      meet the following conditions:\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      (a) You must give any other recipients of the Work or\r\n');
   fprintf(fid,'          Derivative Works a copy of this License; and\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      (b) You must cause any modified files to carry prominent notices\r\n');
   fprintf(fid,'          stating that You changed the files; and\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      (c) You must retain, in the Source form of any Derivative Works\r\n');
   fprintf(fid,'          that You distribute, all copyright, patent, trademark, and\r\n');
   fprintf(fid,'          attribution notices from the Source form of the Work,\r\n');
   fprintf(fid,'          excluding those notices that do not pertain to any part of\r\n');
   fprintf(fid,'          the Derivative Works; and\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      (d) If the Work includes a "NOTICE" text file as part of its\r\n');
   fprintf(fid,'          distribution, then any Derivative Works that You distribute must\r\n');
   fprintf(fid,'          include a readable copy of the attribution notices contained\r\n');
   fprintf(fid,'          within such NOTICE file, excluding those notices that do not\r\n');
   fprintf(fid,'          pertain to any part of the Derivative Works, in at least one\r\n');
   fprintf(fid,'          of the following places: within a NOTICE text file distributed\r\n');
   fprintf(fid,'          as part of the Derivative Works; within the Source form or\r\n');
   fprintf(fid,'          documentation, if provided along with the Derivative Works; or,\r\n');
   fprintf(fid,'          within a display generated by the Derivative Works, if and\r\n');
   fprintf(fid,'          wherever such third-party notices normally appear. The contents\r\n');
   fprintf(fid,'          of the NOTICE file are for informational purposes only and\r\n');
   fprintf(fid,'          do not modify the License. You may add Your own attribution\r\n');
   fprintf(fid,'          notices within Derivative Works that You distribute, alongside\r\n');
   fprintf(fid,'          or as an addendum to the NOTICE text from the Work, provided\r\n');
   fprintf(fid,'          that such additional attribution notices cannot be construed\r\n');
   fprintf(fid,'          as modifying the License.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      You may add Your own copyright statement to Your modifications and\r\n');
   fprintf(fid,'      may provide additional or different license terms and conditions\r\n');
   fprintf(fid,'      for use, reproduction, or distribution of Your modifications, or\r\n');
   fprintf(fid,'      for any such Derivative Works as a whole, provided Your use,\r\n');
   fprintf(fid,'      reproduction, and distribution of the Work otherwise complies with\r\n');
   fprintf(fid,'      the conditions stated in this License.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'   5. Submission of Contributions. Unless You explicitly state otherwise,\r\n');
   fprintf(fid,'      any Contribution intentionally submitted for inclusion in the Work\r\n');
   fprintf(fid,'      by You to the Licensor shall be under the terms and conditions of\r\n');
   fprintf(fid,'      this License, without any additional terms or conditions.\r\n');
   fprintf(fid,'      Notwithstanding the above, nothing herein shall supersede or modify\r\n');
   fprintf(fid,'      the terms of any separate license agreement you may have executed\r\n');
   fprintf(fid,'      with Licensor regarding such Contributions.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'   6. Trademarks. This License does not grant permission to use the trade\r\n');
   fprintf(fid,'      names, trademarks, service marks, or product names of the Licensor,\r\n');
   fprintf(fid,'      except as required for reasonable and customary use in describing the\r\n');
   fprintf(fid,'      origin of the Work and reproducing the content of the NOTICE file.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'   7. Disclaimer of Warranty. Unless required by applicable law or\r\n');
   fprintf(fid,'      agreed to in writing, Licensor provides the Work (and each\r\n');
   fprintf(fid,'      Contributor provides its Contributions) on an "AS IS" BASIS,\r\n');
   fprintf(fid,'      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or\r\n');
   fprintf(fid,'      implied, including, without limitation, any warranties or conditions\r\n');
   fprintf(fid,'      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A\r\n');
   fprintf(fid,'      PARTICULAR PURPOSE. You are solely responsible for determining the\r\n');
   fprintf(fid,'      appropriateness of using or redistributing the Work and assume any\r\n');
   fprintf(fid,'      risks associated with Your exercise of permissions under this License.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'   8. Limitation of Liability. In no event and under no legal theory,\r\n');
   fprintf(fid,'      whether in tort (including negligence), contract, or otherwise,\r\n');
   fprintf(fid,'      unless required by applicable law (such as deliberate and grossly\r\n');
   fprintf(fid,'      negligent acts) or agreed to in writing, shall any Contributor be\r\n');
   fprintf(fid,'      liable to You for damages, including any direct, indirect, special,\r\n');
   fprintf(fid,'      incidental, or consequential damages of any character arising as a\r\n');
   fprintf(fid,'      result of this License or out of the use or inability to use the\r\n');
   fprintf(fid,'      Work (including but not limited to damages for loss of goodwill,\r\n');
   fprintf(fid,'      work stoppage, computer failure or malfunction, or any and all\r\n');
   fprintf(fid,'      other commercial damages or losses), even if such Contributor\r\n');
   fprintf(fid,'      has been advised of the possibility of such damages.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'   9. Accepting Warranty or Additional Liability. While redistributing\r\n');
   fprintf(fid,'      the Work or Derivative Works thereof, You may choose to offer,\r\n');
   fprintf(fid,'      and charge a fee for, acceptance of support, warranty, indemnity,\r\n');
   fprintf(fid,'      or other liability obligations and/or rights consistent with this\r\n');
   fprintf(fid,'      License. However, in accepting such obligations, You may act only\r\n');
   fprintf(fid,'      on Your own behalf and on Your sole responsibility, not on behalf\r\n');
   fprintf(fid,'      of any other Contributor, and only if You agree to indemnify,\r\n');
   fprintf(fid,'      defend, and hold each Contributor harmless for any liability\r\n');
   fprintf(fid,'      incurred by, or claims asserted against, such Contributor by reason\r\n');
   fprintf(fid,'      of your accepting any such warranty or additional liability.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'   END OF TERMS AND CONDITIONS\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'   APPENDIX: How to apply the Apache License to your work.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'      To apply the Apache License to your work, attach the following\r\n');
   fprintf(fid,'      boilerplate notice, with the fields enclosed by brackets "[]"\r\n');
   fprintf(fid,'      replaced with your own identifying information. (Don''t include\r\n');
   fprintf(fid,'      the brackets!)  The text should be enclosed in the appropriate\r\n');
   fprintf(fid,'      comment syntax for the file format. We also recommend that a\r\n');
   fprintf(fid,'      file or class name and description of purpose be included on the\r\n');
   fprintf(fid,'      same "printed page" as the copyright notice for easier\r\n');
   fprintf(fid,'      identification within third-party archives.\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'   Copyright [yyyy] [name of copyright owner]\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'   Licensed under the Apache License, Version 2.0 (the "License");\r\n');
   fprintf(fid,'   you may not use this file except in compliance with the License.\r\n');
   fprintf(fid,'   You may obtain a copy of the License at\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'       http://www.apache.org/licenses/LICENSE-2.0\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'   Unless required by applicable law or agreed to in writing, software\r\n');
   fprintf(fid,'   distributed under the License is distributed on an "AS IS" BASIS,\r\n');
   fprintf(fid,'   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\r\n');
   fprintf(fid,'   See the License for the specific language governing permissions and\r\n');
   fprintf(fid,'   limitations under the License.\r\n');
   fprintf(fid,'============================================================================\r\n');
   fprintf(fid,'-->\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">\r\n');
   fprintf(fid,'<xsl:output version="1.0" encoding="UTF-8" indent="no" omit-xml-declaration="no" media-type="text/html"/>\r\n');
   fprintf(fid,'  \r\n');
   fprintf(fid,'<xsl:template match="/RS_IQ_TAR_FileFormat">\r\n');
   fprintf(fid,'    <html>\r\n');
   fprintf(fid,'      <head>\r\n');
   fprintf(fid,'      <!-- jQuery must be included before excanvas -->\r\n');
   fprintf(fid,'      <!--<script type="text/javascript" src="jquery-1.4.2.min.js" ></script>-->\r\n');
   fprintf(fid,'      <script type="text/javascript" >\r\n');
   fprintf(fid,'      <xsl:text disable-output-escaping="yes">\r\n');
   fprintf(fid,'        <!-- ############################################################################################### -->\r\n');
   fprintf(fid,'        <!-- ### Start: Embedded jQuery source ''jquery-1.4.2.min.js''                                    #### -->\r\n');
   fprintf(fid,'        <!-- ############################################################################################### -->\r\n');
   fprintf(fid,'        <![CDATA[\r\n');
   fprintf(fid,'          /*!\r\n');
   fprintf(fid,'           * jQuery JavaScript Library v1.4.2\r\n');
   fprintf(fid,'           * http://jquery.com/\r\n');
   fprintf(fid,'           *\r\n');
   fprintf(fid,'           * Copyright 2010, John Resig\r\n');
   fprintf(fid,'           * Dual licensed under the MIT or GPL Version 2 licenses.\r\n');
   fprintf(fid,'           * http://jquery.org/license\r\n');
   fprintf(fid,'           *\r\n');
   fprintf(fid,'           * Includes Sizzle.js\r\n');
   fprintf(fid,'           * http://sizzlejs.com/\r\n');
   fprintf(fid,'           * Copyright 2010, The Dojo Foundation\r\n');
   fprintf(fid,'           * Released under the MIT, BSD, and GPL Licenses.\r\n');
   fprintf(fid,'           *\r\n');
   fprintf(fid,'           * Date: Sat Feb 13 22:33:48 2010 -0500\r\n');
   fprintf(fid,'           */\r\n');
   fprintf(fid,'          (function(A,w){function ma(){if(!c.isReady){try{s.documentElement.doScroll("left")}catch(a){setTimeout(ma,1);return}c.ready()}}function Qa(a,b){b.src?c.ajax({url:b.src,async:false,dataType:"script"}):c.globalEval(b.text||b.textContent||b.innerHTML||"");b.parentNode&&b.parentNode.removeChild(b)}function X(a,b,d,f,e,j){var i=a.length;if(typeof b==="object"){for(var o in b)X(a,o,b[o],f,e,d);return a}if(d!==w){f=!j&&f&&c.isFunction(d);for(o=0;o<i;o++)e(a[o],b,f?d.call(a[o],o,e(a[o],b)):d,j);return a}return i?\r\n');
   fprintf(fid,'          e(a[0],b):w}function J(){return(new Date).getTime()}function Y(){return false}function Z(){return true}function na(a,b,d){d[0].type=a;return c.event.handle.apply(b,d)}function oa(a){var b,d=[],f=[],e=arguments,j,i,o,k,n,r;i=c.data(this,"events");if(!(a.liveFired===this||!i||!i.live||a.button&&a.type==="click")){a.liveFired=this;var u=i.live.slice(0);for(k=0;k<u.length;k++){i=u[k];i.origType.replace(O,"")===a.type?f.push(i.selector):u.splice(k--,1)}j=c(a.target).closest(f,a.currentTarget);n=0;for(r=\r\n');
   fprintf(fid,'          j.length;n<r;n++)for(k=0;k<u.length;k++){i=u[k];if(j[n].selector===i.selector){o=j[n].elem;f=null;if(i.preType==="mouseenter"||i.preType==="mouseleave")f=c(a.relatedTarget).closest(i.selector)[0];if(!f||f!==o)d.push({elem:o,handleObj:i})}}n=0;for(r=d.length;n<r;n++){j=d[n];a.currentTarget=j.elem;a.data=j.handleObj.data;a.handleObj=j.handleObj;if(j.handleObj.origHandler.apply(j.elem,e)===false){b=false;break}}return b}}function pa(a,b){return"live."+(a&&a!=="*"?a+".":"")+b.replace(/\\./g,"`").replace(/ /g,\r\n');
   fprintf(fid,'          "&")}function qa(a){return!a||!a.parentNode||a.parentNode.nodeType===11}function ra(a,b){var d=0;b.each(function(){if(this.nodeName===(a[d]&&a[d].nodeName)){var f=c.data(a[d++]),e=c.data(this,f);if(f=f&&f.events){delete e.handle;e.events={};for(var j in f)for(var i in f[j])c.event.add(this,j,f[j][i],f[j][i].data)}}})}function sa(a,b,d){var f,e,j;b=b&&b[0]?b[0].ownerDocument||b[0]:s;if(a.length===1&&typeof a[0]==="string"&&a[0].length<512&&b===s&&!ta.test(a[0])&&(c.support.checkClone||!ua.test(a[0]))){e=\r\n');
   fprintf(fid,'          true;if(j=c.fragments[a[0]])if(j!==1)f=j}if(!f){f=b.createDocumentFragment();c.clean(a,b,f,d)}if(e)c.fragments[a[0]]=j?f:1;return{fragment:f,cacheable:e}}function K(a,b){var d={};c.each(va.concat.apply([],va.slice(0,b)),function(){d[this]=a});return d}function wa(a){return"scrollTo"in a&&a.document?a:a.nodeType===9?a.defaultView||a.parentWindow:false}var c=function(a,b){return new c.fn.init(a,b)},Ra=A.jQuery,Sa=A.$,s=A.document,T,Ta=/^[^<]*(<[\\w\\W]+>)[^>]*$|^#([\\w-]+)$/,Ua=/^.[^:#\\[\\.,]*$/,Va=/\\S/,\r\n');
   fprintf(fid,'          Wa=/^(\\s|\\u00A0)+|(\\s|\\u00A0)+$/g,Xa=/^<(\\w+)\\s*\\/?>(?:<\\/\\1>)?$/,P=navigator.userAgent,xa=false,Q=[],L,$=Object.prototype.toString,aa=Object.prototype.hasOwnProperty,ba=Array.prototype.push,R=Array.prototype.slice,ya=Array.prototype.indexOf;c.fn=c.prototype={init:function(a,b){var d,f;if(!a)return this;if(a.nodeType){this.context=this[0]=a;this.length=1;return this}if(a==="body"&&!b){this.context=s;this[0]=s.body;this.selector="body";this.length=1;return this}if(typeof a==="string")if((d=Ta.exec(a))&&\r\n');
   fprintf(fid,'          (d[1]||!b))if(d[1]){f=b?b.ownerDocument||b:s;if(a=Xa.exec(a))if(c.isPlainObject(b)){a=[s.createElement(a[1])];c.fn.attr.call(a,b,true)}else a=[f.createElement(a[1])];else{a=sa([d[1]],[f]);a=(a.cacheable?a.fragment.cloneNode(true):a.fragment).childNodes}return c.merge(this,a)}else{if(b=s.getElementById(d[2])){if(b.id!==d[2])return T.find(a);this.length=1;this[0]=b}this.context=s;this.selector=a;return this}else if(!b&&/^\\w+$/.test(a)){this.selector=a;this.context=s;a=s.getElementsByTagName(a);return c.merge(this,\r\n');
   fprintf(fid,'          a)}else return!b||b.jquery?(b||T).find(a):c(b).find(a);else if(c.isFunction(a))return T.ready(a);if(a.selector!==w){this.selector=a.selector;this.context=a.context}return c.makeArray(a,this)},selector:"",jquery:"1.4.2",length:0,size:function(){return this.length},toArray:function(){return R.call(this,0)},get:function(a){return a==null?this.toArray():a<0?this.slice(a)[0]:this[a]},pushStack:function(a,b,d){var f=c();c.isArray(a)?ba.apply(f,a):c.merge(f,a);f.prevObject=this;f.context=this.context;if(b===\r\n');
   fprintf(fid,'          "find")f.selector=this.selector+(this.selector?" ":"")+d;else if(b)f.selector=this.selector+"."+b+"("+d+")";return f},each:function(a,b){return c.each(this,a,b)},ready:function(a){c.bindReady();if(c.isReady)a.call(s,c);else Q&&Q.push(a);return this},eq:function(a){return a===-1?this.slice(a):this.slice(a,+a+1)},first:function(){return this.eq(0)},last:function(){return this.eq(-1)},slice:function(){return this.pushStack(R.apply(this,arguments),"slice",R.call(arguments).join(","))},map:function(a){return this.pushStack(c.map(this,\r\n');
   fprintf(fid,'          function(b,d){return a.call(b,d,b)}))},end:function(){return this.prevObject||c(null)},push:ba,sort:[].sort,splice:[].splice};c.fn.init.prototype=c.fn;c.extend=c.fn.extend=function(){var a=arguments[0]||{},b=1,d=arguments.length,f=false,e,j,i,o;if(typeof a==="boolean"){f=a;a=arguments[1]||{};b=2}if(typeof a!=="object"&&!c.isFunction(a))a={};if(d===b){a=this;--b}for(;b<d;b++)if((e=arguments[b])!=null)for(j in e){i=a[j];o=e[j];if(a!==o)if(f&&o&&(c.isPlainObject(o)||c.isArray(o))){i=i&&(c.isPlainObject(i)||\r\n');
   fprintf(fid,'          c.isArray(i))?i:c.isArray(o)?[]:{};a[j]=c.extend(f,i,o)}else if(o!==w)a[j]=o}return a};c.extend({noConflict:function(a){A.$=Sa;if(a)A.jQuery=Ra;return c},isReady:false,ready:function(){if(!c.isReady){if(!s.body)return setTimeout(c.ready,13);c.isReady=true;if(Q){for(var a,b=0;a=Q[b++];)a.call(s,c);Q=null}c.fn.triggerHandler&&c(s).triggerHandler("ready")}},bindReady:function(){if(!xa){xa=true;if(s.readyState==="complete")return c.ready();if(s.addEventListener){s.addEventListener("DOMContentLoaded",\r\n');
   fprintf(fid,'          L,false);A.addEventListener("load",c.ready,false)}else if(s.attachEvent){s.attachEvent("onreadystatechange",L);A.attachEvent("onload",c.ready);var a=false;try{a=A.frameElement==null}catch(b){}s.documentElement.doScroll&&a&&ma()}}},isFunction:function(a){return $.call(a)==="[object Function]"},isArray:function(a){return $.call(a)==="[object Array]"},isPlainObject:function(a){if(!a||$.call(a)!=="[object Object]"||a.nodeType||a.setInterval)return false;if(a.constructor&&!aa.call(a,"constructor")&&!aa.call(a.constructor.prototype,\r\n');
   fprintf(fid,'          "isPrototypeOf"))return false;var b;for(b in a);return b===w||aa.call(a,b)},isEmptyObject:function(a){for(var b in a)return false;return true},error:function(a){throw a;},parseJSON:function(a){if(typeof a!=="string"||!a)return null;a=c.trim(a);if(/^[\\],:{}\\s]*$/.test(a.replace(/\\\\(?:["\\\\\\/bfnrt]|u[0-9a-fA-F]{4})/g,"@").replace(/"[^"\\\\\\n\\r]*"|true|false|null|-?\\d+(?:\\.\\d*)?(?:[eE][+\\-]?\\d+)?/g,"]").replace(/(?:^|:|,)(?:\\s*\\[)+/g,"")))return A.JSON&&A.JSON.parse?A.JSON.parse(a):(new Function("return "+\r\n');
   fprintf(fid,'          a))();else c.error("Invalid JSON: "+a)},noop:function(){},globalEval:function(a){if(a&&Va.test(a)){var b=s.getElementsByTagName("head")[0]||s.documentElement,d=s.createElement("script");d.type="text/javascript";if(c.support.scriptEval)d.appendChild(s.createTextNode(a));else d.text=a;b.insertBefore(d,b.firstChild);b.removeChild(d)}},nodeName:function(a,b){return a.nodeName&&a.nodeName.toUpperCase()===b.toUpperCase()},each:function(a,b,d){var f,e=0,j=a.length,i=j===w||c.isFunction(a);if(d)if(i)for(f in a){if(b.apply(a[f],\r\n');
   fprintf(fid,'          d)===false)break}else for(;e<j;){if(b.apply(a[e++],d)===false)break}else if(i)for(f in a){if(b.call(a[f],f,a[f])===false)break}else for(d=a[0];e<j&&b.call(d,e,d)!==false;d=a[++e]);return a},trim:function(a){return(a||"").replace(Wa,"")},makeArray:function(a,b){b=b||[];if(a!=null)a.length==null||typeof a==="string"||c.isFunction(a)||typeof a!=="function"&&a.setInterval?ba.call(b,a):c.merge(b,a);return b},inArray:function(a,b){if(b.indexOf)return b.indexOf(a);for(var d=0,f=b.length;d<f;d++)if(b[d]===\r\n');
   fprintf(fid,'          a)return d;return-1},merge:function(a,b){var d=a.length,f=0;if(typeof b.length==="number")for(var e=b.length;f<e;f++)a[d++]=b[f];else for(;b[f]!==w;)a[d++]=b[f++];a.length=d;return a},grep:function(a,b,d){for(var f=[],e=0,j=a.length;e<j;e++)!d!==!b(a[e],e)&&f.push(a[e]);return f},map:function(a,b,d){for(var f=[],e,j=0,i=a.length;j<i;j++){e=b(a[j],j,d);if(e!=null)f[f.length]=e}return f.concat.apply([],f)},guid:1,proxy:function(a,b,d){if(arguments.length===2)if(typeof b==="string"){d=a;a=d[b];b=w}else if(b&&\r\n');
   fprintf(fid,'          !c.isFunction(b)){d=b;b=w}if(!b&&a)b=function(){return a.apply(d||this,arguments)};if(a)b.guid=a.guid=a.guid||b.guid||c.guid++;return b},uaMatch:function(a){a=a.toLowerCase();a=/(webkit)[ \\/]([\\w.]+)/.exec(a)||/(opera)(?:.*version)?[ \\/]([\\w.]+)/.exec(a)||/(msie) ([\\w.]+)/.exec(a)||!/compatible/.test(a)&&/(mozilla)(?:.*? rv:([\\w.]+))?/.exec(a)||[];return{browser:a[1]||"",version:a[2]||"0"}},browser:{}});P=c.uaMatch(P);if(P.browser){c.browser[P.browser]=true;c.browser.version=P.version}if(c.browser.webkit)c.browser.safari=\r\n');
   fprintf(fid,'          true;if(ya)c.inArray=function(a,b){return ya.call(b,a)};T=c(s);if(s.addEventListener)L=function(){s.removeEventListener("DOMContentLoaded",L,false);c.ready()};else if(s.attachEvent)L=function(){if(s.readyState==="complete"){s.detachEvent("onreadystatechange",L);c.ready()}};(function(){c.support={};var a=s.documentElement,b=s.createElement("script"),d=s.createElement("div"),f="script"+J();d.style.display="none";d.innerHTML="   <link/><table></table><a href=''/a'' style=''color:red;float:left;opacity:.55;''>a</a><input type=''checkbox''/>";\r\n');
   fprintf(fid,'          var e=d.getElementsByTagName("*"),j=d.getElementsByTagName("a")[0];if(!(!e||!e.length||!j)){c.support={leadingWhitespace:d.firstChild.nodeType===3,tbody:!d.getElementsByTagName("tbody").length,htmlSerialize:!!d.getElementsByTagName("link").length,style:/red/.test(j.getAttribute("style")),hrefNormalized:j.getAttribute("href")==="/a",opacity:/^0.55$/.test(j.style.opacity),cssFloat:!!j.style.cssFloat,checkOn:d.getElementsByTagName("input")[0].value==="on",optSelected:s.createElement("select").appendChild(s.createElement("option")).selected,\r\n');
   fprintf(fid,'          parentNode:d.removeChild(d.appendChild(s.createElement("div"))).parentNode===null,deleteExpando:true,checkClone:false,scriptEval:false,noCloneEvent:true,boxModel:null};b.type="text/javascript";try{b.appendChild(s.createTextNode("window."+f+"=1;"))}catch(i){}a.insertBefore(b,a.firstChild);if(A[f]){c.support.scriptEval=true;delete A[f]}try{delete b.test}catch(o){c.support.deleteExpando=false}a.removeChild(b);if(d.attachEvent&&d.fireEvent){d.attachEvent("onclick",function k(){c.support.noCloneEvent=\r\n');
   fprintf(fid,'          false;d.detachEvent("onclick",k)});d.cloneNode(true).fireEvent("onclick")}d=s.createElement("div");d.innerHTML="<input type=''radio'' name=''radiotest'' checked=''checked''/>";a=s.createDocumentFragment();a.appendChild(d.firstChild);c.support.checkClone=a.cloneNode(true).cloneNode(true).lastChild.checked;c(function(){var k=s.createElement("div");k.style.width=k.style.paddingLeft="1px";s.body.appendChild(k);c.boxModel=c.support.boxModel=k.offsetWidth===2;s.body.removeChild(k).style.display="none"});a=function(k){var n=\r\n');
   fprintf(fid,'          s.createElement("div");k="on"+k;var r=k in n;if(!r){n.setAttribute(k,"return;");r=typeof n[k]==="function"}return r};c.support.submitBubbles=a("submit");c.support.changeBubbles=a("change");a=b=d=e=j=null}})();c.props={"for":"htmlFor","class":"className",readonly:"readOnly",maxlength:"maxLength",cellspacing:"cellSpacing",rowspan:"rowSpan",colspan:"colSpan",tabindex:"tabIndex",usemap:"useMap",frameborder:"frameBorder"};var G="jQuery"+J(),Ya=0,za={};c.extend({cache:{},expando:G,noData:{embed:true,object:true,\r\n');
   fprintf(fid,'          applet:true},data:function(a,b,d){if(!(a.nodeName&&c.noData[a.nodeName.toLowerCase()])){a=a==A?za:a;var f=a[G],e=c.cache;if(!f&&typeof b==="string"&&d===w)return null;f||(f=++Ya);if(typeof b==="object"){a[G]=f;e[f]=c.extend(true,{},b)}else if(!e[f]){a[G]=f;e[f]={}}a=e[f];if(d!==w)a[b]=d;return typeof b==="string"?a[b]:a}},removeData:function(a,b){if(!(a.nodeName&&c.noData[a.nodeName.toLowerCase()])){a=a==A?za:a;var d=a[G],f=c.cache,e=f[d];if(b){if(e){delete e[b];c.isEmptyObject(e)&&c.removeData(a)}}else{if(c.support.deleteExpando)delete a[c.expando];\r\n');
   fprintf(fid,'          else a.removeAttribute&&a.removeAttribute(c.expando);delete f[d]}}}});c.fn.extend({data:function(a,b){if(typeof a==="undefined"&&this.length)return c.data(this[0]);else if(typeof a==="object")return this.each(function(){c.data(this,a)});var d=a.split(".");d[1]=d[1]?"."+d[1]:"";if(b===w){var f=this.triggerHandler("getData"+d[1]+"!",[d[0]]);if(f===w&&this.length)f=c.data(this[0],a);return f===w&&d[1]?this.data(d[0]):f}else return this.trigger("setData"+d[1]+"!",[d[0],b]).each(function(){c.data(this,\r\n');
   fprintf(fid,'          a,b)})},removeData:function(a){return this.each(function(){c.removeData(this,a)})}});c.extend({queue:function(a,b,d){if(a){b=(b||"fx")+"queue";var f=c.data(a,b);if(!d)return f||[];if(!f||c.isArray(d))f=c.data(a,b,c.makeArray(d));else f.push(d);return f}},dequeue:function(a,b){b=b||"fx";var d=c.queue(a,b),f=d.shift();if(f==="inprogress")f=d.shift();if(f){b==="fx"&&d.unshift("inprogress");f.call(a,function(){c.dequeue(a,b)})}}});c.fn.extend({queue:function(a,b){if(typeof a!=="string"){b=a;a="fx"}if(b===\r\n');
   fprintf(fid,'          w)return c.queue(this[0],a);return this.each(function(){var d=c.queue(this,a,b);a==="fx"&&d[0]!=="inprogress"&&c.dequeue(this,a)})},dequeue:function(a){return this.each(function(){c.dequeue(this,a)})},delay:function(a,b){a=c.fx?c.fx.speeds[a]||a:a;b=b||"fx";return this.queue(b,function(){var d=this;setTimeout(function(){c.dequeue(d,b)},a)})},clearQueue:function(a){return this.queue(a||"fx",[])}});var Aa=/[\\n\\t]/g,ca=/\\s+/,Za=/\\r/g,$a=/href|src|style/,ab=/(button|input)/i,bb=/(button|input|object|select|textarea)/i,\r\n');
   fprintf(fid,'          cb=/^(a|area)$/i,Ba=/radio|checkbox/;c.fn.extend({attr:function(a,b){return X(this,a,b,true,c.attr)},removeAttr:function(a){return this.each(function(){c.attr(this,a,"");this.nodeType===1&&this.removeAttribute(a)})},addClass:function(a){if(c.isFunction(a))return this.each(function(n){var r=c(this);r.addClass(a.call(this,n,r.attr("class")))});if(a&&typeof a==="string")for(var b=(a||"").split(ca),d=0,f=this.length;d<f;d++){var e=this[d];if(e.nodeType===1)if(e.className){for(var j=" "+e.className+" ",\r\n');
   fprintf(fid,'          i=e.className,o=0,k=b.length;o<k;o++)if(j.indexOf(" "+b[o]+" ")<0)i+=" "+b[o];e.className=c.trim(i)}else e.className=a}return this},removeClass:function(a){if(c.isFunction(a))return this.each(function(k){var n=c(this);n.removeClass(a.call(this,k,n.attr("class")))});if(a&&typeof a==="string"||a===w)for(var b=(a||"").split(ca),d=0,f=this.length;d<f;d++){var e=this[d];if(e.nodeType===1&&e.className)if(a){for(var j=(" "+e.className+" ").replace(Aa," "),i=0,o=b.length;i<o;i++)j=j.replace(" "+b[i]+" ",\r\n');
   fprintf(fid,'          " ");e.className=c.trim(j)}else e.className=""}return this},toggleClass:function(a,b){var d=typeof a,f=typeof b==="boolean";if(c.isFunction(a))return this.each(function(e){var j=c(this);j.toggleClass(a.call(this,e,j.attr("class"),b),b)});return this.each(function(){if(d==="string")for(var e,j=0,i=c(this),o=b,k=a.split(ca);e=k[j++];){o=f?o:!i.hasClass(e);i[o?"addClass":"removeClass"](e)}else if(d==="undefined"||d==="boolean"){this.className&&c.data(this,"__className__",this.className);this.className=\r\n');
   fprintf(fid,'          this.className||a===false?"":c.data(this,"__className__")||""}})},hasClass:function(a){a=" "+a+" ";for(var b=0,d=this.length;b<d;b++)if((" "+this[b].className+" ").replace(Aa," ").indexOf(a)>-1)return true;return false},val:function(a){if(a===w){var b=this[0];if(b){if(c.nodeName(b,"option"))return(b.attributes.value||{}).specified?b.value:b.text;if(c.nodeName(b,"select")){var d=b.selectedIndex,f=[],e=b.options;b=b.type==="select-one";if(d<0)return null;var j=b?d:0;for(d=b?d+1:e.length;j<d;j++){var i=\r\n');
   fprintf(fid,'          e[j];if(i.selected){a=c(i).val();if(b)return a;f.push(a)}}return f}if(Ba.test(b.type)&&!c.support.checkOn)return b.getAttribute("value")===null?"on":b.value;return(b.value||"").replace(Za,"")}return w}var o=c.isFunction(a);return this.each(function(k){var n=c(this),r=a;if(this.nodeType===1){if(o)r=a.call(this,k,n.val());if(typeof r==="number")r+="";if(c.isArray(r)&&Ba.test(this.type))this.checked=c.inArray(n.val(),r)>=0;else if(c.nodeName(this,"select")){var u=c.makeArray(r);c("option",this).each(function(){this.selected=\r\n');
   fprintf(fid,'          c.inArray(c(this).val(),u)>=0});if(!u.length)this.selectedIndex=-1}else this.value=r}})}});c.extend({attrFn:{val:true,css:true,html:true,text:true,data:true,width:true,height:true,offset:true},attr:function(a,b,d,f){if(!a||a.nodeType===3||a.nodeType===8)return w;if(f&&b in c.attrFn)return c(a)[b](d);f=a.nodeType!==1||!c.isXMLDoc(a);var e=d!==w;b=f&&c.props[b]||b;if(a.nodeType===1){var j=$a.test(b);if(b in a&&f&&!j){if(e){b==="type"&&ab.test(a.nodeName)&&a.parentNode&&c.error("type property can''t be changed");\r\n');
   fprintf(fid,'          a[b]=d}if(c.nodeName(a,"form")&&a.getAttributeNode(b))return a.getAttributeNode(b).nodeValue;if(b==="tabIndex")return(b=a.getAttributeNode("tabIndex"))&&b.specified?b.value:bb.test(a.nodeName)||cb.test(a.nodeName)&&a.href?0:w;return a[b]}if(!c.support.style&&f&&b==="style"){if(e)a.style.cssText=""+d;return a.style.cssText}e&&a.setAttribute(b,""+d);a=!c.support.hrefNormalized&&f&&j?a.getAttribute(b,2):a.getAttribute(b);return a===null?w:a}return c.style(a,b,d)}});var O=/\\.(.*)$/,db=function(a){return a.replace(/[^\\w\\s\\.\\|`]/g,\r\n');
   fprintf(fid,'          function(b){return"\\\\"+b})};c.event={add:function(a,b,d,f){if(!(a.nodeType===3||a.nodeType===8)){if(a.setInterval&&a!==A&&!a.frameElement)a=A;var e,j;if(d.handler){e=d;d=e.handler}if(!d.guid)d.guid=c.guid++;if(j=c.data(a)){var i=j.events=j.events||{},o=j.handle;if(!o)j.handle=o=function(){return typeof c!=="undefined"&&!c.event.triggered?c.event.handle.apply(o.elem,arguments):w};o.elem=a;b=b.split(" ");for(var k,n=0,r;k=b[n++];){j=e?c.extend({},e):{handler:d,data:f};if(k.indexOf(".")>-1){r=k.split(".");\r\n');
   fprintf(fid,'          k=r.shift();j.namespace=r.slice(0).sort().join(".")}else{r=[];j.namespace=""}j.type=k;j.guid=d.guid;var u=i[k],z=c.event.special[k]||{};if(!u){u=i[k]=[];if(!z.setup||z.setup.call(a,f,r,o)===false)if(a.addEventListener)a.addEventListener(k,o,false);else a.attachEvent&&a.attachEvent("on"+k,o)}if(z.add){z.add.call(a,j);if(!j.handler.guid)j.handler.guid=d.guid}u.push(j);c.event.global[k]=true}a=null}}},global:{},remove:function(a,b,d,f){if(!(a.nodeType===3||a.nodeType===8)){var e,j=0,i,o,k,n,r,u,z=c.data(a),\r\n');
   fprintf(fid,'          C=z&&z.events;if(z&&C){if(b&&b.type){d=b.handler;b=b.type}if(!b||typeof b==="string"&&b.charAt(0)==="."){b=b||"";for(e in C)c.event.remove(a,e+b)}else{for(b=b.split(" ");e=b[j++];){n=e;i=e.indexOf(".")<0;o=[];if(!i){o=e.split(".");e=o.shift();k=new RegExp("(^|\\\\.)"+c.map(o.slice(0).sort(),db).join("\\\\.(?:.*\\\\.)?")+"(\\\\.|$)")}if(r=C[e])if(d){n=c.event.special[e]||{};for(B=f||0;B<r.length;B++){u=r[B];if(d.guid===u.guid){if(i||k.test(u.namespace)){f==null&&r.splice(B--,1);n.remove&&n.remove.call(a,u)}if(f!=\r\n');
   fprintf(fid,'          null)break}}if(r.length===0||f!=null&&r.length===1){if(!n.teardown||n.teardown.call(a,o)===false)Ca(a,e,z.handle);delete C[e]}}else for(var B=0;B<r.length;B++){u=r[B];if(i||k.test(u.namespace)){c.event.remove(a,n,u.handler,B);r.splice(B--,1)}}}if(c.isEmptyObject(C)){if(b=z.handle)b.elem=null;delete z.events;delete z.handle;c.isEmptyObject(z)&&c.removeData(a)}}}}},trigger:function(a,b,d,f){var e=a.type||a;if(!f){a=typeof a==="object"?a[G]?a:c.extend(c.Event(e),a):c.Event(e);if(e.indexOf("!")>=0){a.type=\r\n');
   fprintf(fid,'          e=e.slice(0,-1);a.exclusive=true}if(!d){a.stopPropagation();c.event.global[e]&&c.each(c.cache,function(){this.events&&this.events[e]&&c.event.trigger(a,b,this.handle.elem)})}if(!d||d.nodeType===3||d.nodeType===8)return w;a.result=w;a.target=d;b=c.makeArray(b);b.unshift(a)}a.currentTarget=d;(f=c.data(d,"handle"))&&f.apply(d,b);f=d.parentNode||d.ownerDocument;try{if(!(d&&d.nodeName&&c.noData[d.nodeName.toLowerCase()]))if(d["on"+e]&&d["on"+e].apply(d,b)===false)a.result=false}catch(j){}if(!a.isPropagationStopped()&&\r\n');
   fprintf(fid,'          f)c.event.trigger(a,b,f,true);else if(!a.isDefaultPrevented()){f=a.target;var i,o=c.nodeName(f,"a")&&e==="click",k=c.event.special[e]||{};if((!k._default||k._default.call(d,a)===false)&&!o&&!(f&&f.nodeName&&c.noData[f.nodeName.toLowerCase()])){try{if(f[e]){if(i=f["on"+e])f["on"+e]=null;c.event.triggered=true;f[e]()}}catch(n){}if(i)f["on"+e]=i;c.event.triggered=false}}},handle:function(a){var b,d,f,e;a=arguments[0]=c.event.fix(a||A.event);a.currentTarget=this;b=a.type.indexOf(".")<0&&!a.exclusive;\r\n');
   fprintf(fid,'          if(!b){d=a.type.split(".");a.type=d.shift();f=new RegExp("(^|\\\\.)"+d.slice(0).sort().join("\\\\.(?:.*\\\\.)?")+"(\\\\.|$)")}e=c.data(this,"events");d=e[a.type];if(e&&d){d=d.slice(0);e=0;for(var j=d.length;e<j;e++){var i=d[e];if(b||f.test(i.namespace)){a.handler=i.handler;a.data=i.data;a.handleObj=i;i=i.handler.apply(this,arguments);if(i!==w){a.result=i;if(i===false){a.preventDefault();a.stopPropagation()}}if(a.isImmediatePropagationStopped())break}}}return a.result},props:"altKey attrChange attrName bubbles button cancelable charCode clientX clientY ctrlKey currentTarget data detail eventPhase fromElement handler keyCode layerX layerY metaKey newValue offsetX offsetY originalTarget pageX pageY prevValue relatedNode relatedTarget screenX screenY shiftKey srcElement target toElement view wheelDelta which".split(" "),\r\n');
   fprintf(fid,'          fix:function(a){if(a[G])return a;var b=a;a=c.Event(b);for(var d=this.props.length,f;d;){f=this.props[--d];a[f]=b[f]}if(!a.target)a.target=a.srcElement||s;if(a.target.nodeType===3)a.target=a.target.parentNode;if(!a.relatedTarget&&a.fromElement)a.relatedTarget=a.fromElement===a.target?a.toElement:a.fromElement;if(a.pageX==null&&a.clientX!=null){b=s.documentElement;d=s.body;a.pageX=a.clientX+(b&&b.scrollLeft||d&&d.scrollLeft||0)-(b&&b.clientLeft||d&&d.clientLeft||0);a.pageY=a.clientY+(b&&b.scrollTop||\r\n');
   fprintf(fid,'          d&&d.scrollTop||0)-(b&&b.clientTop||d&&d.clientTop||0)}if(!a.which&&(a.charCode||a.charCode===0?a.charCode:a.keyCode))a.which=a.charCode||a.keyCode;if(!a.metaKey&&a.ctrlKey)a.metaKey=a.ctrlKey;if(!a.which&&a.button!==w)a.which=a.button&1?1:a.button&2?3:a.button&4?2:0;return a},guid:1E8,proxy:c.proxy,special:{ready:{setup:c.bindReady,teardown:c.noop},live:{add:function(a){c.event.add(this,a.origType,c.extend({},a,{handler:oa}))},remove:function(a){var b=true,d=a.origType.replace(O,"");c.each(c.data(this,\r\n');
   fprintf(fid,'          "events").live||[],function(){if(d===this.origType.replace(O,""))return b=false});b&&c.event.remove(this,a.origType,oa)}},beforeunload:{setup:function(a,b,d){if(this.setInterval)this.onbeforeunload=d;return false},teardown:function(a,b){if(this.onbeforeunload===b)this.onbeforeunload=null}}}};var Ca=s.removeEventListener?function(a,b,d){a.removeEventListener(b,d,false)}:function(a,b,d){a.detachEvent("on"+b,d)};c.Event=function(a){if(!this.preventDefault)return new c.Event(a);if(a&&a.type){this.originalEvent=\r\n');
   fprintf(fid,'          a;this.type=a.type}else this.type=a;this.timeStamp=J();this[G]=true};c.Event.prototype={preventDefault:function(){this.isDefaultPrevented=Z;var a=this.originalEvent;if(a){a.preventDefault&&a.preventDefault();a.returnValue=false}},stopPropagation:function(){this.isPropagationStopped=Z;var a=this.originalEvent;if(a){a.stopPropagation&&a.stopPropagation();a.cancelBubble=true}},stopImmediatePropagation:function(){this.isImmediatePropagationStopped=Z;this.stopPropagation()},isDefaultPrevented:Y,isPropagationStopped:Y,\r\n');
   fprintf(fid,'          isImmediatePropagationStopped:Y};var Da=function(a){var b=a.relatedTarget;try{for(;b&&b!==this;)b=b.parentNode;if(b!==this){a.type=a.data;c.event.handle.apply(this,arguments)}}catch(d){}},Ea=function(a){a.type=a.data;c.event.handle.apply(this,arguments)};c.each({mouseenter:"mouseover",mouseleave:"mouseout"},function(a,b){c.event.special[a]={setup:function(d){c.event.add(this,b,d&&d.selector?Ea:Da,a)},teardown:function(d){c.event.remove(this,b,d&&d.selector?Ea:Da)}}});if(!c.support.submitBubbles)c.event.special.submit=\r\n');
   fprintf(fid,'          {setup:function(){if(this.nodeName.toLowerCase()!=="form"){c.event.add(this,"click.specialSubmit",function(a){var b=a.target,d=b.type;if((d==="submit"||d==="image")&&c(b).closest("form").length)return na("submit",this,arguments)});c.event.add(this,"keypress.specialSubmit",function(a){var b=a.target,d=b.type;if((d==="text"||d==="password")&&c(b).closest("form").length&&a.keyCode===13)return na("submit",this,arguments)})}else return false},teardown:function(){c.event.remove(this,".specialSubmit")}};\r\n');
   fprintf(fid,'          if(!c.support.changeBubbles){var da=/textarea|input|select/i,ea,Fa=function(a){var b=a.type,d=a.value;if(b==="radio"||b==="checkbox")d=a.checked;else if(b==="select-multiple")d=a.selectedIndex>-1?c.map(a.options,function(f){return f.selected}).join("-"):"";else if(a.nodeName.toLowerCase()==="select")d=a.selectedIndex;return d},fa=function(a,b){var d=a.target,f,e;if(!(!da.test(d.nodeName)||d.readOnly)){f=c.data(d,"_change_data");e=Fa(d);if(a.type!=="focusout"||d.type!=="radio")c.data(d,"_change_data",\r\n');
   fprintf(fid,'          e);if(!(f===w||e===f))if(f!=null||e){a.type="change";return c.event.trigger(a,b,d)}}};c.event.special.change={filters:{focusout:fa,click:function(a){var b=a.target,d=b.type;if(d==="radio"||d==="checkbox"||b.nodeName.toLowerCase()==="select")return fa.call(this,a)},keydown:function(a){var b=a.target,d=b.type;if(a.keyCode===13&&b.nodeName.toLowerCase()!=="textarea"||a.keyCode===32&&(d==="checkbox"||d==="radio")||d==="select-multiple")return fa.call(this,a)},beforeactivate:function(a){a=a.target;c.data(a,\r\n');
   fprintf(fid,'          "_change_data",Fa(a))}},setup:function(){if(this.type==="file")return false;for(var a in ea)c.event.add(this,a+".specialChange",ea[a]);return da.test(this.nodeName)},teardown:function(){c.event.remove(this,".specialChange");return da.test(this.nodeName)}};ea=c.event.special.change.filters}s.addEventListener&&c.each({focus:"focusin",blur:"focusout"},function(a,b){function d(f){f=c.event.fix(f);f.type=b;return c.event.handle.call(this,f)}c.event.special[b]={setup:function(){this.addEventListener(a,\r\n');
   fprintf(fid,'          d,true)},teardown:function(){this.removeEventListener(a,d,true)}}});c.each(["bind","one"],function(a,b){c.fn[b]=function(d,f,e){if(typeof d==="object"){for(var j in d)this[b](j,f,d[j],e);return this}if(c.isFunction(f)){e=f;f=w}var i=b==="one"?c.proxy(e,function(k){c(this).unbind(k,i);return e.apply(this,arguments)}):e;if(d==="unload"&&b!=="one")this.one(d,f,e);else{j=0;for(var o=this.length;j<o;j++)c.event.add(this[j],d,i,f)}return this}});c.fn.extend({unbind:function(a,b){if(typeof a==="object"&&\r\n');
   fprintf(fid,'          !a.preventDefault)for(var d in a)this.unbind(d,a[d]);else{d=0;for(var f=this.length;d<f;d++)c.event.remove(this[d],a,b)}return this},delegate:function(a,b,d,f){return this.live(b,d,f,a)},undelegate:function(a,b,d){return arguments.length===0?this.unbind("live"):this.die(b,null,d,a)},trigger:function(a,b){return this.each(function(){c.event.trigger(a,b,this)})},triggerHandler:function(a,b){if(this[0]){a=c.Event(a);a.preventDefault();a.stopPropagation();c.event.trigger(a,b,this[0]);return a.result}},\r\n');
   fprintf(fid,'          toggle:function(a){for(var b=arguments,d=1;d<b.length;)c.proxy(a,b[d++]);return this.click(c.proxy(a,function(f){var e=(c.data(this,"lastToggle"+a.guid)||0)######d;c.data(this,"lastToggle"+a.guid,e+1);f.preventDefault();return b[e].apply(this,arguments)||false}))},hover:function(a,b){return this.mouseenter(a).mouseleave(b||a)}});var Ga={focus:"focusin",blur:"focusout",mouseenter:"mouseover",mouseleave:"mouseout"};c.each(["live","die"],function(a,b){c.fn[b]=function(d,f,e,j){var i,o=0,k,n,r=j||this.selector,\r\n');
   fprintf(fid,'          u=j?this:c(this.context);if(c.isFunction(f)){e=f;f=w}for(d=(d||"").split(" ");(i=d[o++])!=null;){j=O.exec(i);k="";if(j){k=j[0];i=i.replace(O,"")}if(i==="hover")d.push("mouseenter"+k,"mouseleave"+k);else{n=i;if(i==="focus"||i==="blur"){d.push(Ga[i]+k);i+=k}else i=(Ga[i]||i)+k;b==="live"?u.each(function(){c.event.add(this,pa(i,r),{data:f,selector:r,handler:e,origType:i,origHandler:e,preType:n})}):u.unbind(pa(i,r),e)}}return this}});c.each("blur focus focusin focusout load resize scroll unload click dblclick mousedown mouseup mousemove mouseover mouseout mouseenter mouseleave change select submit keydown keypress keyup error".split(" "),\r\n');
   fprintf(fid,'          function(a,b){c.fn[b]=function(d){return d?this.bind(b,d):this.trigger(b)};if(c.attrFn)c.attrFn[b]=true});A.attachEvent&&!A.addEventListener&&A.attachEvent("onunload",function(){for(var a in c.cache)if(c.cache[a].handle)try{c.event.remove(c.cache[a].handle.elem)}catch(b){}});(function(){function a(g){for(var h="",l,m=0;g[m];m++){l=g[m];if(l.nodeType===3||l.nodeType===4)h+=l.nodeValue;else if(l.nodeType!==8)h+=a(l.childNodes)}return h}function b(g,h,l,m,q,p){q=0;for(var v=m.length;q<v;q++){var t=m[q];\r\n');
   fprintf(fid,'          if(t){t=t[g];for(var y=false;t;){if(t.sizcache===l){y=m[t.sizset];break}if(t.nodeType===1&&!p){t.sizcache=l;t.sizset=q}if(t.nodeName.toLowerCase()===h){y=t;break}t=t[g]}m[q]=y}}}function d(g,h,l,m,q,p){q=0;for(var v=m.length;q<v;q++){var t=m[q];if(t){t=t[g];for(var y=false;t;){if(t.sizcache===l){y=m[t.sizset];break}if(t.nodeType===1){if(!p){t.sizcache=l;t.sizset=q}if(typeof h!=="string"){if(t===h){y=true;break}}else if(k.filter(h,[t]).length>0){y=t;break}}t=t[g]}m[q]=y}}}var f=/((?:\\((?:\\([^()]+\\)|[^()]+)+\\)|\\[(?:\\[[^[\\]]*\\]|[''"][^''"]*[''"]|[^[\\]''"]+)+\\]|\\\\.|[^ >+~,(\\[\\\\]+)+|[>+~])(\\s*,\\s*)?((?:.|\\r|\\n)*)/g,\r\n');
   fprintf(fid,'          e=0,j=Object.prototype.toString,i=false,o=true;[0,0].sort(function(){o=false;return 0});var k=function(g,h,l,m){l=l||[];var q=h=h||s;if(h.nodeType!==1&&h.nodeType!==9)return[];if(!g||typeof g!=="string")return l;for(var p=[],v,t,y,S,H=true,M=x(h),I=g;(f.exec(""),v=f.exec(I))!==null;){I=v[3];p.push(v[1]);if(v[2]){S=v[3];break}}if(p.length>1&&r.exec(g))if(p.length===2&&n.relative[p[0]])t=ga(p[0]+p[1],h);else for(t=n.relative[p[0]]?[h]:k(p.shift(),h);p.length;){g=p.shift();if(n.relative[g])g+=p.shift();\r\n');
   fprintf(fid,'          t=ga(g,t)}else{if(!m&&p.length>1&&h.nodeType===9&&!M&&n.match.ID.test(p[0])&&!n.match.ID.test(p[p.length-1])){v=k.find(p.shift(),h,M);h=v.expr?k.filter(v.expr,v.set)[0]:v.set[0]}if(h){v=m?{expr:p.pop(),set:z(m)}:k.find(p.pop(),p.length===1&&(p[0]==="~"||p[0]==="+")&&h.parentNode?h.parentNode:h,M);t=v.expr?k.filter(v.expr,v.set):v.set;if(p.length>0)y=z(t);else H=false;for(;p.length;){var D=p.pop();v=D;if(n.relative[D])v=p.pop();else D="";if(v==null)v=h;n.relative[D](y,v,M)}}else y=[]}y||(y=t);y||k.error(D||\r\n');
   fprintf(fid,'          g);if(j.call(y)==="[object Array]")if(H)if(h&&h.nodeType===1)for(g=0;y[g]!=null;g++){if(y[g]&&(y[g]===true||y[g].nodeType===1&&E(h,y[g])))l.push(t[g])}else for(g=0;y[g]!=null;g++)y[g]&&y[g].nodeType===1&&l.push(t[g]);else l.push.apply(l,y);else z(y,l);if(S){k(S,q,l,m);k.uniqueSort(l)}return l};k.uniqueSort=function(g){if(B){i=o;g.sort(B);if(i)for(var h=1;h<g.length;h++)g[h]===g[h-1]&&g.splice(h--,1)}return g};k.matches=function(g,h){return k(g,null,null,h)};k.find=function(g,h,l){var m,q;if(!g)return[];\r\n');
   fprintf(fid,'          for(var p=0,v=n.order.length;p<v;p++){var t=n.order[p];if(q=n.leftMatch[t].exec(g)){var y=q[1];q.splice(1,1);if(y.substr(y.length-1)!=="\\\\"){q[1]=(q[1]||"").replace(/\\\\/g,"");m=n.find[t](q,h,l);if(m!=null){g=g.replace(n.match[t],"");break}}}}m||(m=h.getElementsByTagName("*"));return{set:m,expr:g}};k.filter=function(g,h,l,m){for(var q=g,p=[],v=h,t,y,S=h&&h[0]&&x(h[0]);g&&h.length;){for(var H in n.filter)if((t=n.leftMatch[H].exec(g))!=null&&t[2]){var M=n.filter[H],I,D;D=t[1];y=false;t.splice(1,1);if(D.substr(D.length-\r\n');
   fprintf(fid,'          1)!=="\\\\"){if(v===p)p=[];if(n.preFilter[H])if(t=n.preFilter[H](t,v,l,p,m,S)){if(t===true)continue}else y=I=true;if(t)for(var U=0;(D=v[U])!=null;U++)if(D){I=M(D,t,U,v);var Ha=m^!!I;if(l&&I!=null)if(Ha)y=true;else v[U]=false;else if(Ha){p.push(D);y=true}}if(I!==w){l||(v=p);g=g.replace(n.match[H],"");if(!y)return[];break}}}if(g===q)if(y==null)k.error(g);else break;q=g}return v};k.error=function(g){throw"Syntax error, unrecognized expression: "+g;};var n=k.selectors={order:["ID","NAME","TAG"],match:{ID:/#((?:[\\w\\u00c0-\\uFFFF-]|\\\\.)+)/,\r\n');
   fprintf(fid,'          CLASS:/\\.((?:[\\w\\u00c0-\\uFFFF-]|\\\\.)+)/,NAME:/\\[name=[''"]*((?:[\\w\\u00c0-\\uFFFF-]|\\\\.)+)[''"]*\\]/,ATTR:/\\[\\s*((?:[\\w\\u00c0-\\uFFFF-]|\\\\.)+)\\s*(?:(\\S?=)\\s*([''"]*)(.*?)\\3|)\\s*\\]/,TAG:/^((?:[\\w\\u00c0-\\uFFFF\\*-]|\\\\.)+)/,CHILD:/:(only|nth|last|first)-child(?:\\((even|odd|[\\dn+-]*)\\))?/,POS:/:(nth|eq|gt|lt|first|last|even|odd)(?:\\((\\d*)\\))?(?=[^-]|$)/,PSEUDO:/:((?:[\\w\\u00c0-\\uFFFF-]|\\\\.)+)(?:\\(([''"]?)((?:\\([^\\)]+\\)|[^\\(\\)]*)+)\\2\\))?/},leftMatch:{},attrMap:{"class":"className","for":"htmlFor"},attrHandle:{href:function(g){return g.getAttribute("href")}},\r\n');
   fprintf(fid,'          relative:{"+":function(g,h){var l=typeof h==="string",m=l&&!/\\W/.test(h);l=l&&!m;if(m)h=h.toLowerCase();m=0;for(var q=g.length,p;m<q;m++)if(p=g[m]){for(;(p=p.previousSibling)&&p.nodeType!==1;);g[m]=l||p&&p.nodeName.toLowerCase()===h?p||false:p===h}l&&k.filter(h,g,true)},">":function(g,h){var l=typeof h==="string";if(l&&!/\\W/.test(h)){h=h.toLowerCase();for(var m=0,q=g.length;m<q;m++){var p=g[m];if(p){l=p.parentNode;g[m]=l.nodeName.toLowerCase()===h?l:false}}}else{m=0;for(q=g.length;m<q;m++)if(p=g[m])g[m]=\r\n');
   fprintf(fid,'          l?p.parentNode:p.parentNode===h;l&&k.filter(h,g,true)}},"":function(g,h,l){var m=e++,q=d;if(typeof h==="string"&&!/\\W/.test(h)){var p=h=h.toLowerCase();q=b}q("parentNode",h,m,g,p,l)},"~":function(g,h,l){var m=e++,q=d;if(typeof h==="string"&&!/\\W/.test(h)){var p=h=h.toLowerCase();q=b}q("previousSibling",h,m,g,p,l)}},find:{ID:function(g,h,l){if(typeof h.getElementById!=="undefined"&&!l)return(g=h.getElementById(g[1]))?[g]:[]},NAME:function(g,h){if(typeof h.getElementsByName!=="undefined"){var l=[];\r\n');
   fprintf(fid,'          h=h.getElementsByName(g[1]);for(var m=0,q=h.length;m<q;m++)h[m].getAttribute("name")===g[1]&&l.push(h[m]);return l.length===0?null:l}},TAG:function(g,h){return h.getElementsByTagName(g[1])}},preFilter:{CLASS:function(g,h,l,m,q,p){g=" "+g[1].replace(/\\\\/g,"")+" ";if(p)return g;p=0;for(var v;(v=h[p])!=null;p++)if(v)if(q^(v.className&&(" "+v.className+" ").replace(/[\\t\\n]/g," ").indexOf(g)>=0))l||m.push(v);else if(l)h[p]=false;return false},ID:function(g){return g[1].replace(/\\\\/g,"")},TAG:function(g){return g[1].toLowerCase()},\r\n');
   fprintf(fid,'          CHILD:function(g){if(g[1]==="nth"){var h=/(-?)(\\d*)n((?:\\+|-)?\\d*)/.exec(g[2]==="even"&&"2n"||g[2]==="odd"&&"2n+1"||!/\\D/.test(g[2])&&"0n+"+g[2]||g[2]);g[2]=h[1]+(h[2]||1)-0;g[3]=h[3]-0}g[0]=e++;return g},ATTR:function(g,h,l,m,q,p){h=g[1].replace(/\\\\/g,"");if(!p&&n.attrMap[h])g[1]=n.attrMap[h];if(g[2]==="~=")g[4]=" "+g[4]+" ";return g},PSEUDO:function(g,h,l,m,q){if(g[1]==="not")if((f.exec(g[3])||"").length>1||/^\\w/.test(g[3]))g[3]=k(g[3],null,null,h);else{g=k.filter(g[3],h,l,true^q);l||m.push.apply(m,\r\n');
   fprintf(fid,'          g);return false}else if(n.match.POS.test(g[0])||n.match.CHILD.test(g[0]))return true;return g},POS:function(g){g.unshift(true);return g}},filters:{enabled:function(g){return g.disabled===false&&g.type!=="hidden"},disabled:function(g){return g.disabled===true},checked:function(g){return g.checked===true},selected:function(g){return g.selected===true},parent:function(g){return!!g.firstChild},empty:function(g){return!g.firstChild},has:function(g,h,l){return!!k(l[3],g).length},header:function(g){return/h\\d/i.test(g.nodeName)},\r\n');
   fprintf(fid,'          text:function(g){return"text"===g.type},radio:function(g){return"radio"===g.type},checkbox:function(g){return"checkbox"===g.type},file:function(g){return"file"===g.type},password:function(g){return"password"===g.type},submit:function(g){return"submit"===g.type},image:function(g){return"image"===g.type},reset:function(g){return"reset"===g.type},button:function(g){return"button"===g.type||g.nodeName.toLowerCase()==="button"},input:function(g){return/input|select|textarea|button/i.test(g.nodeName)}},\r\n');
   fprintf(fid,'          setFilters:{first:function(g,h){return h===0},last:function(g,h,l,m){return h===m.length-1},even:function(g,h){return h######2===0},odd:function(g,h){return h######2===1},lt:function(g,h,l){return h<l[3]-0},gt:function(g,h,l){return h>l[3]-0},nth:function(g,h,l){return l[3]-0===h},eq:function(g,h,l){return l[3]-0===h}},filter:{PSEUDO:function(g,h,l,m){var q=h[1],p=n.filters[q];if(p)return p(g,l,h,m);else if(q==="contains")return(g.textContent||g.innerText||a([g])||"").indexOf(h[3])>=0;else if(q==="not"){h=\r\n');
   fprintf(fid,'          h[3];l=0;for(m=h.length;l<m;l++)if(h[l]===g)return false;return true}else k.error("Syntax error, unrecognized expression: "+q)},CHILD:function(g,h){var l=h[1],m=g;switch(l){case "only":case "first":for(;m=m.previousSibling;)if(m.nodeType===1)return false;if(l==="first")return true;m=g;case "last":for(;m=m.nextSibling;)if(m.nodeType===1)return false;return true;case "nth":l=h[2];var q=h[3];if(l===1&&q===0)return true;h=h[0];var p=g.parentNode;if(p&&(p.sizcache!==h||!g.nodeIndex)){var v=0;for(m=p.firstChild;m;m=\r\n');
   fprintf(fid,'          m.nextSibling)if(m.nodeType===1)m.nodeIndex=++v;p.sizcache=h}g=g.nodeIndex-q;return l===0?g===0:g######l===0&&g/l>=0}},ID:function(g,h){return g.nodeType===1&&g.getAttribute("id")===h},TAG:function(g,h){return h==="*"&&g.nodeType===1||g.nodeName.toLowerCase()===h},CLASS:function(g,h){return(" "+(g.className||g.getAttribute("class"))+" ").indexOf(h)>-1},ATTR:function(g,h){var l=h[1];g=n.attrHandle[l]?n.attrHandle[l](g):g[l]!=null?g[l]:g.getAttribute(l);l=g+"";var m=h[2];h=h[4];return g==null?m==="!=":m===\r\n');
   fprintf(fid,'          "="?l===h:m==="*="?l.indexOf(h)>=0:m==="~="?(" "+l+" ").indexOf(h)>=0:!h?l&&g!==false:m==="!="?l!==h:m==="^="?l.indexOf(h)===0:m==="$="?l.substr(l.length-h.length)===h:m==="|="?l===h||l.substr(0,h.length+1)===h+"-":false},POS:function(g,h,l,m){var q=n.setFilters[h[2]];if(q)return q(g,l,h,m)}}},r=n.match.POS;for(var u in n.match){n.match[u]=new RegExp(n.match[u].source+/(?![^\\[]*\\])(?![^\\(]*\\))/.source);n.leftMatch[u]=new RegExp(/(^(?:.|\\r|\\n)*?)/.source+n.match[u].source.replace(/\\\\(\\d+)/g,function(g,\r\n');
   fprintf(fid,'          h){return"\\\\"+(h-0+1)}))}var z=function(g,h){g=Array.prototype.slice.call(g,0);if(h){h.push.apply(h,g);return h}return g};try{Array.prototype.slice.call(s.documentElement.childNodes,0)}catch(C){z=function(g,h){h=h||[];if(j.call(g)==="[object Array]")Array.prototype.push.apply(h,g);else if(typeof g.length==="number")for(var l=0,m=g.length;l<m;l++)h.push(g[l]);else for(l=0;g[l];l++)h.push(g[l]);return h}}var B;if(s.documentElement.compareDocumentPosition)B=function(g,h){if(!g.compareDocumentPosition||\r\n');
   fprintf(fid,'          !h.compareDocumentPosition){if(g==h)i=true;return g.compareDocumentPosition?-1:1}g=g.compareDocumentPosition(h)&4?-1:g===h?0:1;if(g===0)i=true;return g};else if("sourceIndex"in s.documentElement)B=function(g,h){if(!g.sourceIndex||!h.sourceIndex){if(g==h)i=true;return g.sourceIndex?-1:1}g=g.sourceIndex-h.sourceIndex;if(g===0)i=true;return g};else if(s.createRange)B=function(g,h){if(!g.ownerDocument||!h.ownerDocument){if(g==h)i=true;return g.ownerDocument?-1:1}var l=g.ownerDocument.createRange(),m=\r\n');
   fprintf(fid,'          h.ownerDocument.createRange();l.setStart(g,0);l.setEnd(g,0);m.setStart(h,0);m.setEnd(h,0);g=l.compareBoundaryPoints(Range.START_TO_END,m);if(g===0)i=true;return g};(function(){var g=s.createElement("div"),h="script"+(new Date).getTime();g.innerHTML="<a name=''"+h+"''/>";var l=s.documentElement;l.insertBefore(g,l.firstChild);if(s.getElementById(h)){n.find.ID=function(m,q,p){if(typeof q.getElementById!=="undefined"&&!p)return(q=q.getElementById(m[1]))?q.id===m[1]||typeof q.getAttributeNode!=="undefined"&&\r\n');
   fprintf(fid,'          q.getAttributeNode("id").nodeValue===m[1]?[q]:w:[]};n.filter.ID=function(m,q){var p=typeof m.getAttributeNode!=="undefined"&&m.getAttributeNode("id");return m.nodeType===1&&p&&p.nodeValue===q}}l.removeChild(g);l=g=null})();(function(){var g=s.createElement("div");g.appendChild(s.createComment(""));if(g.getElementsByTagName("*").length>0)n.find.TAG=function(h,l){l=l.getElementsByTagName(h[1]);if(h[1]==="*"){h=[];for(var m=0;l[m];m++)l[m].nodeType===1&&h.push(l[m]);l=h}return l};g.innerHTML="<a href=''#''></a>";\r\n');
   fprintf(fid,'          if(g.firstChild&&typeof g.firstChild.getAttribute!=="undefined"&&g.firstChild.getAttribute("href")!=="#")n.attrHandle.href=function(h){return h.getAttribute("href",2)};g=null})();s.querySelectorAll&&function(){var g=k,h=s.createElement("div");h.innerHTML="<p class=''TEST''></p>";if(!(h.querySelectorAll&&h.querySelectorAll(".TEST").length===0)){k=function(m,q,p,v){q=q||s;if(!v&&q.nodeType===9&&!x(q))try{return z(q.querySelectorAll(m),p)}catch(t){}return g(m,q,p,v)};for(var l in g)k[l]=g[l];h=null}}();\r\n');
   fprintf(fid,'          (function(){var g=s.createElement("div");g.innerHTML="<div class=''test e''></div><div class=''test''></div>";if(!(!g.getElementsByClassName||g.getElementsByClassName("e").length===0)){g.lastChild.className="e";if(g.getElementsByClassName("e").length!==1){n.order.splice(1,0,"CLASS");n.find.CLASS=function(h,l,m){if(typeof l.getElementsByClassName!=="undefined"&&!m)return l.getElementsByClassName(h[1])};g=null}}})();var E=s.compareDocumentPosition?function(g,h){return!!(g.compareDocumentPosition(h)&16)}:\r\n');
   fprintf(fid,'          function(g,h){return g!==h&&(g.contains?g.contains(h):true)},x=function(g){return(g=(g?g.ownerDocument||g:0).documentElement)?g.nodeName!=="HTML":false},ga=function(g,h){var l=[],m="",q;for(h=h.nodeType?[h]:h;q=n.match.PSEUDO.exec(g);){m+=q[0];g=g.replace(n.match.PSEUDO,"")}g=n.relative[g]?g+"*":g;q=0;for(var p=h.length;q<p;q++)k(g,h[q],l);return k.filter(m,l)};c.find=k;c.expr=k.selectors;c.expr[":"]=c.expr.filters;c.unique=k.uniqueSort;c.text=a;c.isXMLDoc=x;c.contains=E})();var eb=/Until$/,fb=/^(?:parents|prevUntil|prevAll)/,\r\n');
   fprintf(fid,'          gb=/,/;R=Array.prototype.slice;var Ia=function(a,b,d){if(c.isFunction(b))return c.grep(a,function(e,j){return!!b.call(e,j,e)===d});else if(b.nodeType)return c.grep(a,function(e){return e===b===d});else if(typeof b==="string"){var f=c.grep(a,function(e){return e.nodeType===1});if(Ua.test(b))return c.filter(b,f,!d);else b=c.filter(b,f)}return c.grep(a,function(e){return c.inArray(e,b)>=0===d})};c.fn.extend({find:function(a){for(var b=this.pushStack("","find",a),d=0,f=0,e=this.length;f<e;f++){d=b.length;\r\n');
   fprintf(fid,'          c.find(a,this[f],b);if(f>0)for(var j=d;j<b.length;j++)for(var i=0;i<d;i++)if(b[i]===b[j]){b.splice(j--,1);break}}return b},has:function(a){var b=c(a);return this.filter(function(){for(var d=0,f=b.length;d<f;d++)if(c.contains(this,b[d]))return true})},not:function(a){return this.pushStack(Ia(this,a,false),"not",a)},filter:function(a){return this.pushStack(Ia(this,a,true),"filter",a)},is:function(a){return!!a&&c.filter(a,this).length>0},closest:function(a,b){if(c.isArray(a)){var d=[],f=this[0],e,j=\r\n');
   fprintf(fid,'          {},i;if(f&&a.length){e=0;for(var o=a.length;e<o;e++){i=a[e];j[i]||(j[i]=c.expr.match.POS.test(i)?c(i,b||this.context):i)}for(;f&&f.ownerDocument&&f!==b;){for(i in j){e=j[i];if(e.jquery?e.index(f)>-1:c(f).is(e)){d.push({selector:i,elem:f});delete j[i]}}f=f.parentNode}}return d}var k=c.expr.match.POS.test(a)?c(a,b||this.context):null;return this.map(function(n,r){for(;r&&r.ownerDocument&&r!==b;){if(k?k.index(r)>-1:c(r).is(a))return r;r=r.parentNode}return null})},index:function(a){if(!a||typeof a===\r\n');
   fprintf(fid,'          "string")return c.inArray(this[0],a?c(a):this.parent().children());return c.inArray(a.jquery?a[0]:a,this)},add:function(a,b){a=typeof a==="string"?c(a,b||this.context):c.makeArray(a);b=c.merge(this.get(),a);return this.pushStack(qa(a[0])||qa(b[0])?b:c.unique(b))},andSelf:function(){return this.add(this.prevObject)}});c.each({parent:function(a){return(a=a.parentNode)&&a.nodeType!==11?a:null},parents:function(a){return c.dir(a,"parentNode")},parentsUntil:function(a,b,d){return c.dir(a,"parentNode",\r\n');
   fprintf(fid,'          d)},next:function(a){return c.nth(a,2,"nextSibling")},prev:function(a){return c.nth(a,2,"previousSibling")},nextAll:function(a){return c.dir(a,"nextSibling")},prevAll:function(a){return c.dir(a,"previousSibling")},nextUntil:function(a,b,d){return c.dir(a,"nextSibling",d)},prevUntil:function(a,b,d){return c.dir(a,"previousSibling",d)},siblings:function(a){return c.sibling(a.parentNode.firstChild,a)},children:function(a){return c.sibling(a.firstChild)},contents:function(a){return c.nodeName(a,"iframe")?\r\n');
   fprintf(fid,'          a.contentDocument||a.contentWindow.document:c.makeArray(a.childNodes)}},function(a,b){c.fn[a]=function(d,f){var e=c.map(this,b,d);eb.test(a)||(f=d);if(f&&typeof f==="string")e=c.filter(f,e);e=this.length>1?c.unique(e):e;if((this.length>1||gb.test(f))&&fb.test(a))e=e.reverse();return this.pushStack(e,a,R.call(arguments).join(","))}});c.extend({filter:function(a,b,d){if(d)a=":not("+a+")";return c.find.matches(a,b)},dir:function(a,b,d){var f=[];for(a=a[b];a&&a.nodeType!==9&&(d===w||a.nodeType!==1||!c(a).is(d));){a.nodeType===\r\n');
   fprintf(fid,'          1&&f.push(a);a=a[b]}return f},nth:function(a,b,d){b=b||1;for(var f=0;a;a=a[d])if(a.nodeType===1&&++f===b)break;return a},sibling:function(a,b){for(var d=[];a;a=a.nextSibling)a.nodeType===1&&a!==b&&d.push(a);return d}});var Ja=/ jQuery\\d+="(?:\\d+|null)"/g,V=/^\\s+/,Ka=/(<([\\w:]+)[^>]*?)\\/>/g,hb=/^(?:area|br|col|embed|hr|img|input|link|meta|param)$/i,La=/<([\\w:]+)/,ib=/<tbody/i,jb=/<|&#?\\w+;/,ta=/<script|<object|<embed|<option|<style/i,ua=/checked\\s*(?:[^=]|=\\s*.checked.)/i,Ma=function(a,b,d){return hb.test(d)?\r\n');
   fprintf(fid,'          a:b+"></"+d+">"},F={option:[1,"<select multiple=''multiple''>","</select>"],legend:[1,"<fieldset>","</fieldset>"],thead:[1,"<table>","</table>"],tr:[2,"<table><tbody>","</tbody></table>"],td:[3,"<table><tbody><tr>","</tr></tbody></table>"],col:[2,"<table><tbody></tbody><colgroup>","</colgroup></table>"],area:[1,"<map>","</map>"],_default:[0,"",""]};F.optgroup=F.option;F.tbody=F.tfoot=F.colgroup=F.caption=F.thead;F.th=F.td;if(!c.support.htmlSerialize)F._default=[1,"div<div>","</div>"];c.fn.extend({text:function(a){if(c.isFunction(a))return this.each(function(b){var d=\r\n');
   fprintf(fid,'          c(this);d.text(a.call(this,b,d.text()))});if(typeof a!=="object"&&a!==w)return this.empty().append((this[0]&&this[0].ownerDocument||s).createTextNode(a));return c.text(this)},wrapAll:function(a){if(c.isFunction(a))return this.each(function(d){c(this).wrapAll(a.call(this,d))});if(this[0]){var b=c(a,this[0].ownerDocument).eq(0).clone(true);this[0].parentNode&&b.insertBefore(this[0]);b.map(function(){for(var d=this;d.firstChild&&d.firstChild.nodeType===1;)d=d.firstChild;return d}).append(this)}return this},\r\n');
   fprintf(fid,'          wrapInner:function(a){if(c.isFunction(a))return this.each(function(b){c(this).wrapInner(a.call(this,b))});return this.each(function(){var b=c(this),d=b.contents();d.length?d.wrapAll(a):b.append(a)})},wrap:function(a){return this.each(function(){c(this).wrapAll(a)})},unwrap:function(){return this.parent().each(function(){c.nodeName(this,"body")||c(this).replaceWith(this.childNodes)}).end()},append:function(){return this.domManip(arguments,true,function(a){this.nodeType===1&&this.appendChild(a)})},\r\n');
   fprintf(fid,'          prepend:function(){return this.domManip(arguments,true,function(a){this.nodeType===1&&this.insertBefore(a,this.firstChild)})},before:function(){if(this[0]&&this[0].parentNode)return this.domManip(arguments,false,function(b){this.parentNode.insertBefore(b,this)});else if(arguments.length){var a=c(arguments[0]);a.push.apply(a,this.toArray());return this.pushStack(a,"before",arguments)}},after:function(){if(this[0]&&this[0].parentNode)return this.domManip(arguments,false,function(b){this.parentNode.insertBefore(b,\r\n');
   fprintf(fid,'          this.nextSibling)});else if(arguments.length){var a=this.pushStack(this,"after",arguments);a.push.apply(a,c(arguments[0]).toArray());return a}},remove:function(a,b){for(var d=0,f;(f=this[d])!=null;d++)if(!a||c.filter(a,[f]).length){if(!b&&f.nodeType===1){c.cleanData(f.getElementsByTagName("*"));c.cleanData([f])}f.parentNode&&f.parentNode.removeChild(f)}return this},empty:function(){for(var a=0,b;(b=this[a])!=null;a++)for(b.nodeType===1&&c.cleanData(b.getElementsByTagName("*"));b.firstChild;)b.removeChild(b.firstChild);\r\n');
   fprintf(fid,'          return this},clone:function(a){var b=this.map(function(){if(!c.support.noCloneEvent&&!c.isXMLDoc(this)){var d=this.outerHTML,f=this.ownerDocument;if(!d){d=f.createElement("div");d.appendChild(this.cloneNode(true));d=d.innerHTML}return c.clean([d.replace(Ja,"").replace(/=([^="''>\\s]+\\/)>/g,''="$1">'').replace(V,"")],f)[0]}else return this.cloneNode(true)});if(a===true){ra(this,b);ra(this.find("*"),b.find("*"))}return b},html:function(a){if(a===w)return this[0]&&this[0].nodeType===1?this[0].innerHTML.replace(Ja,\r\n');
   fprintf(fid,'          ""):null;else if(typeof a==="string"&&!ta.test(a)&&(c.support.leadingWhitespace||!V.test(a))&&!F[(La.exec(a)||["",""])[1].toLowerCase()]){a=a.replace(Ka,Ma);try{for(var b=0,d=this.length;b<d;b++)if(this[b].nodeType===1){c.cleanData(this[b].getElementsByTagName("*"));this[b].innerHTML=a}}catch(f){this.empty().append(a)}}else c.isFunction(a)?this.each(function(e){var j=c(this),i=j.html();j.empty().append(function(){return a.call(this,e,i)})}):this.empty().append(a);return this},replaceWith:function(a){if(this[0]&&\r\n');
   fprintf(fid,'          this[0].parentNode){if(c.isFunction(a))return this.each(function(b){var d=c(this),f=d.html();d.replaceWith(a.call(this,b,f))});if(typeof a!=="string")a=c(a).detach();return this.each(function(){var b=this.nextSibling,d=this.parentNode;c(this).remove();b?c(b).before(a):c(d).append(a)})}else return this.pushStack(c(c.isFunction(a)?a():a),"replaceWith",a)},detach:function(a){return this.remove(a,true)},domManip:function(a,b,d){function f(u){return c.nodeName(u,"table")?u.getElementsByTagName("tbody")[0]||\r\n');
   fprintf(fid,'          u.appendChild(u.ownerDocument.createElement("tbody")):u}var e,j,i=a[0],o=[],k;if(!c.support.checkClone&&arguments.length===3&&typeof i==="string"&&ua.test(i))return this.each(function(){c(this).domManip(a,b,d,true)});if(c.isFunction(i))return this.each(function(u){var z=c(this);a[0]=i.call(this,u,b?z.html():w);z.domManip(a,b,d)});if(this[0]){e=i&&i.parentNode;e=c.support.parentNode&&e&&e.nodeType===11&&e.childNodes.length===this.length?{fragment:e}:sa(a,this,o);k=e.fragment;if(j=k.childNodes.length===\r\n');
   fprintf(fid,'          1?(k=k.firstChild):k.firstChild){b=b&&c.nodeName(j,"tr");for(var n=0,r=this.length;n<r;n++)d.call(b?f(this[n],j):this[n],n>0||e.cacheable||this.length>1?k.cloneNode(true):k)}o.length&&c.each(o,Qa)}return this}});c.fragments={};c.each({appendTo:"append",prependTo:"prepend",insertBefore:"before",insertAfter:"after",replaceAll:"replaceWith"},function(a,b){c.fn[a]=function(d){var f=[];d=c(d);var e=this.length===1&&this[0].parentNode;if(e&&e.nodeType===11&&e.childNodes.length===1&&d.length===1){d[b](this[0]);\r\n');
   fprintf(fid,'          return this}else{e=0;for(var j=d.length;e<j;e++){var i=(e>0?this.clone(true):this).get();c.fn[b].apply(c(d[e]),i);f=f.concat(i)}return this.pushStack(f,a,d.selector)}}});c.extend({clean:function(a,b,d,f){b=b||s;if(typeof b.createElement==="undefined")b=b.ownerDocument||b[0]&&b[0].ownerDocument||s;for(var e=[],j=0,i;(i=a[j])!=null;j++){if(typeof i==="number")i+="";if(i){if(typeof i==="string"&&!jb.test(i))i=b.createTextNode(i);else if(typeof i==="string"){i=i.replace(Ka,Ma);var o=(La.exec(i)||["",\r\n');
   fprintf(fid,'          ""])[1].toLowerCase(),k=F[o]||F._default,n=k[0],r=b.createElement("div");for(r.innerHTML=k[1]+i+k[2];n--;)r=r.lastChild;if(!c.support.tbody){n=ib.test(i);o=o==="table"&&!n?r.firstChild&&r.firstChild.childNodes:k[1]==="<table>"&&!n?r.childNodes:[];for(k=o.length-1;k>=0;--k)c.nodeName(o[k],"tbody")&&!o[k].childNodes.length&&o[k].parentNode.removeChild(o[k])}!c.support.leadingWhitespace&&V.test(i)&&r.insertBefore(b.createTextNode(V.exec(i)[0]),r.firstChild);i=r.childNodes}if(i.nodeType)e.push(i);else e=\r\n');
   fprintf(fid,'          c.merge(e,i)}}if(d)for(j=0;e[j];j++)if(f&&c.nodeName(e[j],"script")&&(!e[j].type||e[j].type.toLowerCase()==="text/javascript"))f.push(e[j].parentNode?e[j].parentNode.removeChild(e[j]):e[j]);else{e[j].nodeType===1&&e.splice.apply(e,[j+1,0].concat(c.makeArray(e[j].getElementsByTagName("script"))));d.appendChild(e[j])}return e},cleanData:function(a){for(var b,d,f=c.cache,e=c.event.special,j=c.support.deleteExpando,i=0,o;(o=a[i])!=null;i++)if(d=o[c.expando]){b=f[d];if(b.events)for(var k in b.events)e[k]?\r\n');
   fprintf(fid,'          c.event.remove(o,k):Ca(o,k,b.handle);if(j)delete o[c.expando];else o.removeAttribute&&o.removeAttribute(c.expando);delete f[d]}}});var kb=/z-?index|font-?weight|opacity|zoom|line-?height/i,Na=/alpha\\([^)]*\\)/,Oa=/opacity=([^)]*)/,ha=/float/i,ia=/-([a-z])/ig,lb=/([A-Z])/g,mb=/^-?\\d+(?:px)?$/i,nb=/^-?\\d/,ob={position:"absolute",visibility:"hidden",display:"block"},pb=["Left","Right"],qb=["Top","Bottom"],rb=s.defaultView&&s.defaultView.getComputedStyle,Pa=c.support.cssFloat?"cssFloat":"styleFloat",ja=\r\n');
   fprintf(fid,'          function(a,b){return b.toUpperCase()};c.fn.css=function(a,b){return X(this,a,b,true,function(d,f,e){if(e===w)return c.curCSS(d,f);if(typeof e==="number"&&!kb.test(f))e+="px";c.style(d,f,e)})};c.extend({style:function(a,b,d){if(!a||a.nodeType===3||a.nodeType===8)return w;if((b==="width"||b==="height")&&parseFloat(d)<0)d=w;var f=a.style||a,e=d!==w;if(!c.support.opacity&&b==="opacity"){if(e){f.zoom=1;b=parseInt(d,10)+""==="NaN"?"":"alpha(opacity="+d*100+")";a=f.filter||c.curCSS(a,"filter")||"";f.filter=\r\n');
   fprintf(fid,'          Na.test(a)?a.replace(Na,b):b}return f.filter&&f.filter.indexOf("opacity=")>=0?parseFloat(Oa.exec(f.filter)[1])/100+"":""}if(ha.test(b))b=Pa;b=b.replace(ia,ja);if(e)f[b]=d;return f[b]},css:function(a,b,d,f){if(b==="width"||b==="height"){var e,j=b==="width"?pb:qb;function i(){e=b==="width"?a.offsetWidth:a.offsetHeight;f!=="border"&&c.each(j,function(){f||(e-=parseFloat(c.curCSS(a,"padding"+this,true))||0);if(f==="margin")e+=parseFloat(c.curCSS(a,"margin"+this,true))||0;else e-=parseFloat(c.curCSS(a,\r\n');
   fprintf(fid,'          "border"+this+"Width",true))||0})}a.offsetWidth!==0?i():c.swap(a,ob,i);return Math.max(0,Math.round(e))}return c.curCSS(a,b,d)},curCSS:function(a,b,d){var f,e=a.style;if(!c.support.opacity&&b==="opacity"&&a.currentStyle){f=Oa.test(a.currentStyle.filter||"")?parseFloat(RegExp.$1)/100+"":"";return f===""?"1":f}if(ha.test(b))b=Pa;if(!d&&e&&e[b])f=e[b];else if(rb){if(ha.test(b))b="float";b=b.replace(lb,"-$1").toLowerCase();e=a.ownerDocument.defaultView;if(!e)return null;if(a=e.getComputedStyle(a,null))f=\r\n');
   fprintf(fid,'          a.getPropertyValue(b);if(b==="opacity"&&f==="")f="1"}else if(a.currentStyle){d=b.replace(ia,ja);f=a.currentStyle[b]||a.currentStyle[d];if(!mb.test(f)&&nb.test(f)){b=e.left;var j=a.runtimeStyle.left;a.runtimeStyle.left=a.currentStyle.left;e.left=d==="fontSize"?"1em":f||0;f=e.pixelLeft+"px";e.left=b;a.runtimeStyle.left=j}}return f},swap:function(a,b,d){var f={};for(var e in b){f[e]=a.style[e];a.style[e]=b[e]}d.call(a);for(e in b)a.style[e]=f[e]}});if(c.expr&&c.expr.filters){c.expr.filters.hidden=function(a){var b=\r\n');
   fprintf(fid,'          a.offsetWidth,d=a.offsetHeight,f=a.nodeName.toLowerCase()==="tr";return b===0&&d===0&&!f?true:b>0&&d>0&&!f?false:c.curCSS(a,"display")==="none"};c.expr.filters.visible=function(a){return!c.expr.filters.hidden(a)}}var sb=J(),tb=/<script(.|\\s)*?\\/script>/gi,ub=/select|textarea/i,vb=/color|date|datetime|email|hidden|month|number|password|range|search|tel|text|time|url|week/i,N=/=\\?(&|$)/,ka=/\\?/,wb=/(\\?|&)_=.*?(&|$)/,xb=/^(\\w+:)?\\/\\/([^\\/?#]+)/,yb=/######20/g,zb=c.fn.load;c.fn.extend({load:function(a,b,d){if(typeof a!==\r\n');
   fprintf(fid,'          "string")return zb.call(this,a);else if(!this.length)return this;var f=a.indexOf(" ");if(f>=0){var e=a.slice(f,a.length);a=a.slice(0,f)}f="GET";if(b)if(c.isFunction(b)){d=b;b=null}else if(typeof b==="object"){b=c.param(b,c.ajaxSettings.traditional);f="POST"}var j=this;c.ajax({url:a,type:f,dataType:"html",data:b,complete:function(i,o){if(o==="success"||o==="notmodified")j.html(e?c("<div />").append(i.responseText.replace(tb,"")).find(e):i.responseText);d&&j.each(d,[i.responseText,o,i])}});return this},\r\n');
   fprintf(fid,'          serialize:function(){return c.param(this.serializeArray())},serializeArray:function(){return this.map(function(){return this.elements?c.makeArray(this.elements):this}).filter(function(){return this.name&&!this.disabled&&(this.checked||ub.test(this.nodeName)||vb.test(this.type))}).map(function(a,b){a=c(this).val();return a==null?null:c.isArray(a)?c.map(a,function(d){return{name:b.name,value:d}}):{name:b.name,value:a}}).get()}});c.each("ajaxStart ajaxStop ajaxComplete ajaxError ajaxSuccess ajaxSend".split(" "),\r\n');
   fprintf(fid,'          function(a,b){c.fn[b]=function(d){return this.bind(b,d)}});c.extend({get:function(a,b,d,f){if(c.isFunction(b)){f=f||d;d=b;b=null}return c.ajax({type:"GET",url:a,data:b,success:d,dataType:f})},getScript:function(a,b){return c.get(a,null,b,"script")},getJSON:function(a,b,d){return c.get(a,b,d,"json")},post:function(a,b,d,f){if(c.isFunction(b)){f=f||d;d=b;b={}}return c.ajax({type:"POST",url:a,data:b,success:d,dataType:f})},ajaxSetup:function(a){c.extend(c.ajaxSettings,a)},ajaxSettings:{url:location.href,\r\n');
   fprintf(fid,'          global:true,type:"GET",contentType:"application/x-www-form-urlencoded",processData:true,async:true,xhr:A.XMLHttpRequest&&(A.location.protocol!=="file:"||!A.ActiveXObject)?function(){return new A.XMLHttpRequest}:function(){try{return new A.ActiveXObject("Microsoft.XMLHTTP")}catch(a){}},accepts:{xml:"application/xml, text/xml",html:"text/html",script:"text/javascript, application/javascript",json:"application/json, text/javascript",text:"text/plain",_default:"*/*"}},lastModified:{},etag:{},ajax:function(a){function b(){e.success&&\r\n');
   fprintf(fid,'          e.success.call(k,o,i,x);e.global&&f("ajaxSuccess",[x,e])}function d(){e.complete&&e.complete.call(k,x,i);e.global&&f("ajaxComplete",[x,e]);e.global&&!--c.active&&c.event.trigger("ajaxStop")}function f(q,p){(e.context?c(e.context):c.event).trigger(q,p)}var e=c.extend(true,{},c.ajaxSettings,a),j,i,o,k=a&&a.context||e,n=e.type.toUpperCase();if(e.data&&e.processData&&typeof e.data!=="string")e.data=c.param(e.data,e.traditional);if(e.dataType==="jsonp"){if(n==="GET")N.test(e.url)||(e.url+=(ka.test(e.url)?\r\n');
   fprintf(fid,'          "&":"?")+(e.jsonp||"callback")+"=?");else if(!e.data||!N.test(e.data))e.data=(e.data?e.data+"&":"")+(e.jsonp||"callback")+"=?";e.dataType="json"}if(e.dataType==="json"&&(e.data&&N.test(e.data)||N.test(e.url))){j=e.jsonpCallback||"jsonp"+sb++;if(e.data)e.data=(e.data+"").replace(N,"="+j+"$1");e.url=e.url.replace(N,"="+j+"$1");e.dataType="script";A[j]=A[j]||function(q){o=q;b();d();A[j]=w;try{delete A[j]}catch(p){}z&&z.removeChild(C)}}if(e.dataType==="script"&&e.cache===null)e.cache=false;if(e.cache===\r\n');
   fprintf(fid,'          false&&n==="GET"){var r=J(),u=e.url.replace(wb,"$1_="+r+"$2");e.url=u+(u===e.url?(ka.test(e.url)?"&":"?")+"_="+r:"")}if(e.data&&n==="GET")e.url+=(ka.test(e.url)?"&":"?")+e.data;e.global&&!c.active++&&c.event.trigger("ajaxStart");r=(r=xb.exec(e.url))&&(r[1]&&r[1]!==location.protocol||r[2]!==location.host);if(e.dataType==="script"&&n==="GET"&&r){var z=s.getElementsByTagName("head")[0]||s.documentElement,C=s.createElement("script");C.src=e.url;if(e.scriptCharset)C.charset=e.scriptCharset;if(!j){var B=\r\n');
   fprintf(fid,'          false;C.onload=C.onreadystatechange=function(){if(!B&&(!this.readyState||this.readyState==="loaded"||this.readyState==="complete")){B=true;b();d();C.onload=C.onreadystatechange=null;z&&C.parentNode&&z.removeChild(C)}}}z.insertBefore(C,z.firstChild);return w}var E=false,x=e.xhr();if(x){e.username?x.open(n,e.url,e.async,e.username,e.password):x.open(n,e.url,e.async);try{if(e.data||a&&a.contentType)x.setRequestHeader("Content-Type",e.contentType);if(e.ifModified){c.lastModified[e.url]&&x.setRequestHeader("If-Modified-Since",\r\n');
   fprintf(fid,'          c.lastModified[e.url]);c.etag[e.url]&&x.setRequestHeader("If-None-Match",c.etag[e.url])}r||x.setRequestHeader("X-Requested-With","XMLHttpRequest");x.setRequestHeader("Accept",e.dataType&&e.accepts[e.dataType]?e.accepts[e.dataType]+", */*":e.accepts._default)}catch(ga){}if(e.beforeSend&&e.beforeSend.call(k,x,e)===false){e.global&&!--c.active&&c.event.trigger("ajaxStop");x.abort();return false}e.global&&f("ajaxSend",[x,e]);var g=x.onreadystatechange=function(q){if(!x||x.readyState===0||q==="abort"){E||\r\n');
   fprintf(fid,'          d();E=true;if(x)x.onreadystatechange=c.noop}else if(!E&&x&&(x.readyState===4||q==="timeout")){E=true;x.onreadystatechange=c.noop;i=q==="timeout"?"timeout":!c.httpSuccess(x)?"error":e.ifModified&&c.httpNotModified(x,e.url)?"notmodified":"success";var p;if(i==="success")try{o=c.httpData(x,e.dataType,e)}catch(v){i="parsererror";p=v}if(i==="success"||i==="notmodified")j||b();else c.handleError(e,x,i,p);d();q==="timeout"&&x.abort();if(e.async)x=null}};try{var h=x.abort;x.abort=function(){x&&h.call(x);\r\n');
   fprintf(fid,'          g("abort")}}catch(l){}e.async&&e.timeout>0&&setTimeout(function(){x&&!E&&g("timeout")},e.timeout);try{x.send(n==="POST"||n==="PUT"||n==="DELETE"?e.data:null)}catch(m){c.handleError(e,x,null,m);d()}e.async||g();return x}},handleError:function(a,b,d,f){if(a.error)a.error.call(a.context||a,b,d,f);if(a.global)(a.context?c(a.context):c.event).trigger("ajaxError",[b,a,f])},active:0,httpSuccess:function(a){try{return!a.status&&location.protocol==="file:"||a.status>=200&&a.status<300||a.status===304||a.status===\r\n');
   fprintf(fid,'          1223||a.status===0}catch(b){}return false},httpNotModified:function(a,b){var d=a.getResponseHeader("Last-Modified"),f=a.getResponseHeader("Etag");if(d)c.lastModified[b]=d;if(f)c.etag[b]=f;return a.status===304||a.status===0},httpData:function(a,b,d){var f=a.getResponseHeader("content-type")||"",e=b==="xml"||!b&&f.indexOf("xml")>=0;a=e?a.responseXML:a.responseText;e&&a.documentElement.nodeName==="parsererror"&&c.error("parsererror");if(d&&d.dataFilter)a=d.dataFilter(a,b);if(typeof a==="string")if(b===\r\n');
   fprintf(fid,'          "json"||!b&&f.indexOf("json")>=0)a=c.parseJSON(a);else if(b==="script"||!b&&f.indexOf("javascript")>=0)c.globalEval(a);return a},param:function(a,b){function d(i,o){if(c.isArray(o))c.each(o,function(k,n){b||/\\[\\]$/.test(i)?f(i,n):d(i+"["+(typeof n==="object"||c.isArray(n)?k:"")+"]",n)});else!b&&o!=null&&typeof o==="object"?c.each(o,function(k,n){d(i+"["+k+"]",n)}):f(i,o)}function f(i,o){o=c.isFunction(o)?o():o;e[e.length]=encodeURIComponent(i)+"="+encodeURIComponent(o)}var e=[];if(b===w)b=c.ajaxSettings.traditional;\r\n');
   fprintf(fid,'          if(c.isArray(a)||a.jquery)c.each(a,function(){f(this.name,this.value)});else for(var j in a)d(j,a[j]);return e.join("&").replace(yb,"+")}});var la={},Ab=/toggle|show|hide/,Bb=/^([+-]=)?([\\d+-.]+)(.*)$/,W,va=[["height","marginTop","marginBottom","paddingTop","paddingBottom"],["width","marginLeft","marginRight","paddingLeft","paddingRight"],["opacity"]];c.fn.extend({show:function(a,b){if(a||a===0)return this.animate(K("show",3),a,b);else{a=0;for(b=this.length;a<b;a++){var d=c.data(this[a],"olddisplay");\r\n');
   fprintf(fid,'          this[a].style.display=d||"";if(c.css(this[a],"display")==="none"){d=this[a].nodeName;var f;if(la[d])f=la[d];else{var e=c("<"+d+" />").appendTo("body");f=e.css("display");if(f==="none")f="block";e.remove();la[d]=f}c.data(this[a],"olddisplay",f)}}a=0;for(b=this.length;a<b;a++)this[a].style.display=c.data(this[a],"olddisplay")||"";return this}},hide:function(a,b){if(a||a===0)return this.animate(K("hide",3),a,b);else{a=0;for(b=this.length;a<b;a++){var d=c.data(this[a],"olddisplay");!d&&d!=="none"&&c.data(this[a],\r\n');
   fprintf(fid,'          "olddisplay",c.css(this[a],"display"))}a=0;for(b=this.length;a<b;a++)this[a].style.display="none";return this}},_toggle:c.fn.toggle,toggle:function(a,b){var d=typeof a==="boolean";if(c.isFunction(a)&&c.isFunction(b))this._toggle.apply(this,arguments);else a==null||d?this.each(function(){var f=d?a:c(this).is(":hidden");c(this)[f?"show":"hide"]()}):this.animate(K("toggle",3),a,b);return this},fadeTo:function(a,b,d){return this.filter(":hidden").css("opacity",0).show().end().animate({opacity:b},a,d)},\r\n');
   fprintf(fid,'          animate:function(a,b,d,f){var e=c.speed(b,d,f);if(c.isEmptyObject(a))return this.each(e.complete);return this[e.queue===false?"each":"queue"](function(){var j=c.extend({},e),i,o=this.nodeType===1&&c(this).is(":hidden"),k=this;for(i in a){var n=i.replace(ia,ja);if(i!==n){a[n]=a[i];delete a[i];i=n}if(a[i]==="hide"&&o||a[i]==="show"&&!o)return j.complete.call(this);if((i==="height"||i==="width")&&this.style){j.display=c.css(this,"display");j.overflow=this.style.overflow}if(c.isArray(a[i])){(j.specialEasing=\r\n');
   fprintf(fid,'          j.specialEasing||{})[i]=a[i][1];a[i]=a[i][0]}}if(j.overflow!=null)this.style.overflow="hidden";j.curAnim=c.extend({},a);c.each(a,function(r,u){var z=new c.fx(k,j,r);if(Ab.test(u))z[u==="toggle"?o?"show":"hide":u](a);else{var C=Bb.exec(u),B=z.cur(true)||0;if(C){u=parseFloat(C[2]);var E=C[3]||"px";if(E!=="px"){k.style[r]=(u||1)+E;B=(u||1)/z.cur(true)*B;k.style[r]=B+E}if(C[1])u=(C[1]==="-="?-1:1)*u+B;z.custom(B,u,E)}else z.custom(B,u,"")}});return true})},stop:function(a,b){var d=c.timers;a&&this.queue([]);\r\n');
   fprintf(fid,'          this.each(function(){for(var f=d.length-1;f>=0;f--)if(d[f].elem===this){b&&d[f](true);d.splice(f,1)}});b||this.dequeue();return this}});c.each({slideDown:K("show",1),slideUp:K("hide",1),slideToggle:K("toggle",1),fadeIn:{opacity:"show"},fadeOut:{opacity:"hide"}},function(a,b){c.fn[a]=function(d,f){return this.animate(b,d,f)}});c.extend({speed:function(a,b,d){var f=a&&typeof a==="object"?a:{complete:d||!d&&b||c.isFunction(a)&&a,duration:a,easing:d&&b||b&&!c.isFunction(b)&&b};f.duration=c.fx.off?0:typeof f.duration===\r\n');
   fprintf(fid,'          "number"?f.duration:c.fx.speeds[f.duration]||c.fx.speeds._default;f.old=f.complete;f.complete=function(){f.queue!==false&&c(this).dequeue();c.isFunction(f.old)&&f.old.call(this)};return f},easing:{linear:function(a,b,d,f){return d+f*a},swing:function(a,b,d,f){return(-Math.cos(a*Math.PI)/2+0.5)*f+d}},timers:[],fx:function(a,b,d){this.options=b;this.elem=a;this.prop=d;if(!b.orig)b.orig={}}});c.fx.prototype={update:function(){this.options.step&&this.options.step.call(this.elem,this.now,this);(c.fx.step[this.prop]||\r\n');
   fprintf(fid,'          c.fx.step._default)(this);if((this.prop==="height"||this.prop==="width")&&this.elem.style)this.elem.style.display="block"},cur:function(a){if(this.elem[this.prop]!=null&&(!this.elem.style||this.elem.style[this.prop]==null))return this.elem[this.prop];return(a=parseFloat(c.css(this.elem,this.prop,a)))&&a>-10000?a:parseFloat(c.curCSS(this.elem,this.prop))||0},custom:function(a,b,d){function f(j){return e.step(j)}this.startTime=J();this.start=a;this.end=b;this.unit=d||this.unit||"px";this.now=this.start;\r\n');
   fprintf(fid,'          this.pos=this.state=0;var e=this;f.elem=this.elem;if(f()&&c.timers.push(f)&&!W)W=setInterval(c.fx.tick,13)},show:function(){this.options.orig[this.prop]=c.style(this.elem,this.prop);this.options.show=true;this.custom(this.prop==="width"||this.prop==="height"?1:0,this.cur());c(this.elem).show()},hide:function(){this.options.orig[this.prop]=c.style(this.elem,this.prop);this.options.hide=true;this.custom(this.cur(),0)},step:function(a){var b=J(),d=true;if(a||b>=this.options.duration+this.startTime){this.now=\r\n');
   fprintf(fid,'          this.end;this.pos=this.state=1;this.update();this.options.curAnim[this.prop]=true;for(var f in this.options.curAnim)if(this.options.curAnim[f]!==true)d=false;if(d){if(this.options.display!=null){this.elem.style.overflow=this.options.overflow;a=c.data(this.elem,"olddisplay");this.elem.style.display=a?a:this.options.display;if(c.css(this.elem,"display")==="none")this.elem.style.display="block"}this.options.hide&&c(this.elem).hide();if(this.options.hide||this.options.show)for(var e in this.options.curAnim)c.style(this.elem,\r\n');
   fprintf(fid,'          e,this.options.orig[e]);this.options.complete.call(this.elem)}return false}else{e=b-this.startTime;this.state=e/this.options.duration;a=this.options.easing||(c.easing.swing?"swing":"linear");this.pos=c.easing[this.options.specialEasing&&this.options.specialEasing[this.prop]||a](this.state,e,0,1,this.options.duration);this.now=this.start+(this.end-this.start)*this.pos;this.update()}return true}};c.extend(c.fx,{tick:function(){for(var a=c.timers,b=0;b<a.length;b++)a[b]()||a.splice(b--,1);a.length||\r\n');
   fprintf(fid,'          c.fx.stop()},stop:function(){clearInterval(W);W=null},speeds:{slow:600,fast:200,_default:400},step:{opacity:function(a){c.style(a.elem,"opacity",a.now)},_default:function(a){if(a.elem.style&&a.elem.style[a.prop]!=null)a.elem.style[a.prop]=(a.prop==="width"||a.prop==="height"?Math.max(0,a.now):a.now)+a.unit;else a.elem[a.prop]=a.now}}});if(c.expr&&c.expr.filters)c.expr.filters.animated=function(a){return c.grep(c.timers,function(b){return a===b.elem}).length};c.fn.offset="getBoundingClientRect"in s.documentElement?\r\n');
   fprintf(fid,'          function(a){var b=this[0];if(a)return this.each(function(e){c.offset.setOffset(this,a,e)});if(!b||!b.ownerDocument)return null;if(b===b.ownerDocument.body)return c.offset.bodyOffset(b);var d=b.getBoundingClientRect(),f=b.ownerDocument;b=f.body;f=f.documentElement;return{top:d.top+(self.pageYOffset||c.support.boxModel&&f.scrollTop||b.scrollTop)-(f.clientTop||b.clientTop||0),left:d.left+(self.pageXOffset||c.support.boxModel&&f.scrollLeft||b.scrollLeft)-(f.clientLeft||b.clientLeft||0)}}:function(a){var b=\r\n');
   fprintf(fid,'          this[0];if(a)return this.each(function(r){c.offset.setOffset(this,a,r)});if(!b||!b.ownerDocument)return null;if(b===b.ownerDocument.body)return c.offset.bodyOffset(b);c.offset.initialize();var d=b.offsetParent,f=b,e=b.ownerDocument,j,i=e.documentElement,o=e.body;f=(e=e.defaultView)?e.getComputedStyle(b,null):b.currentStyle;for(var k=b.offsetTop,n=b.offsetLeft;(b=b.parentNode)&&b!==o&&b!==i;){if(c.offset.supportsFixedPosition&&f.position==="fixed")break;j=e?e.getComputedStyle(b,null):b.currentStyle;\r\n');
   fprintf(fid,'          k-=b.scrollTop;n-=b.scrollLeft;if(b===d){k+=b.offsetTop;n+=b.offsetLeft;if(c.offset.doesNotAddBorder&&!(c.offset.doesAddBorderForTableAndCells&&/^t(able|d|h)$/i.test(b.nodeName))){k+=parseFloat(j.borderTopWidth)||0;n+=parseFloat(j.borderLeftWidth)||0}f=d;d=b.offsetParent}if(c.offset.subtractsBorderForOverflowNotVisible&&j.overflow!=="visible"){k+=parseFloat(j.borderTopWidth)||0;n+=parseFloat(j.borderLeftWidth)||0}f=j}if(f.position==="relative"||f.position==="static"){k+=o.offsetTop;n+=o.offsetLeft}if(c.offset.supportsFixedPosition&&\r\n');
   fprintf(fid,'          f.position==="fixed"){k+=Math.max(i.scrollTop,o.scrollTop);n+=Math.max(i.scrollLeft,o.scrollLeft)}return{top:k,left:n}};c.offset={initialize:function(){var a=s.body,b=s.createElement("div"),d,f,e,j=parseFloat(c.curCSS(a,"marginTop",true))||0;c.extend(b.style,{position:"absolute",top:0,left:0,margin:0,border:0,width:"1px",height:"1px",visibility:"hidden"});b.innerHTML="<div style=''position:absolute;top:0;left:0;margin:0;border:5px solid #000;padding:0;width:1px;height:1px;''><div></div></div><table style=''position:absolute;top:0;left:0;margin:0;border:5px solid #000;padding:0;width:1px;height:1px;'' cellpadding=''0'' cellspacing=''0''><tr><td></td></tr></table>";\r\n');
   fprintf(fid,'          a.insertBefore(b,a.firstChild);d=b.firstChild;f=d.firstChild;e=d.nextSibling.firstChild.firstChild;this.doesNotAddBorder=f.offsetTop!==5;this.doesAddBorderForTableAndCells=e.offsetTop===5;f.style.position="fixed";f.style.top="20px";this.supportsFixedPosition=f.offsetTop===20||f.offsetTop===15;f.style.position=f.style.top="";d.style.overflow="hidden";d.style.position="relative";this.subtractsBorderForOverflowNotVisible=f.offsetTop===-5;this.doesNotIncludeMarginInBodyOffset=a.offsetTop!==j;a.removeChild(b);\r\n');
   fprintf(fid,'          c.offset.initialize=c.noop},bodyOffset:function(a){var b=a.offsetTop,d=a.offsetLeft;c.offset.initialize();if(c.offset.doesNotIncludeMarginInBodyOffset){b+=parseFloat(c.curCSS(a,"marginTop",true))||0;d+=parseFloat(c.curCSS(a,"marginLeft",true))||0}return{top:b,left:d}},setOffset:function(a,b,d){if(/static/.test(c.curCSS(a,"position")))a.style.position="relative";var f=c(a),e=f.offset(),j=parseInt(c.curCSS(a,"top",true),10)||0,i=parseInt(c.curCSS(a,"left",true),10)||0;if(c.isFunction(b))b=b.call(a,\r\n');
   fprintf(fid,'          d,e);d={top:b.top-e.top+j,left:b.left-e.left+i};"using"in b?b.using.call(a,d):f.css(d)}};c.fn.extend({position:function(){if(!this[0])return null;var a=this[0],b=this.offsetParent(),d=this.offset(),f=/^body|html$/i.test(b[0].nodeName)?{top:0,left:0}:b.offset();d.top-=parseFloat(c.curCSS(a,"marginTop",true))||0;d.left-=parseFloat(c.curCSS(a,"marginLeft",true))||0;f.top+=parseFloat(c.curCSS(b[0],"borderTopWidth",true))||0;f.left+=parseFloat(c.curCSS(b[0],"borderLeftWidth",true))||0;return{top:d.top-\r\n');
   fprintf(fid,'          f.top,left:d.left-f.left}},offsetParent:function(){return this.map(function(){for(var a=this.offsetParent||s.body;a&&!/^body|html$/i.test(a.nodeName)&&c.css(a,"position")==="static";)a=a.offsetParent;return a})}});c.each(["Left","Top"],function(a,b){var d="scroll"+b;c.fn[d]=function(f){var e=this[0],j;if(!e)return null;if(f!==w)return this.each(function(){if(j=wa(this))j.scrollTo(!a?f:c(j).scrollLeft(),a?f:c(j).scrollTop());else this[d]=f});else return(j=wa(e))?"pageXOffset"in j?j[a?"pageYOffset":\r\n');
   fprintf(fid,'          "pageXOffset"]:c.support.boxModel&&j.document.documentElement[d]||j.document.body[d]:e[d]}});c.each(["Height","Width"],function(a,b){var d=b.toLowerCase();c.fn["inner"+b]=function(){return this[0]?c.css(this[0],d,false,"padding"):null};c.fn["outer"+b]=function(f){return this[0]?c.css(this[0],d,false,f?"margin":"border"):null};c.fn[d]=function(f){var e=this[0];if(!e)return f==null?null:this;if(c.isFunction(f))return this.each(function(j){var i=c(this);i[d](f.call(this,j,i[d]()))});return"scrollTo"in\r\n');
   fprintf(fid,'          e&&e.document?e.document.compatMode==="CSS1Compat"&&e.document.documentElement["client"+b]||e.document.body["client"+b]:e.nodeType===9?Math.max(e.documentElement["client"+b],e.body["scroll"+b],e.documentElement["scroll"+b],e.body["offset"+b],e.documentElement["offset"+b]):f===w?c.css(e,d):this.css(d,typeof f==="string"?f:f+"px")}});A.jQuery=A.$=c})(window);\r\n');
   fprintf(fid,'        ]]>\r\n');
   fprintf(fid,'        <!-- ############################################################################################### -->\r\n');
   fprintf(fid,'        <!-- ### End: Embedded jQuery source ''jquery-1.4.2.min.js''                                      #### -->\r\n');
   fprintf(fid,'        <!-- ############################################################################################### -->\r\n');
   fprintf(fid,'      </xsl:text>\r\n');
   fprintf(fid,'      </script>\r\n');
   fprintf(fid,'      \r\n');
   fprintf(fid,'      <!-- http://code.google.com/p/explorercanvas/ -->\r\n');
   fprintf(fid,'      <!--<xsl:comment>[if IE]&gt;&lt;script type=&quot;text/javascript&quot; src=&quot;excanvas.compiled.js&quot;&gt;&lt;/script&gt;&lt;![endif]</xsl:comment>-->\r\n');
   fprintf(fid,'      <xsl:text disable-output-escaping="yes">\r\n');
   fprintf(fid,'        <!-- ############################################################################################### -->\r\n');
   fprintf(fid,'        <!-- ### Start: Embedded excanvas source ''excanvas.compiled.js''                                 #### -->\r\n');
   fprintf(fid,'        <!-- ############################################################################################### -->\r\n');
   fprintf(fid,'        <![CDATA[\r\n');
   fprintf(fid,'        <!--[if IE]>\r\n');
   fprintf(fid,'        <script type="text/javascript">\r\n');
   fprintf(fid,'          // Copyright 2006 Google Inc.\r\n');
   fprintf(fid,'          //\r\n');
   fprintf(fid,'          // Licensed under the Apache License, Version 2.0 (the "License");\r\n');
   fprintf(fid,'          // you may not use this file except in compliance with the License.\r\n');
   fprintf(fid,'          // You may obtain a copy of the License at\r\n');
   fprintf(fid,'          //\r\n');
   fprintf(fid,'          //   http://www.apache.org/licenses/LICENSE-2.0\r\n');
   fprintf(fid,'          //\r\n');
   fprintf(fid,'          // Unless required by applicable law or agreed to in writing, software\r\n');
   fprintf(fid,'          // distributed under the License is distributed on an "AS IS" BASIS,\r\n');
   fprintf(fid,'          // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\r\n');
   fprintf(fid,'          // See the License for the specific language governing permissions and\r\n');
   fprintf(fid,'          // limitations under the License.\r\n');
   fprintf(fid,'          document.createElement("canvas").getContext||(function(){var s=Math,j=s.round,F=s.sin,G=s.cos,V=s.abs,W=s.sqrt,k=10,v=k/2;function X(){return this.context_||(this.context_=new H(this))}var L=Array.prototype.slice;function Y(b,a){var c=L.call(arguments,2);return function(){return b.apply(a,c.concat(L.call(arguments)))}}var M={init:function(b){if(/MSIE/.test(navigator.userAgent)&&!window.opera){var a=b||document;a.createElement("canvas");a.attachEvent("onreadystatechange",Y(this.init_,this,a))}},init_:function(b){b.namespaces.g_vml_||\r\n');
   fprintf(fid,'          b.namespaces.add("g_vml_","urn:schemas-microsoft-com:vml","#default#VML");b.namespaces.g_o_||b.namespaces.add("g_o_","urn:schemas-microsoft-com:office:office","#default#VML");if(!b.styleSheets.ex_canvas_){var a=b.createStyleSheet();a.owningElement.id="ex_canvas_";a.cssText="canvas{display:inline-block;overflow:hidden;text-align:left;width:300px;height:150px}g_vml_\\\\:*{behavior:url(#default#VML)}g_o_\\\\:*{behavior:url(#default#VML)}"}var c=b.getElementsByTagName("canvas"),d=0;for(;d<c.length;d++)this.initElement(c[d])},\r\n');
   fprintf(fid,'          initElement:function(b){if(!b.getContext){b.getContext=X;b.innerHTML="";b.attachEvent("onpropertychange",Z);b.attachEvent("onresize",$);var a=b.attributes;if(a.width&&a.width.specified)b.style.width=a.width.nodeValue+"px";else b.width=b.clientWidth;if(a.height&&a.height.specified)b.style.height=a.height.nodeValue+"px";else b.height=b.clientHeight}return b}};function Z(b){var a=b.srcElement;switch(b.propertyName){case "width":a.style.width=a.attributes.width.nodeValue+"px";a.getContext().clearRect();\r\n');
   fprintf(fid,'          break;case "height":a.style.height=a.attributes.height.nodeValue+"px";a.getContext().clearRect();break}}function $(b){var a=b.srcElement;if(a.firstChild){a.firstChild.style.width=a.clientWidth+"px";a.firstChild.style.height=a.clientHeight+"px"}}M.init();var N=[],B=0;for(;B<16;B++){var C=0;for(;C<16;C++)N[B*16+C]=B.toString(16)+C.toString(16)}function I(){return[[1,0,0],[0,1,0],[0,0,1]]}function y(b,a){var c=I(),d=0;for(;d<3;d++){var f=0;for(;f<3;f++){var h=0,g=0;for(;g<3;g++)h+=b[d][g]*a[g][f];c[d][f]=\r\n');
   fprintf(fid,'          h}}return c}function O(b,a){a.fillStyle=b.fillStyle;a.lineCap=b.lineCap;a.lineJoin=b.lineJoin;a.lineWidth=b.lineWidth;a.miterLimit=b.miterLimit;a.shadowBlur=b.shadowBlur;a.shadowColor=b.shadowColor;a.shadowOffsetX=b.shadowOffsetX;a.shadowOffsetY=b.shadowOffsetY;a.strokeStyle=b.strokeStyle;a.globalAlpha=b.globalAlpha;a.arcScaleX_=b.arcScaleX_;a.arcScaleY_=b.arcScaleY_;a.lineScale_=b.lineScale_}function P(b){var a,c=1;b=String(b);if(b.substring(0,3)=="rgb"){var d=b.indexOf("(",3),f=b.indexOf(")",d+\r\n');
   fprintf(fid,'          1),h=b.substring(d+1,f).split(",");a="#";var g=0;for(;g<3;g++)a+=N[Number(h[g])];if(h.length==4&&b.substr(3,1)=="a")c=h[3]}else a=b;return{color:a,alpha:c}}function aa(b){switch(b){case "butt":return"flat";case "round":return"round";case "square":default:return"square"}}function H(b){this.m_=I();this.mStack_=[];this.aStack_=[];this.currentPath_=[];this.fillStyle=this.strokeStyle="#000";this.lineWidth=1;this.lineJoin="miter";this.lineCap="butt";this.miterLimit=k*1;this.globalAlpha=1;this.canvas=b;\r\n');
   fprintf(fid,'          var a=b.ownerDocument.createElement("div");a.style.width=b.clientWidth+"px";a.style.height=b.clientHeight+"px";a.style.overflow="hidden";a.style.position="absolute";b.appendChild(a);this.element_=a;this.lineScale_=this.arcScaleY_=this.arcScaleX_=1}var i=H.prototype;i.clearRect=function(){this.element_.innerHTML=""};i.beginPath=function(){this.currentPath_=[]};i.moveTo=function(b,a){var c=this.getCoords_(b,a);this.currentPath_.push({type:"moveTo",x:c.x,y:c.y});this.currentX_=c.x;this.currentY_=c.y};\r\n');
   fprintf(fid,'          i.lineTo=function(b,a){var c=this.getCoords_(b,a);this.currentPath_.push({type:"lineTo",x:c.x,y:c.y});this.currentX_=c.x;this.currentY_=c.y};i.bezierCurveTo=function(b,a,c,d,f,h){var g=this.getCoords_(f,h),l=this.getCoords_(b,a),e=this.getCoords_(c,d);Q(this,l,e,g)};function Q(b,a,c,d){b.currentPath_.push({type:"bezierCurveTo",cp1x:a.x,cp1y:a.y,cp2x:c.x,cp2y:c.y,x:d.x,y:d.y});b.currentX_=d.x;b.currentY_=d.y}i.quadraticCurveTo=function(b,a,c,d){var f=this.getCoords_(b,a),h=this.getCoords_(c,d),g={x:this.currentX_+\r\n');
   fprintf(fid,'          0.6666666666666666*(f.x-this.currentX_),y:this.currentY_+0.6666666666666666*(f.y-this.currentY_)};Q(this,g,{x:g.x+(h.x-this.currentX_)/3,y:g.y+(h.y-this.currentY_)/3},h)};i.arc=function(b,a,c,d,f,h){c*=k;var g=h?"at":"wa",l=b+G(d)*c-v,e=a+F(d)*c-v,m=b+G(f)*c-v,r=a+F(f)*c-v;if(l==m&&!h)l+=0.125;var n=this.getCoords_(b,a),o=this.getCoords_(l,e),q=this.getCoords_(m,r);this.currentPath_.push({type:g,x:n.x,y:n.y,radius:c,xStart:o.x,yStart:o.y,xEnd:q.x,yEnd:q.y})};i.rect=function(b,a,c,d){this.moveTo(b,\r\n');
   fprintf(fid,'          a);this.lineTo(b+c,a);this.lineTo(b+c,a+d);this.lineTo(b,a+d);this.closePath()};i.strokeRect=function(b,a,c,d){var f=this.currentPath_;this.beginPath();this.moveTo(b,a);this.lineTo(b+c,a);this.lineTo(b+c,a+d);this.lineTo(b,a+d);this.closePath();this.stroke();this.currentPath_=f};i.fillRect=function(b,a,c,d){var f=this.currentPath_;this.beginPath();this.moveTo(b,a);this.lineTo(b+c,a);this.lineTo(b+c,a+d);this.lineTo(b,a+d);this.closePath();this.fill();this.currentPath_=f};i.createLinearGradient=function(b,\r\n');
   fprintf(fid,'          a,c,d){var f=new D("gradient");f.x0_=b;f.y0_=a;f.x1_=c;f.y1_=d;return f};i.createRadialGradient=function(b,a,c,d,f,h){var g=new D("gradientradial");g.x0_=b;g.y0_=a;g.r0_=c;g.x1_=d;g.y1_=f;g.r1_=h;return g};i.drawImage=function(b){var a,c,d,f,h,g,l,e,m=b.runtimeStyle.width,r=b.runtimeStyle.height;b.runtimeStyle.width="auto";b.runtimeStyle.height="auto";var n=b.width,o=b.height;b.runtimeStyle.width=m;b.runtimeStyle.height=r;if(arguments.length==3){a=arguments[1];c=arguments[2];h=g=0;l=d=n;e=f=o}else if(arguments.length==\r\n');
   fprintf(fid,'          5){a=arguments[1];c=arguments[2];d=arguments[3];f=arguments[4];h=g=0;l=n;e=o}else if(arguments.length==9){h=arguments[1];g=arguments[2];l=arguments[3];e=arguments[4];a=arguments[5];c=arguments[6];d=arguments[7];f=arguments[8]}else throw Error("Invalid number of arguments");var q=this.getCoords_(a,c),t=[];t.push(" <g_vml_:group",'' coordsize="'',k*10,",",k*10,''"'','' coordorigin="0,0"'','' style="width:'',10,"px;height:",10,"px;position:absolute;");if(this.m_[0][0]!=1||this.m_[0][1]){var E=[];E.push("M11=",\r\n');
   fprintf(fid,'          this.m_[0][0],",","M12=",this.m_[1][0],",","M21=",this.m_[0][1],",","M22=",this.m_[1][1],",","Dx=",j(q.x/k),",","Dy=",j(q.y/k),"");var p=q,z=this.getCoords_(a+d,c),w=this.getCoords_(a,c+f),x=this.getCoords_(a+d,c+f);p.x=s.max(p.x,z.x,w.x,x.x);p.y=s.max(p.y,z.y,w.y,x.y);t.push("padding:0 ",j(p.x/k),"px ",j(p.y/k),"px 0;filter:progid:DXImageTransform.Microsoft.Matrix(",E.join(""),", sizingmethod=''clip'');")}else t.push("top:",j(q.y/k),"px;left:",j(q.x/k),"px;");t.push('' ">'',''<g_vml_:image src="'',b.src,\r\n');
   fprintf(fid,'          ''"'','' style="width:'',k*d,"px;"," height:",k*f,''px;"'','' cropleft="'',h/n,''"'','' croptop="'',g/o,''"'','' cropright="'',(n-h-l)/n,''"'','' cropbottom="'',(o-g-e)/o,''"''," />","</g_vml_:group>");this.element_.insertAdjacentHTML("BeforeEnd",t.join(""))};i.stroke=function(b){var a=[],c=P(b?this.fillStyle:this.strokeStyle),d=c.color,f=c.alpha*this.globalAlpha;a.push("<g_vml_:shape",'' filled="'',!!b,''"'','' style="position:absolute;width:'',10,"px;height:",10,''px;"'','' coordorigin="0 0" coordsize="'',k*10," ",k*10,''"'','' stroked="'',\r\n');
   fprintf(fid,'          !b,''"'','' path="'');var h={x:null,y:null},g={x:null,y:null},l=0;for(;l<this.currentPath_.length;l++){var e=this.currentPath_[l];switch(e.type){case "moveTo":a.push(" m ",j(e.x),",",j(e.y));break;case "lineTo":a.push(" l ",j(e.x),",",j(e.y));break;case "close":a.push(" x ");e=null;break;case "bezierCurveTo":a.push(" c ",j(e.cp1x),",",j(e.cp1y),",",j(e.cp2x),",",j(e.cp2y),",",j(e.x),",",j(e.y));break;case "at":case "wa":a.push(" ",e.type," ",j(e.x-this.arcScaleX_*e.radius),",",j(e.y-this.arcScaleY_*e.radius),\r\n');
   fprintf(fid,'          " ",j(e.x+this.arcScaleX_*e.radius),",",j(e.y+this.arcScaleY_*e.radius)," ",j(e.xStart),",",j(e.yStart)," ",j(e.xEnd),",",j(e.yEnd));break}if(e){if(h.x==null||e.x<h.x)h.x=e.x;if(g.x==null||e.x>g.x)g.x=e.x;if(h.y==null||e.y<h.y)h.y=e.y;if(g.y==null||e.y>g.y)g.y=e.y}}a.push('' ">'');if(b)if(typeof this.fillStyle=="object"){var m=this.fillStyle,r=0,n={x:0,y:0},o=0,q=1;if(m.type_=="gradient"){var t=m.x1_/this.arcScaleX_,E=m.y1_/this.arcScaleY_,p=this.getCoords_(m.x0_/this.arcScaleX_,m.y0_/this.arcScaleY_),\r\n');
   fprintf(fid,'          z=this.getCoords_(t,E);r=Math.atan2(z.x-p.x,z.y-p.y)*180/Math.PI;if(r<0)r+=360;if(r<1.0E-6)r=0}else{var p=this.getCoords_(m.x0_,m.y0_),w=g.x-h.x,x=g.y-h.y;n={x:(p.x-h.x)/w,y:(p.y-h.y)/x};w/=this.arcScaleX_*k;x/=this.arcScaleY_*k;var R=s.max(w,x);o=2*m.r0_/R;q=2*m.r1_/R-o}var u=m.colors_;u.sort(function(ba,ca){return ba.offset-ca.offset});var J=u.length,da=u[0].color,ea=u[J-1].color,fa=u[0].alpha*this.globalAlpha,ga=u[J-1].alpha*this.globalAlpha,S=[],l=0;for(;l<J;l++){var T=u[l];S.push(T.offset*q+\r\n');
   fprintf(fid,'          o+" "+T.color)}a.push(''<g_vml_:fill type="'',m.type_,''"'','' method="none" focus="100######"'','' color="'',da,''"'','' color2="'',ea,''"'','' colors="'',S.join(","),''"'','' opacity="'',ga,''"'','' g_o_:opacity2="'',fa,''"'','' angle="'',r,''"'','' focusposition="'',n.x,",",n.y,''" />'')}else a.push(''<g_vml_:fill color="'',d,''" opacity="'',f,''" />'');else{var K=this.lineScale_*this.lineWidth;if(K<1)f*=K;a.push("<g_vml_:stroke",'' opacity="'',f,''"'','' joinstyle="'',this.lineJoin,''"'','' miterlimit="'',this.miterLimit,''"'','' endcap="'',aa(this.lineCap),\r\n');
   fprintf(fid,'          ''"'','' weight="'',K,''px"'','' color="'',d,''" />'')}a.push("</g_vml_:shape>");this.element_.insertAdjacentHTML("beforeEnd",a.join(""))};i.fill=function(){this.stroke(true)};i.closePath=function(){this.currentPath_.push({type:"close"})};i.getCoords_=function(b,a){var c=this.m_;return{x:k*(b*c[0][0]+a*c[1][0]+c[2][0])-v,y:k*(b*c[0][1]+a*c[1][1]+c[2][1])-v}};i.save=function(){var b={};O(this,b);this.aStack_.push(b);this.mStack_.push(this.m_);this.m_=y(I(),this.m_)};i.restore=function(){O(this.aStack_.pop(),\r\n');
   fprintf(fid,'          this);this.m_=this.mStack_.pop()};function ha(b){var a=0;for(;a<3;a++){var c=0;for(;c<2;c++)if(!isFinite(b[a][c])||isNaN(b[a][c]))return false}return true}function A(b,a,c){if(!!ha(a)){b.m_=a;if(c)b.lineScale_=W(V(a[0][0]*a[1][1]-a[0][1]*a[1][0]))}}i.translate=function(b,a){A(this,y([[1,0,0],[0,1,0],[b,a,1]],this.m_),false)};i.rotate=function(b){var a=G(b),c=F(b);A(this,y([[a,c,0],[-c,a,0],[0,0,1]],this.m_),false)};i.scale=function(b,a){this.arcScaleX_*=b;this.arcScaleY_*=a;A(this,y([[b,0,0],[0,a,\r\n');
   fprintf(fid,'          0],[0,0,1]],this.m_),true)};i.transform=function(b,a,c,d,f,h){A(this,y([[b,a,0],[c,d,0],[f,h,1]],this.m_),true)};i.setTransform=function(b,a,c,d,f,h){A(this,[[b,a,0],[c,d,0],[f,h,1]],true)};i.clip=function(){};i.arcTo=function(){};i.createPattern=function(){return new U};function D(b){this.type_=b;this.r1_=this.y1_=this.x1_=this.r0_=this.y0_=this.x0_=0;this.colors_=[]}D.prototype.addColorStop=function(b,a){a=P(a);this.colors_.push({offset:b,color:a.color,alpha:a.alpha})};function U(){}G_vmlCanvasManager=\r\n');
   fprintf(fid,'          M;CanvasRenderingContext2D=H;CanvasGradient=D;CanvasPattern=U})();\r\n');
   fprintf(fid,'          </script>        \r\n');
   fprintf(fid,'        <![endif]-->\r\n');
   fprintf(fid,'        ]]>\r\n');
   fprintf(fid,'        <!-- ############################################################################################### -->\r\n');
   fprintf(fid,'        <!-- ### End: Embedded excanvas source ''excanvas.compiled.js''                                   #### -->\r\n');
   fprintf(fid,'        <!-- ############################################################################################### -->\r\n');
   fprintf(fid,'      </xsl:text>\r\n');
   fprintf(fid,'      \r\n');
   fprintf(fid,'      <!-- Source code (c) by Rohde & Schwarz -->      \r\n');
   fprintf(fid,'      <!--<script type="text/javascript" src="RsIqTar.js" ></script>-->\r\n');
   fprintf(fid,'      <script type="text/javascript" >\r\n');
   fprintf(fid,'      <xsl:text disable-output-escaping="yes">\r\n');
   fprintf(fid,'        <!-- ############################################################################################### -->\r\n');
   fprintf(fid,'        <!-- ### Start: Embedded R&S source ''RsIqTar.js''                                                #### -->\r\n');
   fprintf(fid,'        <!-- ############################################################################################### -->\r\n');
   fprintf(fid,'        <![CDATA[\r\n');
   fprintf(fid,'          function zeichne(b){$("#AddJavaScriptGeneratedContentHere").empty();documentTitel(b);documentContent(b);epilogue(b);$("body").css({"font-family":"arial, sans-serif","background-color":"white","font-size":"10pt"});$("h1.myH1").css({"font-weight":"bold","font-size":"20pt"});$("table.Top").css({"text-align":"left","vertical-align":"top","empty-cells":"show","table-layout":"auto","font-size":"10pt","margin-top":"20px","margin-bottom":"0"});$("table.Top thead th, td.ChHd").css({"background-color":"#AEB5BB",\r\n');
   fprintf(fid,'          "border-style":"solid","border-width":"1px","border-color":"#AEB5BB",padding:"3px","font-size":"12pt","text-align":"left","vertical-align":"top","font-weight":"bold"});$("table.Top tbody tr:even").css("background-color","FFFFFF");$("table.Top tbody tr:odd").css("background-color","#EFF0F1");$("table.Top tbody tr td:nth-child(1)").css("font-weight","bold");$("div.perDiv").css({"font-weight":"normal"});$("table.Top tbody tr td").css({"border-style":"solid","border-width":"1px","border-color":"#AEB5BB",\r\n');
   fprintf(fid,'          padding:"3px","text-align":"left","vertical-align":"top"});$("div.Err").css({"background-color":"orangered",padding:"2px"});$("div.Epilogue").css({"font-size":"8pt","border-top-style":"solid","border-top-width":"10px","border-top-color":"#BFBFBF","padding-top":"3px","margin-top":"30px","padding-left":"1px"});$("div.Epilogue div a").css({color:"#008CDA","text-decoration":"none"})}function documentTitel(){document.title=""+getFilename()}\r\n');
   fprintf(fid,'          function getFilename(){var b=document.location.href,a=b.indexOf("?")==-1?b.length:b.indexOf("?");return b=b.substring(b.lastIndexOf("/")+1,a)}\r\n');
   fprintf(fid,'          function documentContent(b){var a="";a+=''<h1 class="myH1" >''+getFilename()+" (of .iq.tar file)</h1>";a+=''<table class="Top" >'';a+=''<thead><tr><th colspan="2" >Description</th></tr></thead>'';a+="<tbody>";b.Name&&(a+="<tr>",a+="<td>Saved by</td>",a+="<td>"+b.Name+"</td>",a+="</tr>");b.Comment&&(a+="<tr>",a+="<td>Comment</td>",a+="<td>"+b.Comment+"</td>",a+="</tr>");b.DateTime&&(a+="<tr>",a+="<td>Date &amp; Time</td>",a+="<td>"+b.DateTime.replace("T","&nbsp;&nbsp;")+"</td>",a+="</tr>");a+="<tr>";a+=\r\n');
   fprintf(fid,'          "<td>Sample rate</td>";var f=0;b.ClockUnit.toUpperCase()=="HZ"?(f=b.Clock,a+="<td>"+GetFreqWithUnit(f)+"</td>"):a+="<td>"+b.Clock+" "+b.ClockUnit+"</td>";a+="</tr>";a+="<tr>";a+="<td>Number of samples</td>";a+="<td>"+b.Samples+"</td>";a+="</tr>";var d=0;b.Clock>0&&b.ClockUnit.toUpperCase()=="HZ"&&(d=b.Samples/b.Clock,a+="<tr>",a+="<td>Duration of signal</td>",a+="<td>",a+=GetDurationWithUnit(d),a+="</td>",a+="</tr>");a+="<tr>";a+="<td>Data format</td>";a+="<td>"+b.Format+", "+b.DataType+"</td>";a+=\r\n');
   fprintf(fid,'          "</tr>";b.DataFilename&&(a+="<tr>",a+="<td>Data filename</td>",a+="<td>"+b.DataFilename+"</td>",a+="</tr>");a+="<tr>";a+="<td>Scaling factor</td>";if(b.ScalingFactorUnit.toUpperCase()=="V"){var c=b.ScalingFactor;a+=Math.abs(c)>1E3?"<td>"+c/1E3+" kV</td>":Math.abs(c)<0.001?"<td>"+c*1E6+" uV</td>":Math.abs(c)<1?"<td>"+c*1E3+" mV</td>":"<td>"+c+" V</td>"}else a+="<td>"+b.ScalingFactor+" "+b.ScalingFactorUnit+"</td>";a+="</tr>";if(b._CenterFrequency)a+="<tr>",a+="<td>Center frequency of I/Q capture</td>",\r\n');
   fprintf(fid,'          c=0,b._CenterFrequencyUnit.toUpperCase()=="HZ"?(c=b._CenterFrequency,a+="<td>"+GetFreqWithUnit(c)+"</td>"):a+="<td>"+b._CenterFrequency+" "+b._CenterFrequencyUnit+"</td>",a+="</tr>";b.NumberOfChannels>1&&(a+="<tr>",a+="<td>Number of channels</td>",a+="<td>"+b.NumberOfChannels+"</td>",a+="</tr>");a+="</tbody>";a+="</table>";if(b.PreviewData&&b.PreviewData.Channel)for(c=0;c<b.PreviewData.Channel.length;c++)a+=''<table class="Top" >'',a+="<tbody>",a+=''<tr><td colspan="2" class="ChHd">'',a+=b.PreviewData.Channel[c].Name?\r\n');
   fprintf(fid,'          b.PreviewData.Channel[c].Name:"Channel "+(c+1),a+="</td></tr>",b.PreviewData.Channel[c].Comment&&(a+="<tr>",a+="<td>Comment</td>",a+="<td>"+b.PreviewData.Channel[c].Comment+"</td>",a+="</tr>"),b.PreviewData.Channel[c].PowerVsTime&&(a+="<tr>",a+=''<td><div>Power vs time</div><div class="perDiv" id="divLabelpvt''+c+''" /></td>'',a+=''<td><div id="divpvt''+c+''" ></div></td>'',a+="</tr>"),b.PreviewData.Channel[c].Spectrum&&(a+="<tr>",a+=''<td><div>Spectrum</div><div class="perDiv" id="divLabelspec''+c+''" /></td>'',\r\n');
   fprintf(fid,'          a+=''<td><div id="divspec''+c+''" ></div></td>'',a+="</tr>"),b.PreviewData.Channel[c].IQ&&(a+="<tr>",a+=''<td><div>I/Q</div><div class="perDiv" id="divLabeliq''+c+''" /></td>'',a+=''<td><div id="diviq''+c+''" ></div></td>'',a+="</tr>"),a+="</tbody>",a+="</table>";$("#AddJavaScriptGeneratedContentHere").append(a);if(b.PreviewData&&b.PreviewData.Channel)for(c=0;c<b.PreviewData.Channel.length;c++)b.PreviewData.Channel[c].PowerVsTime&&drawPreview("pvt"+c,b.PreviewData.Channel[c].PowerVsTime.Min,b.PreviewData.Channel[c].PowerVsTime.Max,\r\n');
   fprintf(fid,'          d),b.PreviewData.Channel[c].Spectrum&&drawPreview("spec"+c,b.PreviewData.Channel[c].Spectrum.Min,b.PreviewData.Channel[c].Spectrum.Max,f),b.PreviewData.Channel[c].IQ&&drawIqPreview("iq"+c,b.PreviewData.Channel[c].IQ)}\r\n');
   fprintf(fid,'          function drawPreview(b,a,f,d){if(a.length==f.length&&a.length>0){var c=a.length,i=c/2,e=document.createElement("canvas");document.getElementById("div"+b).appendChild(e);typeof G_vmlCanvasManager!="undefined"&&(e=G_vmlCanvasManager.initElement(e));e.setAttribute("width",c+1);e.setAttribute("height",i+1);e.setAttribute("id",b);var e=e.getContext("2d"),g=a.min(),j=f.max(),n=j-g;g-=0.025/0.95*n;j+=0.025/0.95*n;isNaN(g)&&(g=-150);isNaN(j)&&(j=50);var o=0,p=0.5*i;j>g&&(o=1/(g-j)*i,p=-o*j);e.strokeStyle=\r\n');
   fprintf(fid,'          "#AEB5BB";e.fillStyle="#AEB5BB";var k=getPerDivision(g,j),n="";if(k>0)for(var n="<div>y-axis: "+k+" dB /div</div>",h=Math.ceil(g/k)*k;h<j;h+=k)e.fillRect(0.5,h*o+p-0.5,c,1);k="";if(0==b.search("pvt")){if(h=getPerDivision(0,d),h>0)for(var k="<div>x-axis: "+GetTimeWithUnit(h)+" /div</div>",l=a.length/d,m=h;m<d;m+=h)e.fillRect(l*m,0.5,1,i)}else if(0==b.search("spec")&&(h=getPerDivision(-0.5*d,0.5*d),h>0))for(var k="<div>x-axis: "+GetFreqWithUnit(h)+" /div</div>",l=a.length/d,q=0.5*a.length,m=Math.ceil(-0.5*\r\n');
   fprintf(fid,'          d/h)*h;m<0.5*d;m+=h)e.fillRect(l*m+q,0.5,1,i);e.strokeStyle="#0000FF";e.fillStyle="#0000FF";for(d=0;d<a.length;d++)h=a[d],l=f[d],isNaN(h)&&(h=g),isNaN(l)&&(l=j),e.fillRect(d,l*o+p,1,(h-l)*o);e.strokeStyle="#000000";e.fillStyle="#000000";e.strokeRect(0.5,0.5,c,i);c="";c+="<div>&nbsp;</div>";c+=n;c+=k;$("#divLabel"+b).append(c)}else f.length==0||a.length==0||(c="",c+=''<div class="Err">Error: Min and Max preview traces have bad lengths (''+a.length+", "+f.length+").</div>",$("#div"+b).append(c))}\r\n');
   fprintf(fid,'          function drawIqPreview(b,a){if(a.histo.length==a.width*a.height&&a.histo.length>0){var f=2*a.width,d=2*a.height;if(typeof G_vmlCanvasManager!="undefined"){var c="";c+=''<div style="position:relative;height:''+d+"px;width:"+f+''px;border-style:solid;border-width:1px;border-color:#000000;">'';for(var i=0,e=0;e<d;e+=2)for(var g=0;g<f;g+=2){var j=a.histo.charAt(i++);switch(j){case "0":break;case "1":c+=''<div style="position:absolute; height:2px; width:2px; top:''+e+"px; left:"+g+''px; background-color:#E3E3FF;"><\\!-- --\\></div>'';\r\n');
   fprintf(fid,'          break;case "2":c+=''<div style="position:absolute; height:2px; width:2px; top:''+e+"px; left:"+g+''px; background-color:#C6C6FF;"><\\!-- --\\></div>'';break;case "3":c+=''<div style="position:absolute; height:2px; width:2px; top:''+e+"px; left:"+g+''px; background-color:#AAAAFF;"><\\!-- --\\></div>'';break;case "4":c+=''<div style="position:absolute; height:2px; width:2px; top:''+e+"px; left:"+g+''px; background-color:#8E8EFF;"><\\!-- --\\></div>'';break;case "5":c+=''<div style="position:absolute; height:2px; width:2px; top:''+\r\n');
   fprintf(fid,'          e+"px; left:"+g+''px; background-color:#7171FF;"><\\!-- --\\></div>'';break;case "6":c+=''<div style="position:absolute; height:2px; width:2px; top:''+e+"px; left:"+g+''px; background-color:#5555FF;"><\\!-- --\\></div>'';break;case "7":c+=''<div style="position:absolute; height:2px; width:2px; top:''+e+"px; left:"+g+''px; background-color:#3939FF;"><\\!-- --\\></div>'';break;case "8":c+=''<div style="position:absolute; height:2px; width:2px; top:''+e+"px; left:"+g+''px; background-color:#1C1CFF;"><\\!-- --\\></div>'';\r\n');
   fprintf(fid,'          break;default:c+=''<div style="position:absolute; height:2px; width:2px; top:''+e+"px; left:"+g+''px; background-color:#0000FF;"><\\!-- --\\></div>''}}c+="</div>";$("#div"+b).append(c)}else{i=document.createElement("canvas");document.getElementById("div"+b).appendChild(i);i.setAttribute("width",f);i.setAttribute("height",d);i.setAttribute("id",b);c=i.getContext("2d");for(e=i=0;e<d;e+=2)for(g=0;g<f;g+=2){j=a.histo.charAt(i++);switch(j){case "0":break;case "1":c.fillStyle="#E3E3FF";c.fillRect(g,e,2,2);break;\r\n');
   fprintf(fid,'          case "2":c.fillStyle="#C6C6FF";c.fillRect(g,e,2,2);break;case "3":c.fillStyle="#AAAAFF";c.fillRect(g,e,2,2);break;case "4":c.fillStyle="#8E8EFF";c.fillRect(g,e,2,2);break;case "5":c.fillStyle="#7171FF";c.fillRect(g,e,2,2);break;case "6":c.fillStyle="#5555FF";c.fillRect(g,e,2,2);break;case "7":c.fillStyle="#3939FF";c.fillRect(g,e,2,2);break;case "8":c.fillStyle="#1C1CFF";c.fillRect(g,e,2,2);break;default:c.fillStyle="#0000FF",c.fillRect(g,e,2,2)}c.strokeStyle="#000000";c.fillStyle="#000000";c.strokeRect(0,\r\n');
   fprintf(fid,'          0,f,d)}}}else c="",c+=''<div class="Err">Error: I/Q preview has incorrect length (''+a.histo.length+" != "+a.width+" * "+a.height+").</div>",$("#div"+b).append(c)}function getPerDivision(b,a){var f=0,d=0,c=0;a>b&&(c=a-b,c>0&&(f=Math.log(c/14)/Math.LN10,c=Math.floor(f),f-=c,f<=0.3?d=2:f<=0.69?d=5:(d=1,c+=1),f=d*Math.pow(10,c)));return f}function GetTimeWithUnit(b){var a="";a+=b>=1?NiceNo(b)+" s":b>=0.001?NiceNo(b*1E3)+" ms":b>=1.0E-6?NiceNo(b*1E6)+" us":b+" s";return a}\r\n');
   fprintf(fid,'          function GetDurationWithUnit(b){var a="",f=31536E3,d=Math.floor(b/f);d>0&&(a+=d+" year",d>1&&(a+="s"),a+="&nbsp;&nbsp;&nbsp;",b-=d*f);f=86400;d=Math.floor(b/f);d>0&&(a+=d+" day",d>1&&(a+="s"),a+="&nbsp;&nbsp;&nbsp;",b-=d*f);f=3600;d=Math.floor(b/f);d>0&&(a+=d+" h&nbsp;&nbsp;&nbsp;",b-=d*f);f=60;d=Math.floor(b/f);d>0&&(a+=d+" min&nbsp;&nbsp;&nbsp;",b-=d*f);a+=GetTimeWithUnit(b);return a=a.replace(/(&nbsp;)+$/,"")}\r\n');
   fprintf(fid,'          function NiceNo(b){b=""+b.toFixed(3);b=b.replace(/[0]+$/,"");return b=b.replace(/[.]$/,"")}function GetFreqWithUnit(b){var a="";a+=b>=1E9?b/1E9+" GHz":b>=1E6?b/1E6+" MHz":b>=1E3?b/1E3+" kHz":b+" Hz";return a}Array.prototype.max=function(){return Math.max.apply({},this)};Array.prototype.min=function(){return Math.min.apply({},this)};\r\n');
   fprintf(fid,'          function epilogue(b){var a="";a+=''<div class="Epilogue">'';a+=''<div>E-mail: <a href="mailto:info@rohde-schwarz.com">info@rohde-schwarz.com</a></div>'';a+=''<div>Internet: <a href="http://www.rohde-schwarz.com" >http://www.rohde-schwarz.com</a></div>'';b.fileFormatVersion&&(a+="<div>Fileformat version: "+b.fileFormatVersion+"</div>");a+="</div>";$("#AddJavaScriptGeneratedEpilogueHere").empty();$("#AddJavaScriptGeneratedEpilogueHere").append(a)}\r\n');
   fprintf(fid,'          function iqtar(){this.DateTime=this.Comment=this.Name=void 0;this.Clock=this.Samples=0;this.ClockUnit="Hz";this.DataType=this.Format=void 0;this.ScalingFactor=1;this.ScalingFactorUnit="V";this.NumberOfChannels=0;this.DataFilename=void 0;this.UserData=!1;this._CenterFrequency=this.PreviewData=void 0;this._CenterFrequencyUnit="Hz"};\r\n');
   fprintf(fid,'        ]]>\r\n');
   fprintf(fid,'        <!-- ############################################################################################### -->\r\n');
   fprintf(fid,'        <!-- ### End: Embedded R&S source ''RsIqTar.js''                                                  #### -->\r\n');
   fprintf(fid,'        <!-- ############################################################################################### -->\r\n');
   fprintf(fid,'      </xsl:text>\r\n');
   fprintf(fid,'      </script>\r\n');
   fprintf(fid,'      \r\n');
   fprintf(fid,'      <script type="text/javascript">\r\n');
   fprintf(fid,'      $(document).ready(function()\r\n');
   fprintf(fid,'      {\r\n');
   fprintf(fid,'        // Generate html from xml data\r\n');
   fprintf(fid,'        var obj = new iqtar();\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'        // Parse xml elements\r\n');
   fprintf(fid,'        <xsl:apply-templates select="@fileFormatVersion" />\r\n');
   fprintf(fid,'        <xsl:apply-templates select="Name" />\r\n');
   fprintf(fid,'        <xsl:apply-templates select="Comment" />\r\n');
   fprintf(fid,'        <xsl:apply-templates select="DateTime" />\r\n');
   fprintf(fid,'        <xsl:apply-templates select="Samples" />\r\n');
   fprintf(fid,'        <xsl:apply-templates select="Clock" />\r\n');
   fprintf(fid,'        <xsl:apply-templates select="Format" />\r\n');
   fprintf(fid,'        <xsl:apply-templates select="DataType" />\r\n');
   fprintf(fid,'        <xsl:apply-templates select="ScalingFactor" />\r\n');
   fprintf(fid,'        <xsl:apply-templates select="NumberOfChannels" />\r\n');
   fprintf(fid,'        <xsl:apply-templates select="DataFilename" />\r\n');
   fprintf(fid,'        <xsl:apply-templates select="UserData" />\r\n');
   fprintf(fid,'        <xsl:apply-templates select="PreviewData" />\r\n');
   fprintf(fid,'        \r\n');
   fprintf(fid,'        // Generate document\r\n');
   fprintf(fid,'        zeichne(obj);\r\n');
   fprintf(fid,'       \r\n');
   fprintf(fid,'        //alert("FINE"); \r\n');
   fprintf(fid,'      });\r\n');
   fprintf(fid,'      </script>\r\n');
   fprintf(fid,'      </head>\r\n');
   fprintf(fid,'      <body>\r\n');
   fprintf(fid,'        <div id="AddJavaScriptGeneratedContentHere"></div>\r\n');
   fprintf(fid,'        <div id="AddJavaScriptGeneratedEpilogueHere"></div>\r\n');
   fprintf(fid,'      </body>\r\n');
   fprintf(fid,'    </html>\r\n');
   fprintf(fid,'  </xsl:template>  \r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="@fileFormatVersion">\r\n');
   fprintf(fid,'    <xsl:text>obj.fileFormatVersion=parseInt(''</xsl:text><xsl:value-of select="." /><xsl:text>'');</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="Name">\r\n');
   fprintf(fid,'    <xsl:text>obj.Name=''</xsl:text><xsl:value-of select="translate(.,&quot;''&quot;,''&quot;'')" /><xsl:text>'';</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="Comment">\r\n');
   fprintf(fid,'    <!--Replace single quote by double quote-->\r\n');
   fprintf(fid,'    <xsl:text>obj.Comment=''</xsl:text><xsl:value-of select="translate(.,&quot;''&quot;,''&quot;'')" /><xsl:text>'';</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="DateTime">\r\n');
   fprintf(fid,'    <xsl:text>obj.DateTime=''</xsl:text><xsl:value-of select="." /><xsl:text>'';</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'  \r\n');
   fprintf(fid,'  <xsl:template match="Samples">\r\n');
   fprintf(fid,'    <xsl:text>obj.Samples=parseInt(''</xsl:text><xsl:value-of select="." /><xsl:text>'');</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'  \r\n');
   fprintf(fid,'  <xsl:template match="Clock">\r\n');
   fprintf(fid,'    <xsl:text>obj.Clock=parseFloat(''</xsl:text><xsl:value-of select="." /><xsl:text>'');</xsl:text>\r\n');
   fprintf(fid,'    <xsl:text>obj.ClockUnit=''</xsl:text><xsl:value-of select="@unit" /><xsl:text>'';</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="Format">\r\n');
   fprintf(fid,'    <xsl:text>obj.Format=''</xsl:text><xsl:value-of select="." /><xsl:text>'';</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'  \r\n');
   fprintf(fid,'  <xsl:template match="DataType">\r\n');
   fprintf(fid,'    <xsl:text>obj.DataType=''</xsl:text><xsl:value-of select="." /><xsl:text>'';</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="ScalingFactor">\r\n');
   fprintf(fid,'    <xsl:text>obj.ScalingFactor=parseFloat(''</xsl:text><xsl:value-of select="." /><xsl:text>'');</xsl:text>\r\n');
   fprintf(fid,'    <xsl:text>obj.ScalingFactorUnit=''</xsl:text><xsl:value-of select="@unit" /><xsl:text>'';</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'  \r\n');
   fprintf(fid,'  <xsl:template match="NumberOfChannels">\r\n');
   fprintf(fid,'    <xsl:text>obj.NumberOfChannels=parseInt(''</xsl:text><xsl:value-of select="." /><xsl:text>'');</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="DataFilename">\r\n');
   fprintf(fid,'    <xsl:text>obj.DataFilename=''</xsl:text><xsl:value-of select="." /><xsl:text>'';</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="PreviewData">\r\n');
   fprintf(fid,'    <xsl:text>obj.PreviewData ={</xsl:text>\r\n');
   fprintf(fid,'    <xsl:choose>\r\n');
   fprintf(fid,'      <xsl:when test="ArrayOfChannel">\r\n');
   fprintf(fid,'        <xsl:apply-templates select="ArrayOfChannel" />\r\n');
   fprintf(fid,'      </xsl:when>\r\n');
   fprintf(fid,'    </xsl:choose>\r\n');
   fprintf(fid,'    <xsl:text>};</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="ArrayOfChannel">\r\n');
   fprintf(fid,'    <xsl:text>Channel : [</xsl:text>\r\n');
   fprintf(fid,'    <xsl:for-each select="Channel">\r\n');
   fprintf(fid,'      <xsl:text>{</xsl:text>\r\n');
   fprintf(fid,'      <xsl:text>''Name'':''</xsl:text><xsl:value-of select="Name" /><xsl:text>'',</xsl:text>\r\n');
   fprintf(fid,'      <xsl:text>''Comment'':''</xsl:text><xsl:value-of select="Comment" /><xsl:text>'',</xsl:text>\r\n');
   fprintf(fid,'      <xsl:text>''PowerVsTime'':</xsl:text>\r\n');
   fprintf(fid,'      <xsl:choose>\r\n');
   fprintf(fid,'        <xsl:when test="PowerVsTime">\r\n');
   fprintf(fid,'          <xsl:apply-templates select="PowerVsTime" />\r\n');
   fprintf(fid,'        </xsl:when>\r\n');
   fprintf(fid,'        <xsl:otherwise>\r\n');
   fprintf(fid,'          <xsl:text>undefined</xsl:text>\r\n');
   fprintf(fid,'        </xsl:otherwise>\r\n');
   fprintf(fid,'      </xsl:choose>\r\n');
   fprintf(fid,'      <xsl:text>,</xsl:text>  \r\n');
   fprintf(fid,'      <xsl:text>''Spectrum'':</xsl:text>\r\n');
   fprintf(fid,'      <xsl:choose>\r\n');
   fprintf(fid,'        <xsl:when test="Spectrum">\r\n');
   fprintf(fid,'          <xsl:apply-templates select="Spectrum" />\r\n');
   fprintf(fid,'        </xsl:when>\r\n');
   fprintf(fid,'        <xsl:otherwise>\r\n');
   fprintf(fid,'          <xsl:text>undefined</xsl:text>\r\n');
   fprintf(fid,'        </xsl:otherwise>\r\n');
   fprintf(fid,'      </xsl:choose>\r\n');
   fprintf(fid,'      <xsl:text>,</xsl:text>  \r\n');
   fprintf(fid,'      <xsl:text>''IQ'':</xsl:text>\r\n');
   fprintf(fid,'      <xsl:choose>\r\n');
   fprintf(fid,'        <xsl:when test="IQ">\r\n');
   fprintf(fid,'          <xsl:apply-templates select="IQ" />\r\n');
   fprintf(fid,'        </xsl:when>\r\n');
   fprintf(fid,'        <xsl:otherwise>\r\n');
   fprintf(fid,'          <xsl:text>undefined</xsl:text>\r\n');
   fprintf(fid,'        </xsl:otherwise>\r\n');
   fprintf(fid,'      </xsl:choose>\r\n');
   fprintf(fid,'      <xsl:text>}</xsl:text>\r\n');
   fprintf(fid,'      <xsl:if test="position() !=  last()"><xsl:text>,</xsl:text></xsl:if>\r\n');
   fprintf(fid,'    </xsl:for-each>\r\n');
   fprintf(fid,'    <xsl:text>]</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,' \r\n');
   fprintf(fid,'  <xsl:template match="PowerVsTime">\r\n');
   fprintf(fid,'    <xsl:text>{</xsl:text>\r\n');
   fprintf(fid,'    <xsl:text>''Min'':</xsl:text>\r\n');
   fprintf(fid,'    <xsl:choose>\r\n');
   fprintf(fid,'        <xsl:when test="Min">\r\n');
   fprintf(fid,'          <xsl:apply-templates select="Min" />\r\n');
   fprintf(fid,'        </xsl:when>\r\n');
   fprintf(fid,'        <xsl:otherwise>\r\n');
   fprintf(fid,'          <xsl:text>undefined</xsl:text>\r\n');
   fprintf(fid,'        </xsl:otherwise>\r\n');
   fprintf(fid,'      </xsl:choose>\r\n');
   fprintf(fid,'      <xsl:text>,</xsl:text>\r\n');
   fprintf(fid,'    <xsl:text>''Max'':</xsl:text>  <xsl:choose>\r\n');
   fprintf(fid,'        <xsl:when test="Max">\r\n');
   fprintf(fid,'          <xsl:apply-templates select="Max" />\r\n');
   fprintf(fid,'        </xsl:when>\r\n');
   fprintf(fid,'        <xsl:otherwise>\r\n');
   fprintf(fid,'          <xsl:text>undefined</xsl:text>\r\n');
   fprintf(fid,'        </xsl:otherwise>\r\n');
   fprintf(fid,'      </xsl:choose>\r\n');
   fprintf(fid,'    <xsl:text>}</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="Min">\r\n');
   fprintf(fid,'    <xsl:text>[</xsl:text>\r\n');
   fprintf(fid,'    <xsl:if test="ArrayOfFloat">\r\n');
   fprintf(fid,'      <xsl:apply-templates select="ArrayOfFloat" />\r\n');
   fprintf(fid,'    </xsl:if>\r\n');
   fprintf(fid,'    <xsl:text>]</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="Spectrum">\r\n');
   fprintf(fid,'    <xsl:text>{</xsl:text>\r\n');
   fprintf(fid,'    <xsl:text>''Min'':</xsl:text>\r\n');
   fprintf(fid,'    <xsl:choose>\r\n');
   fprintf(fid,'        <xsl:when test="Min">\r\n');
   fprintf(fid,'          <xsl:apply-templates select="Min" />\r\n');
   fprintf(fid,'        </xsl:when>\r\n');
   fprintf(fid,'        <xsl:otherwise>\r\n');
   fprintf(fid,'          <xsl:text>undefined</xsl:text>\r\n');
   fprintf(fid,'        </xsl:otherwise>\r\n');
   fprintf(fid,'      </xsl:choose>\r\n');
   fprintf(fid,'      <xsl:text>,</xsl:text>\r\n');
   fprintf(fid,'    <xsl:text>''Max'':</xsl:text>  <xsl:choose>\r\n');
   fprintf(fid,'        <xsl:when test="Max">\r\n');
   fprintf(fid,'          <xsl:apply-templates select="Max" />\r\n');
   fprintf(fid,'        </xsl:when>\r\n');
   fprintf(fid,'        <xsl:otherwise>\r\n');
   fprintf(fid,'          <xsl:text>undefined</xsl:text>\r\n');
   fprintf(fid,'        </xsl:otherwise>\r\n');
   fprintf(fid,'      </xsl:choose>\r\n');
   fprintf(fid,'    <xsl:text>}</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="IQ">\r\n');
   fprintf(fid,'    <xsl:text>{</xsl:text>\r\n');
   fprintf(fid,'    <xsl:text>''width'':</xsl:text>\r\n');
   fprintf(fid,'    <xsl:choose>\r\n');
   fprintf(fid,'        <xsl:when test="Histogram/@width">\r\n');
   fprintf(fid,'          <xsl:text>parseInt(''</xsl:text><xsl:value-of select="Histogram/@width" /><xsl:text>'')</xsl:text>\r\n');
   fprintf(fid,'        </xsl:when>\r\n');
   fprintf(fid,'        <xsl:otherwise>\r\n');
   fprintf(fid,'          <xsl:text>undefined</xsl:text>\r\n');
   fprintf(fid,'        </xsl:otherwise>\r\n');
   fprintf(fid,'      </xsl:choose>\r\n');
   fprintf(fid,'      <xsl:text>,''height'':</xsl:text>\r\n');
   fprintf(fid,'      <xsl:choose>\r\n');
   fprintf(fid,'        <xsl:when test="Histogram/@height">\r\n');
   fprintf(fid,'          <xsl:text>parseInt(''</xsl:text><xsl:value-of select="Histogram/@height" /><xsl:text>'')</xsl:text>\r\n');
   fprintf(fid,'        </xsl:when>\r\n');
   fprintf(fid,'        <xsl:otherwise>\r\n');
   fprintf(fid,'          <xsl:text>undefined</xsl:text>\r\n');
   fprintf(fid,'        </xsl:otherwise>\r\n');
   fprintf(fid,'      </xsl:choose>\r\n');
   fprintf(fid,'      <xsl:text>,''histo'':</xsl:text>\r\n');
   fprintf(fid,'      <xsl:choose>\r\n');
   fprintf(fid,'        <xsl:when test="Histogram">\r\n');
   fprintf(fid,'          <xsl:text>''</xsl:text><xsl:value-of select="Histogram" /><xsl:text>''</xsl:text>\r\n');
   fprintf(fid,'        </xsl:when>\r\n');
   fprintf(fid,'        <xsl:otherwise>\r\n');
   fprintf(fid,'          <xsl:text>undefined</xsl:text>\r\n');
   fprintf(fid,'        </xsl:otherwise>\r\n');
   fprintf(fid,'      </xsl:choose>\r\n');
   fprintf(fid,'    <xsl:text>}</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="Max">\r\n');
   fprintf(fid,'    <xsl:text>[</xsl:text>\r\n');
   fprintf(fid,'    <xsl:if test="ArrayOfFloat">\r\n');
   fprintf(fid,'      <xsl:apply-templates select="ArrayOfFloat" />\r\n');
   fprintf(fid,'    </xsl:if>\r\n');
   fprintf(fid,'    <xsl:text>]</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="ArrayOfFloat">\r\n');
   fprintf(fid,'    <xsl:for-each select="float">\r\n');
   fprintf(fid,'      <xsl:text>parseFloat(''</xsl:text><xsl:value-of select="." /><xsl:text>'')</xsl:text>\r\n');
   fprintf(fid,'      <xsl:if test="position() !=  last()"><xsl:text>,</xsl:text></xsl:if>\r\n');
   fprintf(fid,'    </xsl:for-each>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <!-- Rohde & Schwarz specific extension for UserData -->\r\n');
   fprintf(fid,'  <xsl:template match="UserData">\r\n');
   fprintf(fid,'    <xsl:apply-templates select="RohdeSchwarz" />\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="RohdeSchwarz">\r\n');
   fprintf(fid,'    <xsl:apply-templates select="SpectrumAnalyzer" />\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="SpectrumAnalyzer">\r\n');
   fprintf(fid,'    <xsl:apply-templates select="CenterFrequency" />\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  <xsl:template match="CenterFrequency">\r\n');
   fprintf(fid,'    <xsl:text>obj._CenterFrequency=parseFloat(''</xsl:text><xsl:value-of select="." /><xsl:text>'');</xsl:text>\r\n');
   fprintf(fid,'    <xsl:text>obj._CenterFrequencyUnit=''</xsl:text><xsl:value-of select="@unit" /><xsl:text>'';</xsl:text>\r\n');
   fprintf(fid,'  </xsl:template>\r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'  \r\n');
   fprintf(fid,'\r\n');
   fprintf(fid,'</xsl:stylesheet>\r\n');
   fclose(fid);
### END OF FUNCTION


if __name__ == "__main__":
   IQD = [1,2,3,4,5,6,7,8,9,19]
   write_iqtar(IQD,"Test",1e6)
