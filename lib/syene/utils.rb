module Syene
  module Utils
    def symbolize_keys(h)
      return h unless h.is_a?(Hash)
      h.keys.inject({}) do |acc, k|
        acc[k.to_sym] = symbolize_keys(h[k])
        acc
      end
    end
    
      
    def download_archive(downloader, url, archive_path)
      downloader.open(url) do |input|
        File.open(archive_path, 'w') do |output|
          while bytes = input.read(2**16)
            output.write(bytes)
          end
        end
      end
      
      archive_path
    end
    
    def extract_archive(archive_path, tmp_dir)
      files = []
      Zip::Archive.open(archive_path) do |archive|
        archive.each do |entry|
          if entry.directory?
            dirname = File.join(tmp_dir, entry.name)
            FileUtils.mkdir_p(dirname)
            files << dirname
          else
            dirname = File.join(tmp_dir, File.dirname(entry.name))
            filename = File.join(dirname, entry.name)
            FileUtils.mkdir_p(dirname)
            File.open(filename, 'wb') do |f|
              f.write(entry.read)
            end
            files << filename
          end
        end
      end
      files
    end
  end
end